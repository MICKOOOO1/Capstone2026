-- CSUCC COOP Supabase setup
-- Run this in Supabase Dashboard > SQL Editor for a new project.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  member_id VARCHAR(50) UNIQUE NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL DEFAULT '',
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20),
  address TEXT,
  income DECIMAL(15, 2),
  credit_score INT DEFAULT 700,
  date_joined DATE DEFAULT CURRENT_DATE,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.loan_applications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  application_id VARCHAR(50) UNIQUE NOT NULL,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  member_name VARCHAR(200) NOT NULL,
  loan_type VARCHAR(50) NOT NULL CHECK (loan_type IN (
    'Regular', 'Medical', 'Educational', 'Emergency', 'Business',
    'Calamity', 'Multi-Purpose', 'Quick', 'Livelihood', 'Appliance',
    'Birthday', 'Anniversary', 'Fiesta', 'Bonus', 'Collateral',
    'Mortuary', 'Subsistence', 'ASSME'
  )),
  amount DECIMAL(15, 2) NOT NULL,
  purpose TEXT,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'under review', 'approved', 'rejected', 'released', 'completed', 'overdue')),
  income DECIMAL(15, 2),
  credit_score INT,
  date_submitted DATE NOT NULL,
  date_approved DATE,
  date_released DATE,
  date_completed DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.loan_payments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  loan_application_id UUID NOT NULL REFERENCES public.loan_applications(id) ON DELETE CASCADE,
  payment_amount DECIMAL(15, 2) NOT NULL,
  payment_date DATE NOT NULL,
  payment_method VARCHAR(50) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'automatic')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.savings_accounts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  account_number VARCHAR(50) UNIQUE NOT NULL,
  balance DECIMAL(15, 2) DEFAULT 0.00,
  account_type VARCHAR(50) DEFAULT 'regular' CHECK (account_type IN ('regular', 'special', 'time_deposit')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_members_member_id ON public.members(member_id);
CREATE INDEX IF NOT EXISTS idx_members_user_id ON public.members(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_applications_member_id ON public.loan_applications(member_id);
CREATE INDEX IF NOT EXISTS idx_loan_applications_application_id ON public.loan_applications(application_id);
CREATE INDEX IF NOT EXISTS idx_loan_applications_status ON public.loan_applications(status);
CREATE INDEX IF NOT EXISTS idx_loan_applications_date_submitted ON public.loan_applications(date_submitted);
CREATE INDEX IF NOT EXISTS idx_loan_payments_loan_application_id ON public.loan_payments(loan_application_id);
CREATE INDEX IF NOT EXISTS idx_savings_accounts_member_id ON public.savings_accounts(member_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_members_updated_at ON public.members;
CREATE TRIGGER update_members_updated_at
  BEFORE UPDATE ON public.members
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_loan_applications_updated_at ON public.loan_applications;
CREATE TRIGGER update_loan_applications_updated_at
  BEFORE UPDATE ON public.loan_applications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_savings_accounts_updated_at ON public.savings_accounts;
CREATE TRIGGER update_savings_accounts_updated_at
  BEFORE UPDATE ON public.savings_accounts
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.is_coop_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
  SELECT COALESCE(auth.jwt() -> 'app_metadata' ->> 'role' = 'coop_admin', false);
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_member_id TEXT;
BEGIN
  base_member_id := 'M-' || upper(substr(replace(NEW.id::TEXT, '-', ''), 1, 8));

  INSERT INTO public.members (user_id, member_id, first_name, last_name, email)
  VALUES (
    NEW.id,
    base_member_id,
    COALESCE(NEW.raw_user_meta_data ->> 'first_name', split_part(COALESCE(NEW.email, 'Member'), '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'last_name', ''),
    NEW.email
  )
  ON CONFLICT (email) DO UPDATE SET user_id = EXCLUDED.user_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own member data" ON public.members;
CREATE POLICY "Users can view own member data"
  ON public.members FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own member data" ON public.members;
CREATE POLICY "Users can update own member data"
  ON public.members FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Coop admins can view all members" ON public.members;
CREATE POLICY "Coop admins can view all members"
  ON public.members FOR SELECT TO authenticated
  USING (public.is_coop_admin());

DROP POLICY IF EXISTS "Coop admins can update members" ON public.members;
CREATE POLICY "Coop admins can update members"
  ON public.members FOR UPDATE TO authenticated
  USING (public.is_coop_admin())
  WITH CHECK (public.is_coop_admin());

DROP POLICY IF EXISTS "Users can view own loan applications" ON public.loan_applications;
CREATE POLICY "Users can view own loan applications"
  ON public.loan_applications FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.members
    WHERE members.id = loan_applications.member_id
      AND members.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Users can insert own loan applications" ON public.loan_applications;
CREATE POLICY "Users can insert own loan applications"
  ON public.loan_applications FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.members
    WHERE members.id = loan_applications.member_id
      AND members.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Coop admins can view all loan applications" ON public.loan_applications;
CREATE POLICY "Coop admins can view all loan applications"
  ON public.loan_applications FOR SELECT TO authenticated
  USING (public.is_coop_admin());

DROP POLICY IF EXISTS "Coop admins can update loan applications" ON public.loan_applications;
CREATE POLICY "Coop admins can update loan applications"
  ON public.loan_applications FOR UPDATE TO authenticated
  USING (public.is_coop_admin())
  WITH CHECK (public.is_coop_admin());

DROP POLICY IF EXISTS "Users can view own loan payments" ON public.loan_payments;
CREATE POLICY "Users can view own loan payments"
  ON public.loan_payments FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.loan_applications
    JOIN public.members ON members.id = loan_applications.member_id
    WHERE loan_applications.id = loan_payments.loan_application_id
      AND members.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Coop admins can view all loan payments" ON public.loan_payments;
CREATE POLICY "Coop admins can view all loan payments"
  ON public.loan_payments FOR SELECT TO authenticated
  USING (public.is_coop_admin());

DROP POLICY IF EXISTS "Users can view own savings accounts" ON public.savings_accounts;
CREATE POLICY "Users can view own savings accounts"
  ON public.savings_accounts FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.members
    WHERE members.id = savings_accounts.member_id
      AND members.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Coop admins can view all savings accounts" ON public.savings_accounts;
CREATE POLICY "Coop admins can view all savings accounts"
  ON public.savings_accounts FOR SELECT TO authenticated
  USING (public.is_coop_admin());

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

INSERT INTO public.members (member_id, first_name, last_name, email, phone, address, income, credit_score) VALUES
('M-001', 'Juan', 'dela Cruz', 'juan@example.com', '09171234567', '123 Main St, Manila', 120000, 750),
('M-002', 'Rosa', 'Mendoza', 'rosa@example.com', '09181234567', '456 Oak Ave, Quezon City', 95000, 720),
('M-003', 'Carlo', 'Reyes', 'carlo@example.com', '09191234567', '789 Pine Rd, Makati', 150000, 780)
ON CONFLICT (member_id) DO NOTHING;

INSERT INTO public.loan_applications (application_id, member_id, member_name, loan_type, amount, purpose, status, income, credit_score, date_submitted) VALUES
('LA-2025-0089', (SELECT id FROM public.members WHERE member_id = 'M-001'), 'Juan dela Cruz', 'Regular', 75000.00, 'Business expansion', 'pending', 120000, 750, '2025-07-25'),
('LA-2025-0088', (SELECT id FROM public.members WHERE member_id = 'M-002'), 'Rosa Mendoza', 'Medical', 30000.00, 'Medical emergency', 'under review', 95000, 720, '2025-07-24'),
('LA-2025-0087', (SELECT id FROM public.members WHERE member_id = 'M-003'), 'Carlo Reyes', 'Educational', 50000.00, 'Tuition fee payment', 'approved', 150000, 780, '2025-07-23')
ON CONFLICT (application_id) DO NOTHING;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'loan_applications'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.loan_applications;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'members'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.members;
    END IF;
  END IF;
END;
$$;
