BEGIN;

-- Policy writes execute only after secure-admin-action has verified the
-- Super Admin password and consumed its single-use action grant.
GRANT SELECT, UPDATE ON public.loan_policy_settings TO service_role;

CREATE OR REPLACE FUNCTION public.audit_loan_policy_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  actor UUID := COALESCE(auth.uid(), NEW.updated_by);
BEGIN
  IF actor IS NULL THEN RAISE EXCEPTION 'A verified policy actor is required.'; END IF;
  NEW.updated_at := NOW();
  NEW.updated_by := actor;
  INSERT INTO public.loan_policy_audit_log (actor_id, old_policy, new_policy)
  VALUES (actor, to_jsonb(OLD), to_jsonb(NEW));
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.audit_loan_policy_change() FROM PUBLIC, anon, authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
