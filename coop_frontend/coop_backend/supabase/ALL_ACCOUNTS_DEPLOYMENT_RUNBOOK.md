# CSUCC MPC All Accounts Deployment Runbook

**Project:** `jhgsqvxlvwhrwpcekvpq`
**Status:** Preparation only. No remote SQL, deployment, backup, or account changes have been performed.

## Deployment gate

Do not deploy the proposed migration until all of these are true:

1. A current read-only schema and account preflight has been reviewed against the linked project. Prior checks are historical snapshots, not a substitute for a pre-deployment check.
2. The reviewed proposal at `008_account_schema_reconciliation.proposed.sql` has been copied into a controlled, versioned deployment artifact and approved. Its local-only changes remove the default that would assign `Member` to future profiles with no verified role, and make the migration stop if an existing linked profile status conflicts with non-null Auth `account_status`.
3. The current remote migration ledger and SQL object definitions have been captured. The known ledger was empty for versions 001–007 while objects already existed.
4. A recoverable backup has been created and its restoration has been rehearsed in a separate non-production project.
5. The temporary access impact from removing the legacy Admin write policies is accepted and a maintenance window is scheduled.

**Do not run `supabase db push`, `supabase migration up`, `supabase db reset`, or any command that marks migrations 001–007 applied.** Do not replay those migrations. Migration 005 contains email-based profile linking; it is not appropriate to replay against the existing accounts. A later, separate decision is required to reconcile migration history for future CLI deployments.

## Final file compatibility review

- `008_account_schema_reconciliation.proposed.sql` is forward-only and preserves existing rows, but it must pass the deployment gate above. It does not restore the five loan RPCs from migration 003. The role column remains nullable; unlinked or unverified profiles are not backfilled as Members.
- `list-admin-accounts/index.ts` authorizes with verified Auth data and active account status, reads profiles and Auth users in pages, detects identifier-set changes, joins only on Auth user ID, and uses a stable final sort. It returns unknown roles as `Unknown`, rather than elevating them.
- `secure-admin-action/index.ts` requires a verified Super Admin, verifies the linked profile status, checks passwords before issuing grants, HMAC-binds a temporary password to the grant fingerprint, and consumes the action-specific grant before performing the action.
- `SecureAdminActionProvider.tsx` sends the same action secret during password verification and final execution. Final confirmation remains a separate UI step.
- `MembersData.tsx` includes an Unknown role filter; `RoleBadge.tsx` renders the label as “Unverified.”
- `src/app/super-admin/layout.tsx` applies `AdminPortalLayout` with `role="super_admin"`. `AdminPortalLayout` uses the `AdminAuthProvider` role guard and enables secure actions only for Super Admin. The server-side checks remain authoritative.

The current code was locally syntax/build/type/lint validated as described in the change report. The Edge Functions have not been type-checked or runtime-tested by Deno against the deployed Edge Runtime.

## 1. Backup and recovery preparation

1. Confirm the Dashboard is displaying project `jhgsqvxlvwhrwpcekvpq` before opening Backups or SQL Editor.
2. In **Database → Backups**, confirm a successful backup/recovery point exists after the final preflight and before the migration. Availability and retention depend on the project's plan. If using PITR, confirm the displayed recovery window includes the planned deployment time.
3. For an independently held logical backup, use the official Supabase CLI backup workflow to capture roles, schema, and data separately. Store the connection string in a secure credential manager or protected environment—not in command history, a script, or this runbook. Supabase's CLI workflow requires Docker and PostgreSQL client tools; the earlier local dump attempt was blocked because Docker/Podman was unavailable.
4. Verify recoverability by restoring/cloning the backup to a separate non-production project. Confirm the expected `members`, loan, payment, savings, notification, and Auth records are present, and compare aggregate row counts with the source preflight. Do not test restoration into production.
5. Record the backup timestamp, restore test result, approver, and recovery contact in the deployment ticket.

