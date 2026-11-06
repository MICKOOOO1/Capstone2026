BEGIN;

-- Policy changes must pass secure-admin-action password reauthentication and
-- its scoped, short-lived, single-use authorization grant.
DROP POLICY IF EXISTS "Only active Super Admins can update loan policy"
  ON public.loan_policy_settings;
REVOKE UPDATE ON public.loan_policy_settings FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.loan_policy_settings TO authenticated;

COMMIT;
