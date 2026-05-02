BEGIN;

select plan(7);

-- Create mock users
select tests.create_supabase_user('normal_user');
select tests.create_supabase_user('admin_user');
select tests.create_supabase_user('another_user');

-- Insert a tenant and business data for normal_user
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "normal_user", "role": "authenticated"}';

insert into public.tenants (id, name, created_by) values ('00000000-0000-0000-0000-000000000001', 'Tenant 1', 'normal_user');
insert into public.tenant_users (tenant_id, user_id, role) values ('00000000-0000-0000-0000-000000000001', 'normal_user', 'owner');
insert into public.products (id, tenant_id, code, name) values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'P1', 'Product 1');

-- Insert another tenant for another_user
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "another_user", "role": "authenticated"}';
insert into public.tenants (id, name, created_by) values ('00000000-0000-0000-0000-000000000002', 'Tenant 2', 'another_user');
insert into public.tenant_users (tenant_id, user_id, role) values ('00000000-0000-0000-0000-000000000002', 'another_user', 'owner');
insert into public.products (id, tenant_id, code, name) values ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'P2', 'Product 2');

-- Test 1: normal tenant user cannot read another tenant data
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "normal_user", "role": "authenticated"}';
select is(
  (select count(*) from public.tenants),
  1::bigint,
  'normal_user should only see 1 tenant'
);

select is(
  (select count(*) from public.products),
  1::bigint,
  'normal_user should only see their own products'
);

-- Set admin_user as platform admin
set local role postgres;
insert into public.platform_admins (user_id, email, role, status) values ('admin_user', 'admin@virex.com', 'owner', 'active');

-- Test 2: platform admin can read all tenants and products
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "admin_user", "role": "authenticated"}';

select is(
  (select count(*) from public.tenants),
  2::bigint,
  'admin_user should see 2 tenants'
);

select is(
  (select count(*) from public.products),
  2::bigint,
  'admin_user should see all products'
);

-- Test 3: platform admin cannot delete business rows through client policies
prepare delete_product as delete from public.products where id = '10000000-0000-0000-0000-000000000001';
select throws_ok(
  'delete_product',
  '42501',
  NULL,
  'admin_user cannot delete products'
);

-- Test 4: Check profiles.email exists
select is(
  (
    select count(*)
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'email'
  )::int,
  1,
  'profiles.email column exists'
);

-- Test 5: platform admin can read profiles
select is(
  (select count(*) from public.profiles),
  3::bigint,
  'admin_user can read profiles'
);

select * from finish();
ROLLBACK;
