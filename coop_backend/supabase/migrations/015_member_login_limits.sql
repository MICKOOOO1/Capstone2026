BEGIN;

CREATE TABLE IF NOT EXISTS public.member_login_limits (
  identifier_hash TEXT PRIMARY KEY,
  attempts INTEGER NOT NULL CHECK (attempts BETWEEN 1 AND 5),
  window_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.member_login_limits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.member_login_limits FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.member_login_limits TO service_role;

-- Reserve one attempt atomically before checking credentials. Successful
-- authentication clears the bucket; five failures block for 15 minutes.
CREATE OR REPLACE FUNCTION public.reserve_member_login_attempt(p_identifier_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  reserved TEXT;
BEGIN
  INSERT INTO public.member_login_limits (identifier_hash, attempts)
  VALUES (p_identifier_hash, 1)
  ON CONFLICT (identifier_hash) DO UPDATE
  SET attempts = CASE
        WHEN member_login_limits.window_started_at <= NOW() - INTERVAL '15 minutes' THEN 1
        ELSE member_login_limits.attempts + 1
      END,
      window_started_at = CASE
        WHEN member_login_limits.window_started_at <= NOW() - INTERVAL '15 minutes' THEN NOW()
        ELSE member_login_limits.window_started_at
      END
  WHERE member_login_limits.attempts < 5
    OR member_login_limits.window_started_at <= NOW() - INTERVAL '15 minutes'
  RETURNING identifier_hash INTO reserved;
  RETURN reserved IS NOT NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.reserve_member_login_attempt(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_member_login_attempt(TEXT) TO service_role;
NOTIFY pgrst, 'reload schema';
COMMIT;
