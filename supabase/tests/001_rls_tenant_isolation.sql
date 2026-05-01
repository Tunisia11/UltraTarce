-- Phase 6.5 smoke test: tenant isolation for business rows.
-- Run after migrations against a local/dev Supabase database:
-- psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/001_rls_tenant_isolation.sql

begin;

set local statement_timeout = '10s';

insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-0000000065a1',
    'authenticated',
    'authenticated',
    'tenant-a-user@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-0000000065b1',
    'authenticated',
    'authenticated',
    'tenant-b-user@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-0000000065f0',
    'authenticated',
    'authenticated',
    'tenant-outsider@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  )
on conflict (id) do nothing;

insert into public.tenants (id, name, owner_user_id)
values
  (
    '10000000-0000-0000-0000-0000000065a1',
    'Tenant A RLS Smoke',
    '00000000-0000-0000-0000-0000000065a1'
  ),
  (
    '10000000-0000-0000-0000-0000000065b1',
    'Tenant B RLS Smoke',
    '00000000-0000-0000-0000-0000000065b1'
  )
on conflict (id) do nothing;

insert into public.tenant_users (tenant_id, user_id, role, status)
values
  (
    '10000000-0000-0000-0000-0000000065a1',
    '00000000-0000-0000-0000-0000000065a1',
    'owner',
    'active'
  ),
  (
    '10000000-0000-0000-0000-0000000065b1',
    '00000000-0000-0000-0000-0000000065b1',
    'owner',
    'active'
  )
on conflict (tenant_id, user_id) do update
set role = excluded.role, status = excluded.status;

insert into public.companies (id, tenant_id, name, created_by)
values
  (
    '20000000-0000-0000-0000-0000000065a1',
    '10000000-0000-0000-0000-0000000065a1',
    'Societe A',
    '00000000-0000-0000-0000-0000000065a1'
  ),
  (
    '20000000-0000-0000-0000-0000000065b1',
    '10000000-0000-0000-0000-0000000065b1',
    'Societe B',
    '00000000-0000-0000-0000-0000000065b1'
  )
on conflict (id) do nothing;

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065a1',
  true
);

do $$
begin
  if (select count(*) from public.companies) <> 1 then
    raise exception 'tenant A user should see exactly one company row';
  end if;

  if not exists (
    select 1
    from public.companies
    where tenant_id = '10000000-0000-0000-0000-0000000065a1'
  ) then
    raise exception 'tenant A user cannot see own tenant company';
  end if;

  if exists (
    select 1
    from public.companies
    where tenant_id = '10000000-0000-0000-0000-0000000065b1'
  ) then
    raise exception 'tenant A user can see tenant B company';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065b1',
  true
);

do $$
begin
  if (select count(*) from public.companies) <> 1 then
    raise exception 'tenant B user should see exactly one company row';
  end if;

  if not exists (
    select 1
    from public.companies
    where tenant_id = '10000000-0000-0000-0000-0000000065b1'
  ) then
    raise exception 'tenant B user cannot see own tenant company';
  end if;

  if exists (
    select 1
    from public.companies
    where tenant_id = '10000000-0000-0000-0000-0000000065a1'
  ) then
    raise exception 'tenant B user can see tenant A company';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065f0',
  true
);

do $$
begin
  if (select count(*) from public.companies) <> 0 then
    raise exception 'non-member user should not see tenant company rows';
  end if;
end $$;

rollback;
