-- Test same-member/same-type duplicate blocking atomically without touching
-- real loans. All inserted test applications are rolled back.
BEGIN;
DO $$
DECLARE
  member_uuid UUID;
  application_ref TEXT := 'LA-' || to_char(CURRENT_DATE, 'YYYY') || '-' || lpad(floor(random() * 999999)::INT::TEXT, 6, '0');
BEGIN
  SELECT m.id INTO member_uuid
  FROM public.members m
  WHERE NOT EXISTS (
    SELECT 1 FROM public.loan_applications l
    WHERE l.member_id = m.id AND l.loan_type = 'Emergency'
      AND l.status IN ('pending','under review','approved','released','overdue')
  )
  LIMIT 1;
  IF member_uuid IS NULL THEN RAISE EXCEPTION 'No member without an active Emergency loan is available for this test'; END IF;

  INSERT INTO public.loan_applications(application_id,member_id,member_name,loan_type,amount,status,date_submitted)
    VALUES(application_ref,member_uuid,'Unique Loan Test','Emergency',1000,'pending',CURRENT_DATE);
  BEGIN
    INSERT INTO public.loan_applications(application_id,member_id,member_name,loan_type,amount,status,date_submitted)
      VALUES(application_ref || '1',member_uuid,'Unique Loan Test','Emergency',1000,'pending',CURRENT_DATE);
    RAISE EXCEPTION 'Duplicate in-progress application was allowed';
  EXCEPTION WHEN unique_violation THEN
    IF SQLERRM NOT LIKE 'You already have an in-progress application%' THEN RAISE; END IF;
  END;

  -- Rejected/completed history must not block a fresh application.
  UPDATE public.loan_applications SET status = 'rejected' WHERE application_id = application_ref;
  INSERT INTO public.loan_applications(application_id,member_id,member_name,loan_type,amount,status,date_submitted)
    VALUES(application_ref || '2',member_uuid,'Unique Loan Test','Emergency',1000,'pending',CURRENT_DATE);
END;
$$;
ROLLBACK;
