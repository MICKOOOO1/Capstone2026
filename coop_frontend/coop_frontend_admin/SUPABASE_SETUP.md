# Supabase Setup for Admin Web

This document explains how to set up the admin web application to connect to Supabase.

## Environment Variables

For deployment, set the following variables in the host environment or in an ignored `.env.local` file:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-publishable-or-anon-key
```

For local development, the Next.js config reuses `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the Flutter project's ignored root `.env`. Never put a service-role key in this project or expose it to a browser.

## Architecture

### Supabase Clients

The admin web uses two Supabase clients:

The browser client uses the publishable/anon key and the signed-in administrator's Supabase Auth session. Database RLS grants cross-member access only when the user's `app_metadata.role` is `coop_admin`.

### API Layer

The API layer (`src/lib/api.ts`) has been updated to use Supabase instead of the Node.js backend:

- `fetchLoanApplications()` - Fetches all loan applications from Supabase
- `fetchLoanApplicationById(id)` - Fetches a specific loan application
- `createLoanApplication(application)` - Creates a new loan application
- `updateLoanApplicationStatus(id, status)` - Updates loan application status
- `fetchMembers()` - Fetches all members (new)
- `updateMemberStatus(memberId, status)` - Updates member status (new)

## Data Flow

```
Flutter App → Supabase (PostgreSQL + RLS)
Admin Web → Supabase (PostgreSQL + Auth session + RLS)
```

Both the Flutter app and admin web connect to the same Supabase database:
- **Flutter app** uses the anon key with member-scoped RLS policies.
- **Admin web** uses that same anon key with an authenticated admin session and `coop_admin` RLS policies.

## Real-time Updates

The loan applications page subscribes to `loan_applications` changes and refreshes its list. Migration `005_shared_admin_and_app_fields.sql` enables that table in the Supabase Realtime publication.

## Running the Admin Web

1. Install dependencies:
```bash
cd coop_frontend_admin
npm install
```

2. For local development, ensure the root Flutter `.env` has the Supabase URL/key. For deployment, set the variables above in the hosting environment.

3. Run the development server:
```bash
npm run dev
```

4. Open http://localhost:3000

## Security Notes

- Never commit the `.env.local` file to version control
- Create admin users in Supabase Auth and set their server-managed `app_metadata.role` to `coop_admin`.
- Client-side role checks are for navigation; RLS in migration 005 is the data authorization boundary.
- Apply all migrations through `005_shared_admin_and_app_fields.sql` before signing in.

To assign the role to an existing Supabase Auth user, run this in the SQL Editor with that user's email:

```sql
UPDATE auth.users
SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"role":"coop_admin"}'::jsonb
WHERE email = 'admin@example.com';
```

Sign out and back in after changing the role so the refreshed session contains the new claim.

## Database Schema

The admin web expects the following Supabase tables:

- `members` - Member information
- `loan_applications` - Loan applications
- `loan_payments` - Loan payment records
- `savings_accounts` - Savings account information
- `notifications` - User notifications

Make sure you've applied the database migrations from `supabase/migrations/` in the Flutter project.
