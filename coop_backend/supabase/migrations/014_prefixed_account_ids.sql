-- Use CSUCC-YYYY-NNNN for newly generated IDs and the next-ID preview.
-- Keep the existing trigger and sequence; do not renumber account records.
BEGIN;

CREATE OR REPLACE FUNCTION public.generate_account_member_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  next_number BIGINT;
  creation_year TEXT;
BEGIN
  next_number := nextval('public.account_id_sequence'::regclass);
  creation_year := EXTRACT(
    YEAR FROM COALESCE(NEW.created_at, NOW()) AT TIME ZONE 'Asia/Manila'
  )::INTEGER::TEXT;

  NEW.member_id := 'CSUCC-' || creation_year || '-' || lpad(
    next_number::TEXT, greatest(4, length(next_number::TEXT)), '0'
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.preview_next_member_id()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  sequence_last_value BIGINT;
  sequence_is_called BOOLEAN;
  next_sequence_value BIGINT;
  account_year TEXT;
BEGIN
  SELECT last_value, is_called INTO sequence_last_value, sequence_is_called
  FROM public.account_id_sequence;

  next_sequence_value := sequence_last_value + CASE WHEN sequence_is_called THEN 1 ELSE 0 END;
  account_year := to_char(clock_timestamp() AT TIME ZONE 'Asia/Manila', 'YYYY');
  RETURN 'CSUCC-' || account_year || '-' || lpad(
    next_sequence_value::TEXT, greatest(4, length(next_sequence_value::TEXT)), '0'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.preview_next_member_id() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.preview_next_member_id() TO service_role;
NOTIFY pgrst, 'reload schema';
COMMIT;
