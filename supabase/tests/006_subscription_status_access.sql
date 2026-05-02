begin;
select plan(7);

-- 1. Create a platform admin user
select * from tests.create_supabase_user('admin@trace.test');
insert into public.platform_admins (user_id)
select id from auth.users where email = 'admin@trace.test';

-- 2. Create normal tenant users
select * from tests.create_supabase_user('owner1@trace.test');
select * from tests.create_supabase_user('owner2@trace.test');

-- 3. Create tenants using the platform admin to bypass RLS initially
select tests.authenticate_as('admin@trace.test');
insert into public.tenants (id, name, status) values
  ('11111111-1111-1111-1111-111111111111', 'Tenant 1', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'Tenant 2', 'active');

insert into public.tenant_subscriptions (tenant_id, plan, status) values
  ('11111111-1111-1111-1111-111111111111', 'pilot', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'pilot', 'suspended');

-- 4. Assign ownership
insert into public.tenant_users (tenant_id, user_id, role)
select '11111111-1111-1111-1111-111111111111', id, 'owner'
from auth.users where email = 'owner1@trace.test';

insert into public.tenant_users (tenant_id, user_id, role)
select '22222222-2222-2222-2222-222222222222', id, 'owner'
from auth.users where email = 'owner2@trace.test';

-- 5. Test normal tenant member access (Tenant 1)
select tests.authenticate_as('owner1@trace.test');

select results_eq(
  $$ select tenant_id from public.tenant_subscriptions $$,
  $$ values ('11111111-1111-1111-1111-111111111111'::uuid) $$,
  'Normal tenant member can SELECT only their own tenant subscription'
);

select throws_ok(
  $$ update public.tenant_subscriptions set status = 'active' where tenant_id = '11111111-1111-1111-1111-111111111111' $$,
  'new row violates row-level security policy for table "tenant_subscriptions"',
  'Normal tenant member cannot update their own subscription'
);

select throws_ok(
  $$ delete from public.tenant_subscriptions where tenant_id = '11111111-1111-1111-1111-111111111111' $$,
  'new row violates row-level security policy for table "tenant_subscriptions"',
  'Normal tenant member cannot delete subscription'
);

-- 6. Test suspended tenant member access (Tenant 2)
select tests.authenticate_as('owner2@trace.test');

select results_eq(
  $$ select status from public.tenant_subscriptions where tenant_id = '22222222-2222-2222-2222-222222222222' $$,
  $$ values ('suspended'::text) $$,
  'Suspended tenant member can still read their own status'
);

-- 7. Test platform admin access
select tests.authenticate_as('admin@trace.test');

select results_eq(
  $$ select count(*)::int from public.tenant_subscriptions $$,
  $$ values (2::int) $$,
  'Platform admin can SELECT all subscriptions'
);

select lives_ok(
  $$ update public.tenant_subscriptions set status = 'overdue' where tenant_id = '11111111-1111-1111-1111-111111111111' $$,
  'Platform admin can UPDATE subscription status'
);

select throws_ok(
  $$ delete from public.tenant_subscriptions $$,
  'new row violates row-level security policy for table "tenant_subscriptions"',
  'No broad delete policy exists even for platform admins'
);

select * from finish();
rollback;
