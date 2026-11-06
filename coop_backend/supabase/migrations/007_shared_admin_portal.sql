CREATE OR REPLACE FUNCTION public.is_coop_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, auth
SET row_security = off
AS $$
  SELECT COALESCE(
    auth.jwt() -> 'app_metadata' ->> 'role' IN (
      'admin',
      'coop_admin',
      'super_admin'
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.members AS member
      WHERE member.user_id = auth.uid()
        AND member.status <> 'active'
    ),
    false
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_coop_admin() TO authenticated;

UPDATE auth.users AS auth_user
SET raw_app_meta_data =
  COALESCE(auth_user.raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object('account_status', member.status)
FROM public.members AS member
WHERE member.user_id = auth_user.id
  AND member.status IN ('active', 'inactive', 'suspended', 'blocked');

DROP POLICY IF EXISTS "Coop admins can manage loan payments"
  ON public.loan_payments;

DROP POLICY IF EXISTS "Coop admins can view all loan payments"
  ON public.loan_payments;

CREATE POLICY "Active admins can view all loan payments"
  ON public.loan_payments
  FOR SELECT
  TO authenticated
  USING (public.is_coop_admin());

CREATE OR REPLACE FUNCTION public.issue_admin_action_grant(
  p_user_id UUID,
  p_action_name TEXT,
  p_target_id TEXT,
  p_request_fingerprint TEXT,
  p_grant_token_hash TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
SET row_security = off
AS $$
DECLARE
  v_role TEXT;
  v_grant_id UUID;
BEGIN
  SELECT raw_app_meta_data ->> 'role'
    INTO v_role
  FROM auth.users
  WHERE id = p_user_id
    AND (banned_until IS NULL OR banned_until <= NOW());

  IF v_role IS DISTINCT FROM 'super_admin'
     OR EXISTS (
       SELECT 1
       FROM public.members
       WHERE user_id = p_user_id
         AND status <> 'active'
     ) THEN
    RAISE EXCEPTION 'Active Super Admin authorization required';
  END IF;

  INSERT INTO public.admin_action_grants (
    user_id,
    action_name,
    target_id,
    request_fingerprint,
    grant_token_hash,
    expires_at
  )
  VALUES (
    p_user_id,
    p_action_name,
    p_target_id,
    p_request_fingerprint,
    p_grant_token_hash,
    NOW() + INTERVAL '120 seconds'
  )
  RETURNING id INTO v_grant_id;

  RETURN v_grant_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_admin_action_grant(
  p_user_id UUID,
  p_action_name TEXT,
  p_target_id TEXT,
  p_request_fingerprint TEXT,
  p_grant_token_hash TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
SET row_security = off
AS $$
DECLARE
  v_role TEXT;
  v_grant_id UUID;
BEGIN
  SELECT raw_app_meta_data ->> 'role'
    INTO v_role
  FROM auth.users
  WHERE id = p_user_id
    AND (banned_until IS NULL OR banned_until <= NOW());

  IF v_role IS DISTINCT FROM 'super_admin'
     OR EXISTS (
       SELECT 1
       FROM public.members
       WHERE user_id = p_user_id
         AND status <> 'active'
     ) THEN
    RETURN FALSE;
  END IF;

  UPDATE public.admin_action_grants
  SET consumed_at = NOW()
  WHERE user_id = p_user_id
    AND action_name = p_action_name
    AND target_id = p_target_id
    AND request_fingerprint = p_request_fingerprint
    AND grant_token_hash = p_grant_token_hash
    AND consumed_at IS NULL
    AND expires_at > NOW()
  RETURNING id INTO v_grant_id;

  RETURN v_grant_id IS NOT NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.issue_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.consume_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.issue_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.consume_admin_action_grant(UUID, TEXT, TEXT, TEXT, TEXT)
  TO service_role;
