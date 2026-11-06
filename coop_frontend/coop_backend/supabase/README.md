# Supabase Setup Guide

This directory contains all the Supabase configuration for the CSUCCERMPC app.

## Database Migrations

**Do not replay migrations 001–007 against the linked production project.** Its
remote migration ledger is inconsistent with its existing schema and account
data. In particular, migration 005 contains email-based account linking.
`db push`, `migration up`, and marking historical migrations applied are not
approved deployment steps.

The proposed forward-only account reconciliation remains subject to final
review and approval. Follow
[ALL_ACCOUNTS_DEPLOYMENT_RUNBOOK.md](./ALL_ACCOUNTS_DEPLOYMENT_RUNBOOK.md) for
the required backup, current read-only preflight, controlled SQL execution,
Edge Function cutover, and tests. Do not execute SQL from this README.

## Super Admin Portal Authentication

The admin website uses Supabase Auth. Configure these public values in
`coop_frontend_admin/.env.local`:

```text
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-supabase-publishable-key
```

Grant existing Super Admin users the `super_admin` value in server-controlled
`app_metadata.role` using a trusted Supabase administrative process. Do not set
authorization roles through client-editable user metadata. The portal rejects
accounts without this role.

The shared login redirects users with trusted `app_metadata.role` values of
`super_admin` to `/super-admin/dashboard` and `admin` to `/admin/dashboard`.
The existing `coop_admin` role remains accepted as an Admin alias. Admin pages
are read-only until permissions are confirmed; protected account and loan writes
remain Super Admin-only on the server. Assign Admin roles only through a trusted
Supabase administrative process. The Admin role must never be put in
`user_metadata`.

Create Auth users under **Authentication → Users** and set or reset their
password there; SQL role assignment does not create a user or set a password.
For a new Admin user, update `auth.users.raw_app_meta_data` to include
`{"role":"admin"}`. Existing `coop_admin` metadata continues to work as an
Admin role.

Deploy `list-admin-accounts`, `secure-admin-action`, `loan-approval`, and `loan-release` from the
`supabase/functions` directory. The loan approval/release functions require a
matching, unexpired, single-use grant. Configure `SUPABASE_URL`,
`SUPABASE_PUBLISHABLE_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` as Edge Function
secrets. Existing projects may continue to use `SUPABASE_ANON_KEY` instead.
The service role key must never be placed in the admin website. The Express
loan-status endpoint also requires these values server-side.

`list-admin-accounts` allows active callers with trusted `app_metadata.role`
values of `super_admin`, `admin`, or `coop_admin` to read accounts. It uses the
server-side service role to join Auth users with
`public.members` by Auth user ID. It returns unlinked records as integrity
issues and does not fabricate missing profile data. It requires the reviewed
account reconciliation schema and secure-action functions; do not assume the
remote project has them until deployment has been verified.

Account listing is read-only. Protected account modifications continue to
require a Super Admin through `secure-admin-action`.

Grants are bound to the authenticated Super Admin, action, target ID, and a
request fingerprint that includes non-secret action data and a keyed digest of
temporary credentials where applicable. Grants expire after 120 seconds and
are consumed atomically once. Failed password verification is limited to five
attempts per 15 minutes.

## Edge Functions

Edge Functions are serverless functions for sensitive business logic:

- **secure-admin-action**: Reauthenticates Super Admins, issues and consumes action grants, provisions accounts, and performs protected account and loan operations
- **loan-approval**: Processes loan approval logic
- **loan-eligibility**: Checks if a member is eligible for a loan
- **loan-release**: Releases approved loans
- **notifications**: Sends notifications to users

### Edge Function Deployment

Do not deploy functions as part of local validation. The approved All Accounts
cutover deploys only `list-admin-accounts` and `secure-admin-action`, with JWT
verification enabled. See
[ALL_ACCOUNTS_DEPLOYMENT_RUNBOOK.md](./ALL_ACCOUNTS_DEPLOYMENT_RUNBOOK.md) for
the project-scoped commands and required environment variable names. Do not
deploy all functions, use `--no-verify-jwt`, or change project secrets as part
of this procedure.

The Super Admin create-account action intentionally omits `members.member_id`
so the existing database trigger and sequence assign the readable Account ID;
do not recreate the sequence or trigger. Review and apply
`009_member_account_field_guards.sql` through the approved schema process to
prevent authenticated users from changing that ID or ordinary members from
changing membership classification. This guard does not replace or modify
RLS policies. Migration `010_membership_type_labels.sql` normalizes legacy
lowercase membership values to `Regular` and `Associate` and updates the
existing membership constraint; inspect its preflight check before applying
it. Migration `011_account_id_preview.sql` adds a service-role-only RPC that
reads `account_id_sequence.last_value` and `is_called` without advancing the
sequence. The `secure-admin-action` Edge Function exposes this only after
verifying an active Super Admin. The displayed value is only a preview; the
existing insert trigger assigns the definitive ID. Apply schema changes only
after completing the account/schema preflight in the deployment runbook.
Deploy the updated Edge Function after the database migrations are approved
and applied.

