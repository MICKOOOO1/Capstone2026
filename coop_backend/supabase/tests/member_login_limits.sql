BEGIN;
DO $$
DECLARE
  identifier TEXT := 'test-' || gen_random_uuid()::TEXT;
BEGIN
  FOR attempt IN 1..5 LOOP
    IF NOT public.reserve_member_login_attempt(identifier) THEN
      RAISE EXCEPTION 'Expected attempt % to be accepted', attempt;
    END IF;
  END LOOP;
  IF public.reserve_member_login_attempt(identifier) THEN
    RAISE EXCEPTION 'Sixth login attempt was not blocked';
  END IF;
  UPDATE public.member_login_limits SET window_started_at = NOW() - INTERVAL '16 minutes'
  WHERE identifier_hash = identifier;
  IF NOT public.reserve_member_login_attempt(identifier) THEN
    RAISE EXCEPTION 'Expired login window was not reset';
  END IF;
  IF (SELECT attempts FROM public.member_login_limits WHERE identifier_hash = identifier) <> 1 THEN
    RAISE EXCEPTION 'Reset login window has an incorrect attempt count';
  END IF;
  IF has_function_privilege('anon', 'public.reserve_member_login_attempt(text)', 'EXECUTE')
     OR has_table_privilege('authenticated', 'public.member_login_limits', 'SELECT') THEN
    RAISE EXCEPTION 'Login limiter is exposed to browser roles';
  END IF;
END;
$$;
ROLLBACK;
