BEGIN;

-- Existing RLS policies restrict reads to the signed-in member's rows.
GRANT SELECT ON public.loan_payments, public.savings_accounts, public.notifications TO authenticated;
GRANT UPDATE (read) ON public.notifications TO authenticated;
GRANT INSERT (application_id, member_id, member_name, loan_type, amount, purpose, status, date_submitted)
  ON public.loan_applications TO authenticated;

ALTER POLICY "Users can insert own loan applications" ON public.loan_applications
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'member'
    AND status = 'pending'
    AND amount > 0
    AND date_approved IS NULL
    AND date_released IS NULL
    AND date_completed IS NULL
    AND EXISTS (
      SELECT 1 FROM public.members m
      WHERE m.id = loan_applications.member_id
        AND m.user_id = auth.uid()
        AND m.status = 'active'
        AND m.must_change_password = FALSE
    )
  );

NOTIFY pgrst, 'reload schema';
COMMIT;
