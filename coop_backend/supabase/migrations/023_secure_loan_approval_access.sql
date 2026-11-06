-- The secure-admin-action Edge Function validates the Super Admin grant,
-- member eligibility, policy and documents before it reads/approves loans.
-- Browser roles retain only their existing RLS-scoped permissions.
GRANT SELECT, UPDATE ON public.loan_applications TO service_role;