A schema-only dump is not a recoverable backup of account and loan data. Supabase database backups do not include files stored through the Storage API; this migration does not modify those files.

If the approved backup operator has Docker and PostgreSQL client tools available, the documented logical backup sequence is:

```powershell
Set-Location 'C:\Users\zylcee\Desktop\COOP\coop_backend'
if (-not $env:SUPABASE_DB_URL) { throw 'Set SUPABASE_DB_URL through a protected local secret store first.' }
npx --yes supabase@2.120.0 db dump --db-url $env:SUPABASE_DB_URL --file roles.sql --role-only
npx --yes supabase@2.120.0 db dump --db-url $env:SUPABASE_DB_URL --file schema.sql
npx --yes supabase@2.120.0 db dump --db-url $env:SUPABASE_DB_URL --file data.sql --data-only --use-copy --exclude storage.buckets_vectors --exclude storage.vector_indexes
```

Keep these files encrypted with access limited to the backup operators. Treat the connection string as a credential; do not put its value in the command, shell history, logs, or the backup files. These logical dumps still require a separate restore rehearsal and do not replace Storage object backups.

If the migration fails before `COMMIT`, ensure the SQL Editor reports the transaction as rolled back, then check the schema before retrying. After commit, prefer a reviewed forward corrective SQL change. Restoring a production backup is a last resort: it can cause downtime and discard all legitimate writes after the restore point.

## 2. Read-only preflight

Run and save results before any write:

- Verify the project reference and inspect the remote migration ledger. Expect no automatic ledger changes.
- Verify `public.members`, `loan_applications`, `loan_payments`, `savings_accounts`, and `notifications` exist.
- Inspect the actual `members` columns used by the proposal and functions: `id`, `user_id`, `member_id`, `first_name`, `last_name`, `email`, `department`, `role`, `membership_type`, `status`, `must_change_password`, `in_person_identity_verified`, `created_by`, and `created_at`.
- Inspect the existing `generate_member_id_before_insert` trigger and `public.generate_account_member_id()` definition. Verify it assigns `YYYY-NNNN` using the `Asia/Manila` creation year and `public.account_id_sequence`; do not recreate either object.
- Read `last_value` and `is_called` from `public.account_id_sequence` and compare the result with the known existing Account IDs. Treat the sequence state—not a frontend preview, row count, or maximum ID—as the next-number authority. Do not call `nextval` for a preview.
- Review `011_account_id_preview.sql` and verify only `service_role` can execute its non-advancing sequence preview function. The Edge Function must authenticate and authorize the Super Admin before returning this preview; it is not a reservation and can differ from the trigger-assigned ID.
- Count duplicate non-null `members.user_id` values; confirm the unique partial index can be created.
- Aggregate member status, membership type, and role values. Review all unsupported values before proceeding.
- Compare linked Auth `raw_app_meta_data.role` and `account_status` with profile role/status. Stop for manual review on any conflict; do not repair by email, name, or username.
- Count unlinked profiles and Auth users without profiles. Preserve them; do not invent links or profile data.
- Check whether the three account-management tables, their RLS flags, the required RPC functions/signatures, and existing policy names already exist.
- Capture the exact current RLS policy definitions and table grants for `members`, loan applications, and loan payments.
- Confirm that `admin_action_grants`, `admin_security_attempts`, and `admin_activity_logs` do not contain incompatible pre-existing shapes. `CREATE TABLE IF NOT EXISTS` does not reconcile an incorrectly shaped existing table.

Stop if the live schema differs materially from the reviewed baseline, if the role/status guard would fail, or if account counts differ unexpectedly. Re-review the proposal rather than editing the remote schema interactively.

## 3. Edge Function configuration and deployment

