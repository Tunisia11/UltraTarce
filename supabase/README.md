# Trace Ultra Supabase Migrations

Phase 6 adds the remote Auth, tenant, business, storage, and future sync schema.
The Flutter app still writes normal inventory data to local Drift; remote business
repositories are only skeletons until the offline sync phase.

## CLI Setup

Install the Supabase CLI on the machine used for validation:

```bash
brew install supabase/tap/supabase
```

Other supported installers are documented by Supabase. After installing, verify:

```bash
supabase --version
```

## Local Migration Validation

Start the local Supabase stack, then reset/apply migrations:

```bash
supabase start
supabase db reset
```

If you only need to apply pending migrations to an already running local stack:

```bash
supabase migration up
```

If the Supabase CLI or Docker is unavailable, apply the files in timestamp order
from `supabase/migrations/` against a disposable dev database. Do not mark Phase
6.5 as fully validated until the migrations have actually run.

## SQL Smoke Tests

The smoke tests are transactional and roll back their seed data. Run them after
the migrations apply cleanly:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/001_rls_tenant_isolation.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/002_role_permissions.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/003_storage_policies.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/004_sync_metadata_schema.sql
```

For a local Supabase stack, get the database URL from:

```bash
supabase status
```

The tests cover:

- tenant A cannot read tenant B business rows
- non-members cannot read tenant business rows
- `read_only` can select but cannot insert/update
- owner and manager can write allowed rows
- cashier, stock manager, and accountant can write their scoped rows
- client hard deletes are blocked by the absence of broad DELETE policies
- file metadata RLS blocks cross-tenant access
- storage object policies are installed when the `storage` schema exists
- sync metadata columns and sync support table RLS are present

## Remote Dev Project

Link and push only to a disposable development Supabase project:

```bash
supabase link --project-ref <dev-project-ref>
supabase db push
```

Never use production data to validate these smoke tests.

## Required Flutter Configuration

The Flutter app must use the public anon/publishable key only:

```bash
--dart-define=SUPABASE_URL=https://<project>.supabase.co
--dart-define=SUPABASE_ANON_KEY=<anon-or-publishable-key>
```

`SUPABASE_PUBLISHABLE_KEY` is also accepted by the app config. Do not pass or
reference a `service_role` key in Flutter.

For local development without credentials:

```bash
--dart-define=TRACE_AUTH_BYPASS=true
```

## Storage Path Rule

Storage policies expect object paths to start with the tenant UUID:

```text
<tenant_id>/<folder>/<file>
```

Examples:

```text
00000000-0000-0000-0000-000000000000/logos/logo.png
00000000-0000-0000-0000-000000000000/products/product-1.png
```

## Storage Manual Checklist

Run this checklist in a local/dev Supabase project if object-level storage tests
are not automated by the local stack:

1. Sign in as tenant A user.
2. Upload `tenantA-uuid/logos/logo.png` to `tenant-logos`.
3. Verify tenant A can read the object.
4. Sign in as tenant B user.
5. Verify tenant B cannot read tenant A's object.
6. Verify tenant B cannot upload to a path beginning with tenant A's UUID.
7. Verify tenant B can upload to a path beginning with tenant B's UUID.

## Phase 7 Notes

- Keep normal business workflows local until the sync engine exists.
- Sync code should write through authenticated user sessions only.
- Conflict resolution should use `sync_conflicts` and never silently overwrite
  local Drift data.
- Admin or elevated actions must use trusted server-side code, not Flutter
  service-role credentials.

## Phase 7B Manual Push Smoke Test

Use a disposable local or dev Supabase project:

1. Run `supabase start` and `supabase db reset`.
2. Start Flutter with `SUPABASE_URL` and `SUPABASE_ANON_KEY`; do not enable
   `TRACE_AUTH_BYPASS` for the remote push test.
3. Create or sign in as a normal user, then create/select a tenant.
4. Create a product in Trace Ultra. The local Drift write should create a
   `sync_outbox` row.
5. Click `Synchroniser maintenant` in the inventory status bar.
6. Confirm the outbox row becomes `synced` locally.
7. Confirm the product exists in the remote `products` table for that tenant.
8. Sign in as a different tenant user and verify RLS blocks reading that row.

Phase 7B only pushes pending local changes. Pull sync, conflict resolution, and
storage/file sync are intentionally deferred.

## Cloud Pilot Verification

Run the app for the pilot with:

```bash
flutter run -d chrome \
  --dart-define=TRACE_CLOUD_PILOT=true \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

