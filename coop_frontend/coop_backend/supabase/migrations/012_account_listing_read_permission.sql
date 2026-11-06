-- The authenticated Edge Function uses service_role for account listing.
-- This does not change anon/authenticated grants, RLS, or account records.
GRANT SELECT ON TABLE public.members TO service_role;
