begin;
select plan(9);

-- 1. Create users
select * from tests.create_supabase_user('team-owner@trace.test');
select * from tests.create_supabase_user('team-member@trace.test');
select * from tests.create_supabase_user('team-outsider@trace.test');
select * from tests.create_supabase_user('admin@trace.test');

-- 2. Set up platform admin
insert into public.platform_admins (user_id)
select id from auth.users where email = 'admin@trace.test';

-- 3. Create tenant as owner
select tests.authenticate_as('team-owner@trace.test');
insert into public.tenants (id, name, status, owner_user_id)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Team Test Co', 'active',
  (select id from auth.users where email = 'team-owner@trace.test'));

insert into public.tenant_users (tenant_id, user_id, role, status)
select 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', id, 'owner', 'active'
from auth.users where email = 'team-owner@trace.test';

-- 4. Test: Owner can insert invite
select lives_ok(
  $$ insert into public.tenant_invites (tenant_id, email, role, invited_by)
     select 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'team-member@trace.test', 'cashier',
       id from auth.users where email = 'team-owner@trace.test' $$,
  'Owner can insert an invite'
);

-- 5. Test: Non-owner cannot insert invite
select tests.authenticate_as('team-member@trace.test');
select throws_ok(
  $$ insert into public.tenant_invites (tenant_id, email, role, invited_by)
     select 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'team-outsider@trace.test', 'cashier',
       id from auth.users where email = 'team-member@trace.test' $$,
  'new row violates row-level security policy for table "tenant_invites"',
  'Non-owner cannot insert invite'
);

-- 6. Test: Invited email can select own pending invite
select tests.authenticate_as('team-member@trace.test');
select results_eq(
  $$ select email from public.tenant_invites where status = 'pending' $$,
  $$ values ('team-member@trace.test'::text) $$,
  'Invited email can see their own pending invite'
);

-- 7. Test: Wrong email cannot see the invite
select tests.authenticate_as('team-outsider@trace.test');
select is_empty(
  $$ select * from public.tenant_invites $$,
  'Outsider cannot see any invites'
);

-- 8. Test: Accept invite function works
select tests.authenticate_as('team-member@trace.test');
select lives_ok(
  format($$ select public.accept_tenant_invite('%s'::uuid) $$,
    (select invite_token from public.tenant_invites limit 1)),
  'Accept invite function creates membership'
);

-- 9. Verify tenant_users row was created
select results_eq(
  $$ select role from public.tenant_users where user_id = (select id from auth.users where email = 'team-member@trace.test') and tenant_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
  $$ values ('cashier'::text) $$,
  'Accepted invite created tenant_users with correct role'
);

-- 10. Test: Owner can update member role
select tests.authenticate_as('team-owner@trace.test');
select lives_ok(
  $$ update public.tenant_users set role = 'read_only' where user_id = (select id from auth.users where email = 'team-member@trace.test') and tenant_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
  'Owner can update member role'
);

-- 11. Test: Cashier cannot update tenant_users
select tests.authenticate_as('team-member@trace.test');
select throws_ok(
  $$ update public.tenant_users set role = 'manager' where user_id = (select id from auth.users where email = 'team-member@trace.test') $$,
  'new row violates row-level security policy for table "tenant_users"',
  'Cashier cannot update tenant_users'
);

-- 12. Test: Platform admin can read team data
select tests.authenticate_as('admin@trace.test');
select results_eq(
  $$ select count(*)::int from public.tenant_invites $$,
  $$ values (1::int) $$,
  'Platform admin can read all invites'
);

select * from finish();
rollback;
