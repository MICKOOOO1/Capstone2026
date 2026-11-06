BEGIN;
ALTER TABLE public.loan_policy_settings
  ADD COLUMN IF NOT EXISTS collateral_required_above NUMERIC(15,2) NOT NULL DEFAULT 200000
  CHECK (collateral_required_above >= 0);

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
  IF p_amount > policy.collateral_required_above AND NOT EXISTS (
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
