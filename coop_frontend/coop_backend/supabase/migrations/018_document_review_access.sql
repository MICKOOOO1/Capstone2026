-- Admins/Super Admins can review the loan containing the private attachments.
CREATE POLICY "Active document reviewers can read loan applications"
ON public.loan_applications FOR SELECT TO authenticated
USING (public.can_review_loan_documents());