After creating pilot data and clicking `Synchroniser maintenant`, verify rows in
the dev Supabase database:

```sql
select count(*) from companies;
select count(*) from warehouses;
select count(*) from categories;
select count(*) from products;
select count(*) from partners;
select count(*) from documents;
select count(*) from document_lines;
select count(*) from payments;
select count(*) from stock_movements;
```

Pilot limitations to explain to the client:

- local Drift remains the source of truth
- sync is manual push to cloud only
- no pull sync yet
- one main device is recommended for the pilot

## Admin Virex Setup

To access the private platform admin dashboard (Phase 8A):

1. Find your auth user id in Supabase Dashboard -> Authentication -> Users.
2. Run SQL in the Supabase SQL Editor:

```sql
insert into public.platform_admins (user_id, email, role, status)
values (
  '<YOUR_AUTH_USER_ID>',
  '<YOUR_EMAIL>',
  'owner',
  'active'
)
on conflict (user_id) do update
set role = excluded.role,
    status = excluded.status,
    updated_at = now();
```

Then login to the Flutter app again and open the "Admin Virex" menu option.

## Phase 8B — Subscription Status

You can manage client SaaS access from the Virex Admin Dashboard. The system supports the following statuses:

- **trial**: can use (shows a trial ending warning)
- **active**: can use
- **overdue**: can use with warning (payment pending)
- **suspended**: blocked (UI is locked, but local data remains safe)
- **cancelled**: blocked (UI is locked)

If you need to set tenant status manually via SQL:

```sql
update public.tenant_subscriptions
set status = 'suspended',
    suspended_at = now(),
    admin_notes = 'Non paiement',
    updated_at = now()
where tenant_id = '<TENANT_ID>';
```

## Phase 8C: Team Management & Invitations

Migration: `20260502100000_tenant_team_invites.sql`

### Tables

- **tenant_invites**: Stores pending/accepted/cancelled invitations with `invite_token`.
- **tenant_users**: Extended with status constraint (`active`, `invited`, `disabled`).

### RLS Policies

- Tenant owners can create, read, and cancel invites.
- Invited users can see their own pending invite (by email match).
- Platform admins can read all invites and team data.
- No broad DELETE policies exist on either table.

### Invite Flow

1. Owner creates invite via the **Équipe** page → `INSERT into tenant_invites`.
2. Owner shares the invite code/email with the new user.
3. New user registers/logs in with matching email.
4. User opens **Mes invitations** from the user menu.
5. User accepts → calls `accept_tenant_invite(token)` (SECURITY DEFINER).
6. The function creates or updates `tenant_users` and marks the invite as accepted.

### Roles & Permissions

| Permission           | owner | manager | cashier | stock_manager | accountant | read_only |
|---------------------|-------|---------|---------|---------------|------------|-----------|
| Manage team          | ✅     |         |         |               |            |           |
| Manage company       | ✅     | ✅       |         |               |            |           |
| Create sales         | ✅     | ✅       | ✅       |               |            |           |
| Edit products        | ✅     | ✅       |         | ✅             |            |           |
| Manage stock         | ✅     | ✅       |         | ✅             |            |           |
| Validate documents   | ✅     | ✅       |         |               |            |           |
| View reports         | ✅     | ✅       |         |               | ✅          |           |
| Export backups       | ✅     | ✅       |         |               | ✅          |           |
| Record payments      | ✅     | ✅       | ✅       |               |            |           |

### Seats Limit

When `tenant_subscriptions.seats_limit` is set, the team page shows usage
and prevents inviting new members when the limit is reached.

### Smoke Test

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/007_team_roles_invites.sql
```

