-- Forward-only setup for the deployed secure-admin-action function.
-- Preserve existing account IDs, profiles, Auth roles, and sequence state.
BEGIN;

ALTER TABLE public.members
  ADD COLUMN IF NOT EXISTS department TEXT,
  ADD COLUMN IF NOT EXISTS role VARCHAR(40),
  ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS in_person_identity_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

CREATE TABLE IF NOT EXISTS public.admin_action_grants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_name TEXT NOT NULL,
  target_id TEXT NOT NULL,
  request_fingerprint TEXT NOT NULL,
  grant_token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS admin_action_grants_expiration_idx
  ON public.admin_action_grants(expires_at);

CREATE TABLE IF NOT EXISTS public.admin_security_attempts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS admin_security_attempts_user_time_idx
  ON public.admin_security_attempts(user_id, attempted_at DESC);

CREATE TABLE IF NOT EXISTS public.admin_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL REFERENCES auth.users(id),
  action_name TEXT NOT NULL,
  target_id TEXT NOT NULL,
  result TEXT NOT NULL CHECK (result IN ('success', 'failure')),
  details JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_action_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_security_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_activity_logs ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.admin_action_grants, public.admin_security_attempts,
  public.admin_activity_logs FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_action_grants,
  public.admin_security_attempts TO service_role;
GRANT SELECT, INSERT ON public.admin_activity_logs TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.admin_security_attempts_id_seq TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.members TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.account_id_sequence TO service_role;

CREATE OR REPLACE FUNCTION public.is_admin_security_rate_limited(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT COUNT(*) >= 5
  FROM public.admin_security_attempts
  WHERE user_id = p_user_id
    AND attempted_at > NOW() - INTERVAL '15 minutes';
$$;

CREATE OR REPLACE FUNCTION public.record_admin_security_failure(p_user_id UUID)
RETURNS VOID
LANGUAGE SQL
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  INSERT INTO public.admin_security_attempts (user_id) VALUES (p_user_id);
$$;

CREATE OR REPLACE FUNCTION public.clear_admin_security_failures(p_user_id UUID)
RETURNS VOID
LANGUAGE SQL
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  DELETE FROM public.admin_security_attempts WHERE user_id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION public.is_active_secure_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u
    WHERE u.id = p_user_id
      AND u.raw_app_meta_data ->> 'role' = 'super_admin'
      AND (u.banned_until IS NULL OR u.banned_until <= NOW())
      AND COALESCE(u.raw_app_meta_data ->> 'account_status', 'active') = 'active'
      AND NOT EXISTS (
        SELECT 1 FROM public.members m
        WHERE m.user_id = u.id AND m.status IS DISTINCT FROM 'active'
      )
      AND (
        EXISTS (SELECT 1 FROM public.members m WHERE m.user_id = u.id)
        OR u.raw_app_meta_data ->> 'account_status' = 'active'
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.issue_admin_action_grant(
  p_user_id UUID, p_action_name TEXT, p_target_id TEXT,
  p_request_fingerprint TEXT, p_grant_token_hash TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  grant_id UUID;
BEGIN
  IF NOT public.is_active_secure_admin(p_user_id) THEN
    RAISE EXCEPTION 'Active Super Admin authorization required';
  END IF;

  INSERT INTO public.admin_action_grants (
    user_id, action_name, target_id, request_fingerprint, grant_token_hash, expires_at
  ) VALUES (
    p_user_id, p_action_name, p_target_id, p_request_fingerprint,
    p_grant_token_hash, NOW() + INTERVAL '120 seconds'
  ) RETURNING id INTO grant_id;

  RETURN grant_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_admin_action_grant(
  p_user_id UUID, p_action_name TEXT, p_target_id TEXT,
  p_request_fingerprint TEXT, p_grant_token_hash TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  grant_id UUID;
BEGIN
  IF NOT public.is_active_secure_admin(p_user_id) THEN RETURN FALSE; END IF;

  UPDATE public.admin_action_grants SET consumed_at = NOW()
  WHERE user_id = p_user_id
    AND action_name = p_action_name
    AND target_id = p_target_id
    AND request_fingerprint = p_request_fingerprint
    AND grant_token_hash = p_grant_token_hash
    AND consumed_at IS NULL
    AND expires_at > NOW()
  RETURNING id INTO grant_id;

  RETURN grant_id IS NOT NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin_security_rate_limited(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.record_admin_security_failure(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.clear_admin_security_failures(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.is_active_secure_admin(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.issue_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.consume_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.is_admin_security_rate_limited(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.record_admin_security_failure(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.clear_admin_security_failures(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.is_active_secure_admin(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.issue_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.consume_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT) TO service_role;

NOTIFY pgrst, 'reload schema';
COMMIT;
