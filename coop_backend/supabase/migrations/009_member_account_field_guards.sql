CREATE OR REPLACE FUNCTION public.protect_member_account_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  request_role TEXT := COALESCE(NULLIF(auth.role(), ''), current_user::text);
  account_role TEXT := COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', '');
BEGIN
  IF NEW.member_id IS DISTINCT FROM OLD.member_id
     AND request_role NOT IN ('service_role', 'postgres', 'supabase_admin') THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Account IDs cannot be changed.';
  END IF;

  IF NEW.membership_type IS DISTINCT FROM OLD.membership_type
     AND request_role NOT IN ('service_role', 'postgres', 'supabase_admin')
     AND account_role NOT IN ('super_admin', 'admin', 'coop_admin') THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Only cooperative administrators can change membership classification.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_member_account_fields ON public.members;
CREATE TRIGGER protect_member_account_fields
  BEFORE UPDATE ON public.members
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_member_account_fields();