Required server-side environment names:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_PUBLISHABLE_KEY` **or** the existing `SUPABASE_ANON_KEY` fallback
- `SUPABASE_FUNCTION_ALLOWED_ORIGINS`: comma-separated exact admin frontend origins, including scheme and port where applicable; do not include paths or `*`.

Do not print, paste into tickets, or place any secret in source control or the frontend. These functions use the service-role credential only on the server.

The repository's Supabase CLI cache records version `2.120.0`; the following commands pin that CLI version. Run from PowerShell. `--use-api` bundles without local Docker. **Do not** add `--no-verify-jwt`; the deployment command must retain the CLI's default JWT verification.

```powershell
Set-Location 'C:\Users\zylcee\Desktop\COOP\coop_backend'
# Replace these with the exact origins serving the admin frontend.
$env:SUPABASE_FUNCTION_ALLOWED_ORIGINS = 'http://localhost:3000,https://admin.example.edu'
npx --yes supabase@2.120.0 secrets set "SUPABASE_FUNCTION_ALLOWED_ORIGINS=$env:SUPABASE_FUNCTION_ALLOWED_ORIGINS" --project-ref jhgsqvxlvwhrwpcekvpq
npx --yes supabase@2.120.0 functions deploy list-admin-accounts --project-ref jhgsqvxlvwhrwpcekvpq --use-api
npx --yes supabase@2.120.0 functions deploy secure-admin-action --project-ref jhgsqvxlvwhrwpcekvpq --use-api
```

Deploy only these named functions; do not omit function names (which deploys all local functions) and do not use `--prune`. Before deployment, confirm CLI login and project authorization interactively. Afterward, inspect each function's Dashboard configuration and confirm **Verify JWT** is enabled. The repository currently has no `supabase/config.toml` declaring per-function settings, so do not assume a local config override is present.

The secure-action preflight must allow only the configured exact origins, `POST`/`OPTIONS`, and the Supabase SDK headers `authorization`, `apikey`, `content-type`, `x-client-info`, `x-retry-count`, `traceparent`, `tracestate`, and `baggage`. Verify an unauthenticated `OPTIONS` preflight succeeds with the real admin origin after deployment, then verify an authenticated Super Admin can invoke the preview. Do not disable JWT verification to make the preflight pass.

## 4. Controlled database execution

After the Edge Function artifacts are deployed and the deployment gate is approved:

1. Keep the maintenance window open. Between function deployment and migration commit, account listing may return a schema error and secure actions may return an RPC/configuration error; neither should execute an action. Do not treat this as a successful test.
2. Open the Dashboard for `jhgsqvxlvwhrwpcekvpq`, confirm the project reference in the URL, then use **SQL Editor**.
3. Copy the complete, approved reconciliation SQL from its versioned deployment artifact into a new SQL Editor query. Do not paste migrations 001–007.
4. Review the editor contents against the approved artifact and run it once as a single transaction. The proposal contains `BEGIN`/`COMMIT`; do not split it into selected statements or run it concurrently with other schema changes.
5. If any statement fails, stop. Do not rerun only the failed statement or mark any migration version applied. Confirm rollback, collect the error, and reconcile forward from the actual catalog state.
6. After commit, perform the read-only schema/RLS/RPC checks below before declaring the backend ready.

Running through SQL Editor does not automatically create a migration ledger entry. Leave migration history unchanged. Resolve how to baseline/reconcile it through a separately reviewed process before future `db push` operations.

## 5. Post-migration authorization and account tests

Test first in a staging/isolated environment where possible. In production, use existing authorized accounts and non-destructive tests; do not create fake records, modify passwords, block accounts, or delete accounts just to exercise the workflow.

| Test | Expected outcome |
|---|---|
| Super Admin login | Existing trusted `super_admin` user reaches the Super Admin area; inactive/blocked or banned account is denied. |
| Admin login | Existing trusted `admin`/`coop_admin` user reaches only Admin routes; cannot use Super Admin account management actions. |
| Missing/invalid bearer token | Gateway/function rejects the request (401); no account data returned. |
| Authenticated Admin calls `list-admin-accounts` | Rejected (403); only a Super Admin may list all accounts. |
| Authenticated active Super Admin lists accounts | Success; linked records match existing Auth IDs and profile IDs. |
| Role mapping | Trusted Auth `super_admin`, `admin`/`coop_admin`, and `member` map to Super Admin, Admin, and Member respectively. Unknown/missing role displays as Unverified and never grants management permissions. |
| Unlinked profiles / Auth-only users | Reported as integrity issues; no automatic email linking or fabricated profile values. |
| Duplicate prevention | One row per linked Auth identity; duplicate profile linkage is reported and its management actions remain disabled. No rows are silently dropped. |
| Role, search, ID, status, membership filters | Each filter and combinations show only matching rows; unknown role can be filtered. |
| Pagination and ordering | UI pagination remains correct; backend pages through all Auth/profile rows, with stable ordering. An unstable snapshot returns a retryable error rather than a truncated list. For page-boundary tests, use a non-production dataset that crosses the 500-profile and 1,000-Auth page limits. |
| Banned or inactive Super Admin | Listing and secure-action requests are rejected. Confirm both Auth ban state and linked profile status paths in staging. |
| Wrong security password | No grant is issued and no operation occurs. |
| Correct password verification | One short-lived grant is issued for the exact actor, action, target, payload, and secret fingerprint; final confirmation is still required. |
| Cancel final confirmation | No operation occurs. |
| Confirm final action | Exactly the requested authorized action occurs; success/error is reported. |
| Change action/target/payload/temporary credential after verification | Grant does not match; no operation occurs. |
| Replay consumed grant | Rejected; no second operation occurs. |
| View Details | Works without password verification and does not modify records. |
| RLS and privileges | RLS remains enabled; grant/security/audit tables are inaccessible to `anon` and `authenticated`; approved server-side role/function permissions match the migration. |

Do not test destructive or status-changing operations against real accounts without a separately approved test plan and a designated test account.

After backend tests pass, release the matching frontend build through the project's existing hosting pipeline. Verify the deployed app is using the same Supabase project and the updated All Accounts code; the frontend release mechanism is not identified in this repository.

## 6. Remaining risks and blockers

- **Migration default / status conflict:** addressed in the local proposal, but the corrected proposal still requires final approval and versioned capture. The status guard intentionally aborts on conflicting Auth/profile status.
- **Migration history:** remote history is known to be inconsistent (versions 001–007 previously absent despite existing objects). Do not use `db push` or mark those versions applied as part of this release. Future CLI migration work remains blocked until a separate baseline decision.
- **Existing RLS policies:** the reconciliation removes broad Admin update policies on members, loan applications, and loan payments. The protected Edge Function path must be available and the full catalog/policy preflight must match expectations before commit. Direct Admin writes should be unavailable after cutover by design.
- **Loan RPCs:** the earlier audit found `check_loan_eligibility`, `calculate_payment_schedule`, `process_loan_approval`, `release_loan`, and `update_credit_score` missing remotely. Migration 008 does not restore them. All Accounts does not depend on them, but loan eligibility/approval/release features remain separately blocked or at risk. Do not include unreviewed loan-function restoration in this deployment.
- **Runtime:** no Deno runtime/type check or live Edge Function execution has been performed. `--use-api` addresses local bundling without Docker, not remote runtime validation.
- **Availability:** expect a short period where account listing and secure actions are unavailable between function deployment and successful SQL commit. SQL failure must halt the cutover; do not expose the UI as healthy based on local tests.
- **Backup restoration:** restoring a project can cause downtime and lose writes after the restore point. Prefer a forward fix after commit unless incident response explicitly approves a restore.
- **Live data verification:** no current live database query, account listing, or authorization test was run for this package.

## Official references

- [Supabase Edge Function deployment](https://supabase.com/docs/guides/functions/deploy)
- [Supabase database backups](https://supabase.com/docs/guides/platform/backups)
- [Supabase CLI backup and restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
