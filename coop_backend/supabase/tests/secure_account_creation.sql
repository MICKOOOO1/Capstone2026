-- Integration checks against existing accounts; all test rows are rolled back.
-- Does not create Auth accounts or advance the member/account ID sequence.
BEGIN;

DO $$
DECLARE
  actor UUID;
  ordinary_admin UUID;
  token_hash TEXT := gen_random_uuid()::TEXT;
  expired_hash TEXT := gen_random_uuid()::TEXT;
  protected_table TEXT;
BEGIN
  SELECT id INTO actor FROM auth.users
  WHERE public.is_active_secure_admin(id)
  LIMIT 1;
  IF actor IS NULL THEN RAISE EXCEPTION 'An existing active Super Admin is required for this test'; END IF;

  SELECT id INTO ordinary_admin FROM auth.users
  WHERE raw_app_meta_data ->> 'role' IN ('admin', 'coop_admin') LIMIT 1;

  PERFORM public.clear_admin_security_failures(actor);
  IF public.is_admin_security_rate_limited(actor) THEN RAISE EXCEPTION 'Empty attempts incorrectly rate limited'; END IF;
  FOR attempt IN 1..4 LOOP
    PERFORM public.record_admin_security_failure(actor);
  END LOOP;
  IF public.is_admin_security_rate_limited(actor) THEN RAISE EXCEPTION 'Four attempts incorrectly rate limited'; END IF;
  PERFORM public.record_admin_security_failure(actor);
  IF NOT public.is_admin_security_rate_limited(actor) THEN RAISE EXCEPTION 'Five attempts must be rate limited'; END IF;
  PERFORM public.clear_admin_security_failures(actor);
  IF public.is_admin_security_rate_limited(actor) THEN RAISE EXCEPTION 'Reset did not clear rate limit'; END IF;

  PERFORM public.issue_admin_action_grant(actor, 'create-account', 'new-account', 'test-fingerprint', token_hash);
  IF public.consume_admin_action_grant(actor, 'create-account', 'different-target', 'test-fingerprint', token_hash) THEN
    RAISE EXCEPTION 'Grant accepted a different target';
  END IF;
  IF public.consume_admin_action_grant(actor, 'create-account', 'new-account', 'different-fingerprint', token_hash) THEN
    RAISE EXCEPTION 'Grant accepted a different payload';
  END IF;
  IF NOT public.consume_admin_action_grant(actor, 'create-account', 'new-account', 'test-fingerprint', token_hash) THEN
    RAISE EXCEPTION 'Valid grant was rejected';
  END IF;
  IF public.consume_admin_action_grant(actor, 'create-account', 'new-account', 'test-fingerprint', token_hash) THEN
    RAISE EXCEPTION 'Consumed grant was accepted twice';
  END IF;

  PERFORM public.issue_admin_action_grant(actor, 'create-account', 'new-account', 'test-fingerprint', expired_hash);
  UPDATE public.admin_action_grants SET expires_at = NOW() - INTERVAL '1 second'
  WHERE grant_token_hash = expired_hash;
  IF public.consume_admin_action_grant(actor, 'create-account', 'new-account', 'test-fingerprint', expired_hash) THEN
    RAISE EXCEPTION 'Expired grant was accepted';
  END IF;

  IF ordinary_admin IS NOT NULL THEN
    BEGIN
      PERFORM public.issue_admin_action_grant(ordinary_admin, 'create-account', 'new-account', 'test', gen_random_uuid()::TEXT);
      RAISE EXCEPTION 'Ordinary Admin was allowed to issue a grant';
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM <> 'Active Super Admin authorization required' THEN RAISE; END IF;
    END;
  END IF;

  FOREACH protected_table IN ARRAY ARRAY['admin_security_attempts', 'admin_action_grants', 'admin_activity_logs'] LOOP
    IF has_table_privilege('authenticated', 'public.' || protected_table, 'SELECT')
      OR has_table_privilege('anon', 'public.' || protected_table, 'SELECT') THEN
      RAISE EXCEPTION 'Security table is readable by a browser role: %', protected_table;
    END IF;
  END LOOP;
  IF has_function_privilege('authenticated', 'public.issue_admin_action_grant(uuid,text,text,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Browser can directly issue security grants';
  END IF;
END;
$$;

ROLLBACK;
