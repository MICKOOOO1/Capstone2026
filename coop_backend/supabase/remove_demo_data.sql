-- Run in Supabase SQL Editor to remove the original, unclaimed demo records.
-- Auth-linked members and records with real payment/savings activity are preserved.
BEGIN;

CREATE TEMP TABLE coop_demo_members ON COMMIT DROP AS
SELECT m.id
FROM public.members m
JOIN (VALUES
  ('M-001', 'juan@example.com', 'Juan', 'dela Cruz'),
  ('M-002', 'rosa@example.com', 'Rosa', 'Mendoza'),
  ('M-003', 'carlo@example.com', 'Carlo', 'Reyes'),
  ('2026-0001', 'juan@example.com', 'Juan', 'dela Cruz'),
  ('2026-0002', 'rosa@example.com', 'Rosa', 'Mendoza'),
  ('2026-0003', 'carlo@example.com', 'Carlo', 'Reyes'),
  ('M-004', 'ana@example.com', 'Ana', 'Torres'),
  ('M-005', 'pedro@example.com', 'Pedro', 'Santos'),
  ('M-006', 'luis@example.com', 'Luis', 'Garcia'),
  ('M-007', 'grace@example.com', 'Grace', 'Tan')
) AS seed(member_id, email, first_name, last_name)
ON m.member_id = seed.member_id AND m.email = seed.email
AND m.first_name = seed.first_name AND m.last_name = seed.last_name
WHERE m.user_id IS NULL
AND NOT EXISTS (
  SELECT 1 FROM auth.users u WHERE lower(u.email) = lower(m.email)
)
AND NOT EXISTS (SELECT 1 FROM public.savings_accounts s WHERE s.member_id = m.id)
AND NOT EXISTS (
  SELECT 1 FROM public.loan_payments p
  JOIN public.loan_applications l ON l.id = p.loan_application_id
  WHERE l.member_id = m.id
);

DELETE FROM public.loan_applications l
USING (VALUES
  ('LA-2025-0089', 'Juan dela Cruz', 75000, DATE '2025-07-25'),
  ('LA-2025-0088', 'Rosa Mendoza', 30000, DATE '2025-07-24'),
  ('LA-2025-0087', 'Carlo Reyes', 50000, DATE '2025-07-23'),
  ('LA-2025-0086', 'Ana Torres', 20000, DATE '2025-07-22'),
  ('LA-2025-0085', 'Pedro Santos', 80000, DATE '2025-07-21'),
  ('LA-2025-0084', 'Luis Garcia', 25000, DATE '2025-07-20'),
  ('LA-2025-0083', 'Grace Tan', 60000, DATE '2025-07-19')
) AS seed(application_id, member_name, amount, date_submitted)
WHERE l.member_id IN (SELECT id FROM coop_demo_members)
AND l.application_id = seed.application_id
AND l.member_name = seed.member_name
AND l.amount = seed.amount
AND l.date_submitted = seed.date_submitted;

DELETE FROM public.members m
WHERE m.id IN (SELECT id FROM coop_demo_members)
AND NOT EXISTS (SELECT 1 FROM public.loan_applications l WHERE l.member_id = m.id);

COMMIT;
