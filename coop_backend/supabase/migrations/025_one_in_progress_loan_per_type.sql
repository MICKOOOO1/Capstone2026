-- Prevent additional in-progress applications of a loan type while retaining
-- existing issued/history rows (including any pre-existing duplicates).
CREATE OR REPLACE FUNCTION public.prevent_duplicate_in_progress_loan_type()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
SET row_security = off
AS $$
BEGIN
  IF NEW.status IN ('pending','under review','approved','released','overdue') THEN
    PERFORM pg_advisory_xact_lock(
      hashtextextended(NEW.member_id::TEXT || ':' || lower(trim(NEW.loan_type)), 0)
    );
    IF EXISTS (
      SELECT 1 FROM public.loan_applications existing
      WHERE existing.member_id = NEW.member_id
        AND lower(trim(existing.loan_type)) = lower(trim(NEW.loan_type))
        AND existing.status IN ('pending','under review','approved','released','overdue')
        AND existing.id IS DISTINCT FROM NEW.id
    ) THEN
      RAISE EXCEPTION USING
        ERRCODE = '23505',
        MESSAGE = 'You already have an in-progress application or loan for this loan type.',
        CONSTRAINT = 'one_in_progress_loan_per_member_type';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.prevent_duplicate_in_progress_loan_type() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS prevent_duplicate_in_progress_loan_type ON public.loan_applications;
CREATE TRIGGER prevent_duplicate_in_progress_loan_type
  BEFORE INSERT ON public.loan_applications
  FOR EACH ROW EXECUTE FUNCTION public.prevent_duplicate_in_progress_loan_type();