`secure-admin-action` CORS is restricted to exact origins configured in the
server-side `COOP_ADMIN_ALLOWED_ORIGINS` Edge Function secret. Include
the frontend origin(s), for example `http://localhost:3000` for local
development and the exact deployed admin origin; do not use `*`. The function
allows only `POST`/`OPTIONS` and known Supabase SDK request headers. Deploy
with JWT verification left enabled, then validate the OPTIONS preflight and an
authenticated preview request against the same project used by the frontend.

## Database Functions

The following database functions are available for use:

### check_loan_eligibility(p_member_id, p_loan_type, p_amount)
Checks if a member is eligible for a loan based on:
- Member status (must be active)
- Credit score
- Income
- Existing loans
- Savings balance
- Payment history

Returns: eligibility status, max loan amount, and reason

### calculate_payment_schedule(p_loan_amount, p_interest_rate, p_term_months)
Calculates amortization schedule for a loan.

Returns: payment schedule with principal, interest, and remaining balance for each payment

### process_loan_approval(p_application_id, p_approved_by, p_notes)
Processes loan approval by:
- Checking eligibility
- Automatically rejecting if not eligible
- Updating loan status to approved

Returns: success status, message, and new status

### release_loan(p_application_id)
Releases an approved loan by updating status to 'released' and setting release date.

Returns: success status and message

### update_credit_score(p_member_id)
Updates a member's credit score based on payment history.

Returns: new credit score

## Storage Setup

Create storage buckets in Supabase:

1. Go to Storage in your Supabase dashboard
2. Create a bucket named `documents` for loan documents
3. Create a bucket named `profile-images` for member profile pictures
4. Set appropriate RLS policies for each bucket

## Flutter Integration

The Flutter member client signs in with its complete Member ID and password
through `member-auth`. Login supports `CSUCC-YYYY-NNNN` and existing `YYYY-NNNN`
IDs. The function validates passwords using Supabase Auth and only returns a
session for an active, linked member account. It never publishes an ID-to-email
directory. First-login password changes clear `members.must_change_password`
only after the password update succeeds.

`member-auth` is an unauthenticated login endpoint, so its gateway JWT check is
disabled specifically in `config.toml`. Its password-change mode verifies the
member's JWT explicitly. The admin functions retain gateway JWT verification.
Deploy this endpoint from `coop_backend` using:

```powershell
npx --yes supabase@2.120.0 functions deploy member-auth --project-ref jhgsqvxlvwhrwpcekvpq --use-api
```

For loan email verification, configure **Authentication → Email Templates →
Magic Link** in the hosted project's Dashboard. The default template sends a
sign-in link, not an OTP. Set the subject to `Your CSUCC loan verification code`
and paste `coop_frontend_client/supabase/templates/magic_link_otp.html` as the
body; it includes Supabase's `{{ .Token }}` placeholder. The live Auth config
uses an 8-digit OTP, and Flutter accepts 8 digits. Save the Dashboard template
and test using a real linked member email. Local `config.toml` template settings
do not update a hosted project's email template.

Migration 015 installs a server-only five-attempt/15-minute login limiter.
Migration 016 restores member app read access under the existing RLS policies
and limits member loan submissions to their own pending applications after
temporary-password setup. Review these forward-only files when configuring
another Supabase project; do not replay historical migrations on this project.

Migration 017 creates the private `loan-documents` storage bucket, document
metadata table, own-account-only RLS policies, a server-verified atomic
loan-and-document submission RPC, and removes the direct client loan insert
grant. Migration 018 grants active Admin/Coop Admin/Super Admin loan-review
read access required by the admin Documents modal. These forward migrations
have been applied to the linked production project.

Migrations 019–020 add persistent loan policy settings with Super-Admin-only
updates and an audit trail. The live calculator reads the saved base interest,
processing/service fees, and amount bounds; loan submission rechecks amount,
membership tenure, collateral threshold, and repayment tenure in the database.
Migration 022 removes direct browser update privileges: policy changes must be
reauthenticated and confirmed through the `update-loan-policy` secure action.
Migration 025 prevents a member from having more than one in-progress loan
application or loan of the same type. It preserves pre-existing records and
does not prevent reapplying after a previous application is rejected or a loan
is completed.

The Flutter app has been configured with:
- `supabase_flutter` dependency
- Environment variables in `.env` file
- Supabase initialization in `main.dart`
- SupabaseService class for common operations

### Usage in Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

// Authentication
await SupabaseService().signIn(email: 'user@example.com', password: 'password');
await SupabaseService().signOut();

// Database operations
final supabase = Supabase.instance.client;
final data = await supabase.from('members').select().eq('user_id', userId);

// Call database functions
final eligibility = await supabase.rpc('check_loan_eligibility', params: {
  'p_member_id': memberId,
  'p_loan_type': 'Regular',
  'p_amount': 50000
});

// Sensitive admin Edge Functions also require a grant issued after password
// reauthentication. Direct calls without a matching grant are rejected.
```

## Security Notes

- Never commit the `.env` file to version control
- The service role key is for server-side use only (Edge Functions)
- The anon key is safe for client-side use due to RLS policies
- RLS policies ensure users can only access their own data
- Edge Functions use service role key for elevated privileges
