-- Exercise RLS using a simulated member JWT for an existing linked identity.
-- Actual login separately checks the user's trusted role in Supabase Auth.
-- Test profile changes and loans are
-- isolated in this transaction and rolled back; no Auth accounts are created.
BEGIN;
DO $$
DECLARE
  member_uuid UUID;
  auth_uuid UUID;
  other_member_uuid UUID;
  member_name TEXT;
  test_reference TEXT := 'CHECK-' || substr(gen_random_uuid()::TEXT, 1, 8);
BEGIN
  SELECT m.id, m.user_id, trim(m.first_name || ' ' || m.last_name)
  INTO member_uuid, auth_uuid, member_name
  FROM public.members m JOIN auth.users u ON u.id = m.user_id
  WHERE m.status = 'active'
  LIMIT 1;
  IF auth_uuid IS NULL THEN RAISE EXCEPTION 'An existing active linked profile is required for this check'; END IF;
  SELECT id INTO other_member_uuid FROM public.members WHERE id <> member_uuid LIMIT 1;

  -- Simulate completed password setup only inside this rolled-back test.
  UPDATE public.members SET must_change_password = FALSE WHERE id = member_uuid;
  PERFORM set_config('request.jwt.claims', jsonb_build_object(
    'sub', auth_uuid, 'role', 'authenticated',
    'app_metadata', jsonb_build_object('role', 'member')
  )::TEXT, TRUE);
  EXECUTE 'SET LOCAL ROLE authenticated';

  IF (SELECT count(*) FROM public.members WHERE id = member_uuid) <> 1 THEN
    RAISE EXCEPTION 'Member cannot read their own profile';
  END IF;
  IF EXISTS (SELECT 1 FROM public.members WHERE id <> member_uuid) THEN
    RAISE EXCEPTION 'Member can read another member profile';
  END IF;
  PERFORM count(*) FROM public.loan_payments;
  PERFORM count(*) FROM public.savings_accounts;
  PERFORM count(*) FROM public.notifications;

  BEGIN
    INSERT INTO public.loan_applications (
      application_id, member_id, member_name, loan_type, amount, status, date_submitted
    ) VALUES (test_reference, member_uuid, member_name, 'Regular', 1, 'pending', CURRENT_DATE);
    RAISE EXCEPTION 'Legacy direct submission bypassed required document saving';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    INSERT INTO public.loan_applications (
      application_id, member_id, member_name, loan_type, amount, status, date_submitted
    ) VALUES (test_reference || '-A', member_uuid, member_name, 'Regular', 1, 'approved', CURRENT_DATE);
    RAISE EXCEPTION 'Member was allowed to self-approve a loan';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF other_member_uuid IS NOT NULL THEN
    BEGIN
      INSERT INTO public.loan_applications (
        application_id, member_id, member_name, loan_type, amount, status, date_submitted
      ) VALUES (test_reference || '-B', other_member_uuid, member_name, 'Regular', 1, 'pending', CURRENT_DATE);
      RAISE EXCEPTION 'Member was allowed to submit a loan for another account';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
  END IF;
END;
$$;
ROLLBACK;
