BEGIN;

CREATE TABLE public.loan_policy_settings (
  singleton BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (singleton = TRUE),
  base_interest_rate NUMERIC(7,4) NOT NULL CHECK (base_interest_rate BETWEEN 0 AND 100),
  processing_fee_percent NUMERIC(7,4) NOT NULL CHECK (processing_fee_percent BETWEEN 0 AND 100),
  max_loan_multiplier NUMERIC(8,3) NOT NULL CHECK (max_loan_multiplier > 0 AND max_loan_multiplier <= 1000),
  min_member_tenure_months INTEGER NOT NULL CHECK (min_member_tenure_months BETWEEN 0 AND 600),
  penalty_rate_percent NUMERIC(7,4) NOT NULL CHECK (penalty_rate_percent BETWEEN 0 AND 100),
  service_fee_percent NUMERIC(7,4) NOT NULL CHECK (service_fee_percent BETWEEN 0 AND 100),
  co_maker_required_above NUMERIC(15,2) NOT NULL CHECK (co_maker_required_above >= 0),
  loan_processing_time TEXT NOT NULL CHECK (length(trim(loan_processing_time)) BETWEEN 1 AND 100),
  min_loan_amount NUMERIC(15,2) NOT NULL CHECK (min_loan_amount > 0),
  max_loan_amount NUMERIC(15,2) NOT NULL CHECK (max_loan_amount >= min_loan_amount),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

INSERT INTO public.loan_policy_settings (
  singleton, base_interest_rate, processing_fee_percent, max_loan_multiplier,
  min_member_tenure_months, penalty_rate_percent, service_fee_percent,
  co_maker_required_above, loan_processing_time, min_loan_amount, max_loan_amount
) VALUES (TRUE, 1.5, 1.0, 3, 6, 2.0, 0.5, 50000, '3–5', 1000, 500000)
ON CONFLICT (singleton) DO NOTHING;

ALTER TABLE public.loan_policy_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.loan_policy_settings FROM PUBLIC, anon;
GRANT SELECT ON public.loan_policy_settings TO authenticated;
GRANT UPDATE ON public.loan_policy_settings TO authenticated;

CREATE POLICY "Active accounts can read loan policy"
  ON public.loan_policy_settings FOR SELECT TO authenticated
  USING (
    COALESCE(auth.jwt() -> 'app_metadata' ->> 'account_status', 'active') = 'active'
    AND EXISTS (
      SELECT 1 FROM public.members m
      WHERE m.user_id = auth.uid() AND m.status = 'active'
    )
  );

CREATE POLICY "Only active Super Admins can update loan policy"
  ON public.loan_policy_settings FOR UPDATE TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'super_admin'
    AND COALESCE(auth.jwt() -> 'app_metadata' ->> 'account_status', 'active') = 'active'
    AND EXISTS (
      SELECT 1 FROM public.members m
      WHERE m.user_id = auth.uid() AND m.status = 'active'
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'super_admin'
    AND COALESCE(auth.jwt() -> 'app_metadata' ->> 'account_status', 'active') = 'active'
    AND EXISTS (
      SELECT 1 FROM public.members m
      WHERE m.user_id = auth.uid() AND m.status = 'active'
    )
  );

CREATE TABLE public.loan_policy_audit_log (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_id UUID NOT NULL REFERENCES auth.users(id),
  old_policy JSONB NOT NULL,
  new_policy JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.loan_policy_audit_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.loan_policy_audit_log FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON public.loan_policy_audit_log TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.loan_policy_audit_log_id_seq TO service_role;

CREATE OR REPLACE FUNCTION public.audit_loan_policy_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
BEGIN
  NEW.updated_at := NOW();
  NEW.updated_by := auth.uid();
  INSERT INTO public.loan_policy_audit_log (actor_id, old_policy, new_policy)
  VALUES (auth.uid(), to_jsonb(OLD), to_jsonb(NEW));
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.audit_loan_policy_change() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER audit_loan_policy_change
BEFORE UPDATE ON public.loan_policy_settings
FOR EACH ROW EXECUTE FUNCTION public.audit_loan_policy_change();

ALTER TABLE public.loan_applications
  ADD COLUMN IF NOT EXISTS tenure_months INTEGER,
  ADD COLUMN IF NOT EXISTS monthly_payment NUMERIC(15,2);

CREATE OR REPLACE FUNCTION public.submit_loan_with_documents(
  p_application_id TEXT,
  p_loan_type TEXT,
  p_amount NUMERIC,
  p_documents JSONB,
  p_tenure_months INTEGER DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
DECLARE
  member_row public.members%ROWTYPE;
  policy public.loan_policy_settings%ROWTYPE;
  existing public.loan_applications%ROWTYPE;
  application_uuid UUID;
  doc JSONB;
  object_metadata JSONB;
  object_path TEXT;
  declared_size BIGINT;
BEGIN
  IF auth.uid() IS NULL OR NOT public.can_submit_loan_documents() THEN
    RAISE EXCEPTION 'Sign in with an active member account and complete password setup before submitting.';
  END IF;
  SELECT * INTO STRICT member_row FROM public.members WHERE user_id = auth.uid();
  SELECT * INTO STRICT policy FROM public.loan_policy_settings WHERE singleton = TRUE;

  IF p_application_id IS NULL OR length(p_application_id) > 50
     OR p_application_id !~ '^LA-[0-9]{4}-[0-9]{4,}$'
     OR p_amount IS NULL OR p_amount < policy.min_loan_amount OR p_amount > policy.max_loan_amount
     OR p_amount::TEXT IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Requested amount is outside the current loan policy limits.';
  END IF;
  IF p_tenure_months IS NULL OR p_tenure_months < 1 OR p_tenure_months > 600 THEN
    RAISE EXCEPTION 'Select a valid repayment tenure.';
  END IF;
  IF policy.min_member_tenure_months > 0 AND
    (member_row.date_joined IS NULL OR member_row.date_joined > CURRENT_DATE - make_interval(months => policy.min_member_tenure_months)) THEN
    RAISE EXCEPTION 'Your membership has not yet met the minimum tenure of % months.', policy.min_member_tenure_months;
  END IF;
  IF p_documents IS NULL OR jsonb_typeof(p_documents) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Attach your payslip and valid identification.';
  END IF;
  IF jsonb_array_length(p_documents) NOT BETWEEN 2 AND 4
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(p_documents) d GROUP BY d ->> 'kind' HAVING count(*) > 1)
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(p_documents) d WHERE d ->> 'kind' = 'payslip')
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(p_documents) d WHERE d ->> 'kind' = 'validId') THEN
    RAISE EXCEPTION 'Attach one payslip and one valid identification document.';
  END IF;
  IF p_amount > policy.co_maker_required_above AND NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_documents) d WHERE d ->> 'kind' = 'collateral'
  ) THEN
    RAISE EXCEPTION 'A collateral document is required for this loan amount.';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_application_id, 0));
  SELECT * INTO existing FROM public.loan_applications WHERE application_id = p_application_id;
  IF FOUND THEN
    IF existing.member_id = member_row.id AND existing.loan_type = p_loan_type
      AND existing.amount = round(p_amount, 2) AND existing.tenure_months = p_tenure_months
      AND EXISTS (SELECT 1 FROM public.loan_documents WHERE loan_application_id = existing.id) THEN
      RETURN existing.id;
    END IF;
    RAISE EXCEPTION 'This application reference has already been used.';
  END IF;

  FOR doc IN SELECT value FROM jsonb_array_elements(p_documents) LOOP
    object_path := doc ->> 'path';
    declared_size := (doc ->> 'size')::BIGINT;
    IF jsonb_typeof(doc) IS DISTINCT FROM 'object'
      OR COALESCE(doc ->> 'kind', '') NOT IN ('payslip','validId','collateral','supporting')
      OR COALESCE(doc ->> 'mimeType', '') NOT IN ('image/jpeg','image/png','image/webp','image/heic','image/heif','application/pdf')
      OR length(COALESCE(doc ->> 'name', '')) NOT BETWEEN 1 AND 255
      OR declared_size IS NULL OR declared_size NOT BETWEEN 1 AND 10485760
      OR object_path IS NULL OR split_part(object_path, '/', 1) <> auth.uid()::TEXT
      OR split_part(object_path, '/', 2) <> p_application_id
      OR array_length(string_to_array(object_path, '/'), 1) <> 3
      OR split_part(object_path, '/', 3) !~ '^[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp|heic|heif|pdf)$' THEN
      RAISE EXCEPTION 'One of the selected documents has invalid details.';
    END IF;
    SELECT metadata INTO object_metadata FROM storage.objects
      WHERE bucket_id = 'loan-documents' AND name = object_path;
    IF NOT FOUND OR COALESCE((object_metadata ->> 'size')::BIGINT, -1) <> declared_size
      OR object_metadata ->> 'mimetype' IS DISTINCT FROM doc ->> 'mimeType' THEN
      RAISE EXCEPTION 'A selected document has not finished uploading. Please retry.';
    END IF;
  END LOOP;

  INSERT INTO public.loan_applications (
    application_id, member_id, member_name, loan_type, amount, purpose, status,
    date_submitted, tenure_months, monthly_payment
  ) VALUES (
    p_application_id, member_row.id, trim(member_row.first_name || ' ' || member_row.last_name),
    p_loan_type, round(p_amount, 2), p_loan_type, 'pending', CURRENT_DATE,
    p_tenure_months,
    round((p_amount / p_tenure_months) + (p_amount * policy.base_interest_rate / 100), 2)
  ) RETURNING id INTO application_uuid;

  INSERT INTO public.loan_documents (loan_application_id, user_id, kind, storage_path, original_name, content_type, size_bytes)
  SELECT application_uuid, auth.uid(), d ->> 'kind', d ->> 'path', d ->> 'name', d ->> 'mimeType', (d ->> 'size')::BIGINT
  FROM jsonb_array_elements(p_documents) d;
  RETURN application_uuid;
END;
$$;
REVOKE ALL ON FUNCTION public.submit_loan_with_documents(TEXT,TEXT,NUMERIC,JSONB,INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_loan_with_documents(TEXT,TEXT,NUMERIC,JSONB,INTEGER) TO authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
