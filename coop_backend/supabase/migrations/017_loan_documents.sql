BEGIN;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('loan-documents', 'loan-documents', FALSE, 10485760,
  ARRAY['image/jpeg','image/png','image/webp','image/heic','image/heif','application/pdf'])
ON CONFLICT (id) DO NOTHING;

CREATE TABLE public.loan_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_application_id UUID NOT NULL REFERENCES public.loan_applications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  kind TEXT NOT NULL CHECK (kind IN ('payslip','validId','collateral','supporting')),
  storage_path TEXT NOT NULL UNIQUE,
  original_name TEXT NOT NULL CHECK (length(original_name) BETWEEN 1 AND 255),
  content_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes BETWEEN 1 AND 10485760),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (loan_application_id, kind)
);
CREATE INDEX loan_documents_application_idx ON public.loan_documents(loan_application_id);
ALTER TABLE public.loan_documents ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.loan_documents FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.loan_documents TO authenticated;
GRANT ALL ON public.loan_documents TO service_role;

CREATE OR REPLACE FUNCTION public.can_submit_loan_documents()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u JOIN public.members m ON m.user_id = u.id
    WHERE u.id = auth.uid() AND u.raw_app_meta_data ->> 'role' = 'member'
      AND COALESCE(u.raw_app_meta_data ->> 'account_status', 'active') = 'active'
      AND (u.banned_until IS NULL OR u.banned_until <= NOW())
      AND m.status = 'active' AND m.must_change_password = FALSE
  );
$$;

CREATE OR REPLACE FUNCTION public.can_review_loan_documents()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u JOIN public.members m ON m.user_id = u.id
    WHERE u.id = auth.uid() AND u.raw_app_meta_data ->> 'role' IN ('admin','coop_admin','super_admin')
      AND COALESCE(u.raw_app_meta_data ->> 'account_status', 'active') = 'active'
      AND (u.banned_until IS NULL OR u.banned_until <= NOW()) AND m.status = 'active'
  );
$$;
REVOKE ALL ON FUNCTION public.can_submit_loan_documents() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_review_loan_documents() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_submit_loan_documents(), public.can_review_loan_documents() TO authenticated;

CREATE POLICY "Members and reviewers can read loan document metadata"
  ON public.loan_documents FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.can_review_loan_documents());

CREATE POLICY "Members can stage their own loan documents"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'loan-documents'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
    AND public.can_submit_loan_documents());

CREATE POLICY "Owners and reviewers can read private loan documents"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'loan-documents' AND (
    (storage.foldername(name))[1] = auth.uid()::TEXT
    OR (public.can_review_loan_documents() AND EXISTS (
      SELECT 1 FROM public.loan_documents d WHERE d.storage_path = storage.objects.name
    ))
  ));

-- Failed/retried requests can clean up drafts, but cannot delete files already
-- attached by a committed submission, even if its response was lost.
CREATE POLICY "Members can remove only their unsubmitted document drafts"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'loan-documents'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
    AND NOT EXISTS (SELECT 1 FROM public.loan_documents d WHERE d.storage_path = storage.objects.name));

CREATE OR REPLACE FUNCTION public.submit_loan_with_documents(
  p_application_id TEXT, p_loan_type TEXT, p_amount NUMERIC, p_documents JSONB
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
DECLARE
  member_row public.members%ROWTYPE;
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
  IF p_application_id IS NULL OR length(p_application_id) > 50
     OR p_application_id !~ '^LA-[0-9]{4}-[0-9]{4,}$'
     OR p_amount IS NULL OR p_amount <= 0 OR p_amount::TEXT IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Invalid loan application details.';
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
  IF p_amount > 200000 AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(p_documents) d WHERE d ->> 'kind' = 'collateral') THEN
    RAISE EXCEPTION 'A collateral document is required for loans over 200,000 pesos.';
  END IF;

  -- Serialize retries of the same reference. No account ID sequence is used.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_application_id, 0));
  SELECT * INTO existing FROM public.loan_applications WHERE application_id = p_application_id;
  IF FOUND THEN
    IF existing.member_id = member_row.id AND existing.loan_type = p_loan_type
      AND existing.amount = round(p_amount, 2)
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

  INSERT INTO public.loan_applications (application_id, member_id, member_name, loan_type, amount, purpose, status, date_submitted)
  VALUES (p_application_id, member_row.id, trim(member_row.first_name || ' ' || member_row.last_name), p_loan_type,
    round(p_amount, 2), p_loan_type, 'pending', CURRENT_DATE)
  RETURNING id INTO application_uuid;

  INSERT INTO public.loan_documents (loan_application_id, user_id, kind, storage_path, original_name, content_type, size_bytes)
  SELECT application_uuid, auth.uid(), d ->> 'kind', d ->> 'path', d ->> 'name', d ->> 'mimeType', (d ->> 'size')::BIGINT
  FROM jsonb_array_elements(p_documents) d;
  RETURN application_uuid;
END;
$$;
REVOKE ALL ON FUNCTION public.submit_loan_with_documents(TEXT,TEXT,NUMERIC,JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_loan_with_documents(TEXT,TEXT,NUMERIC,JSONB) TO authenticated;

-- Member submissions now go through the atomic document-aware RPC.
REVOKE INSERT ON public.loan_applications FROM authenticated;
REVOKE INSERT (application_id, member_id, member_name, loan_type, amount, purpose, status, date_submitted)
  ON public.loan_applications FROM authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
