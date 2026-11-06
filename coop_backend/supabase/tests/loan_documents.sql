-- Transaction-local fixtures exercise database authorization and atomicity.
-- No Auth users or actual storage blobs are created; all changes roll back.
BEGIN;
DO $$
DECLARE
  actor UUID;
  other_actor UUID;
  reference TEXT := 'LA-' || to_char(CURRENT_DATE, 'YYYY') || '-' || lpad(floor(random() * 999999)::INT::TEXT, 6, '0');
  base_path TEXT;
  documents JSONB;
  application_uuid UUID;
  repeated UUID;
  deleted_count INT;
BEGIN
  IF (SELECT public FROM storage.buckets WHERE id = 'loan-documents') IS DISTINCT FROM FALSE THEN
    RAISE EXCEPTION 'Loan documents bucket must be private';
  END IF;
  SELECT u.id INTO actor FROM auth.users u JOIN public.members m ON m.user_id = u.id
  WHERE m.status = 'active' AND (u.banned_until IS NULL OR u.banned_until <= NOW()) LIMIT 1;
  SELECT u.id INTO other_actor FROM auth.users u JOIN public.members m ON m.user_id = u.id
  WHERE u.id <> actor LIMIT 1;
  IF actor IS NULL THEN RAISE EXCEPTION 'An existing linked identity is required for the authorization checks'; END IF;

  -- Only inside this transaction, simulate trusted Member identities.
  UPDATE auth.users SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::JSONB) || '{"role":"member","account_status":"active"}'::JSONB
  WHERE id = actor OR id = other_actor;
  UPDATE public.members SET must_change_password = FALSE WHERE user_id = actor;
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated', 'app_metadata', jsonb_build_object('role', 'member'))::TEXT, TRUE);
  EXECUTE 'SET LOCAL ROLE authenticated';

  base_path := actor::TEXT || '/' || reference || '/';
  INSERT INTO storage.objects(bucket_id, name, metadata) VALUES
    ('loan-documents', base_path || 'payslip.pdf', '{"size":100,"mimetype":"application/pdf"}'),
    ('loan-documents', base_path || 'identification.pdf', '{"size":100,"mimetype":"application/pdf"}');
  documents := jsonb_build_array(
    jsonb_build_object('kind','payslip','path',base_path || 'payslip.pdf','name','payslip.pdf','mimeType','application/pdf','size',100),
    jsonb_build_object('kind','validId','path',base_path || 'identification.pdf','name','identification.pdf','mimeType','application/pdf','size',100)
  );

  BEGIN
    PERFORM public.submit_loan_with_documents(reference,'Regular',150000,jsonb_build_array(documents -> 0));
    RAISE EXCEPTION 'Missing identification was accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Attach one payslip and one valid identification document.' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.submit_loan_with_documents(reference,'Regular',250000,documents);
    RAISE EXCEPTION 'Missing collateral was accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'A collateral document is required for loans over 200,000 pesos.' THEN RAISE; END IF;
  END;
  IF other_actor IS NOT NULL THEN
    BEGIN
      PERFORM public.submit_loan_with_documents(reference,'Regular',150000,
        jsonb_set(documents, '{0,path}', to_jsonb(other_actor::TEXT || '/' || reference || '/payslip.pdf')));
      RAISE EXCEPTION 'Another account storage path was accepted';
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM <> 'One of the selected documents has invalid details.' THEN RAISE; END IF;
    END;
  END IF;

  application_uuid := public.submit_loan_with_documents(reference,'Regular',150000,documents);
  IF (SELECT count(*) FROM public.loan_documents WHERE loan_application_id = application_uuid) <> 2 THEN
    RAISE EXCEPTION 'Submission did not atomically attach both documents';
  END IF;
  repeated := public.submit_loan_with_documents(reference,'Regular',150000,documents);
  IF repeated <> application_uuid THEN RAISE EXCEPTION 'Submission retry was not idempotent'; END IF;

  -- Mimic the Storage API's transaction-local deletion guard while testing
  -- RLS against metadata fixtures. No real objects/blobs are involved.
  PERFORM set_config('storage.allow_delete_query', 'true', TRUE);
  DELETE FROM storage.objects WHERE bucket_id = 'loan-documents' AND name IN (base_path || 'payslip.pdf', base_path || 'identification.pdf');
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  IF deleted_count <> 0 THEN RAISE EXCEPTION 'Committed documents were deleted during draft cleanup'; END IF;
  INSERT INTO storage.objects(bucket_id, name, metadata)
  VALUES ('loan-documents', base_path || 'unused.pdf', '{"size":100,"mimetype":"application/pdf"}');
  DELETE FROM storage.objects WHERE bucket_id = 'loan-documents' AND name = base_path || 'unused.pdf';
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  IF deleted_count <> 1 THEN RAISE EXCEPTION 'Unused document draft could not be cleaned up'; END IF;

  IF other_actor IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', other_actor, 'role', 'authenticated', 'app_metadata', jsonb_build_object('role','member'))::TEXT, TRUE);
    IF EXISTS (SELECT 1 FROM public.loan_documents WHERE loan_application_id = application_uuid) THEN
      RAISE EXCEPTION 'Another member can read private document metadata';
    END IF;
    IF EXISTS (SELECT 1 FROM storage.objects WHERE bucket_id = 'loan-documents' AND name = base_path || 'payslip.pdf') THEN
      RAISE EXCEPTION 'Another member can read private document objects';
    END IF;
  END IF;
END;
$$;
ROLLBACK;
