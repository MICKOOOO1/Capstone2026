-- Browser roles cannot directly change policy; the secure server executor can
-- update it with the verified actor ID. Transaction rolls back all changes.
BEGIN;
DO $$
DECLARE
  super_id UUID;
  admin_id UUID;
  changed INTEGER;
BEGIN
  SELECT id INTO super_id FROM auth.users
    WHERE raw_app_meta_data ->> 'role' = 'super_admin' LIMIT 1;
  IF super_id IS NULL THEN RAISE EXCEPTION 'Existing Super Admin required for policy test'; END IF;
  SELECT id INTO admin_id FROM auth.users
    WHERE raw_app_meta_data ->> 'role' IN ('admin','coop_admin') AND id <> super_id LIMIT 1;

  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', super_id, 'role', 'authenticated',
    'app_metadata', jsonb_build_object('role','super_admin','account_status','active'))::TEXT, TRUE);
  EXECUTE 'SET LOCAL ROLE authenticated';
  BEGIN
    UPDATE public.loan_policy_settings SET base_interest_rate = base_interest_rate + 0.01 WHERE singleton = TRUE;
    GET DIAGNOSTICS changed = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN changed := 0;
  END;
  IF changed <> 0 THEN RAISE EXCEPTION 'Super Admin bypassed password-confirmed secure action'; END IF;

  PERFORM set_config('request.jwt.claims', '{}', TRUE);
  EXECUTE 'RESET ROLE';
  EXECUTE 'SET LOCAL ROLE service_role';
  UPDATE public.loan_policy_settings SET base_interest_rate = base_interest_rate + 0.01, updated_by = super_id WHERE singleton = TRUE;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 THEN RAISE EXCEPTION 'Secure server executor could not update policy'; END IF;
  IF (SELECT updated_by FROM public.loan_policy_settings WHERE singleton = TRUE) <> super_id THEN
    RAISE EXCEPTION 'Policy audit trigger did not record the actor';
  END IF;

  IF admin_id IS NOT NULL THEN
    EXECUTE 'RESET ROLE';
    PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', admin_id, 'role', 'authenticated',
      'app_metadata', jsonb_build_object('role','admin','account_status','active'))::TEXT, TRUE);
    EXECUTE 'SET LOCAL ROLE authenticated';
    BEGIN
      UPDATE public.loan_policy_settings SET base_interest_rate = base_interest_rate + 1 WHERE singleton = TRUE;
      GET DIAGNOSTICS changed = ROW_COUNT;
    EXCEPTION WHEN insufficient_privilege THEN changed := 0;
    END;
    IF changed <> 0 THEN RAISE EXCEPTION 'Admin unexpectedly changed loan policy'; END IF;
  END IF;
END;
$$;
ROLLBACK;
