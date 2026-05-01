-- Phase 6.5 smoke test: role-based business permissions.
-- Run after migrations against a local/dev Supabase database:
-- psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/002_role_permissions.sql

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
    '00000000-0000-0000-0000-000000006501',
    'authenticated',
    'authenticated',
    'owner@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000006502',
    'authenticated',
    'authenticated',
    'manager@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000006503',
    'authenticated',
    'authenticated',
    'cashier@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000006504',
    'authenticated',
    'authenticated',
    'stock@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000006505',
    'authenticated',
    'authenticated',
    'accountant@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000006506',
    'authenticated',
    'authenticated',
    'readonly@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-0000000065ff',
    'authenticated',
    'authenticated',
    'nonmember@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  )
on conflict (id) do nothing;

insert into public.tenants (id, name, owner_user_id)
values (
  '10000000-0000-0000-0000-000000006501',
  'Tenant Role Smoke',
  '00000000-0000-0000-0000-000000006501'
)
on conflict (id) do nothing;

insert into public.tenant_users (tenant_id, user_id, role, status)
values
  (
    '10000000-0000-0000-0000-000000006501',
    '00000000-0000-0000-0000-000000006501',
    'owner',
    'active'
  ),
  (
    '10000000-0000-0000-0000-000000006501',
    '00000000-0000-0000-0000-000000006502',
    'manager',
    'active'
  ),
  (
    '10000000-0000-0000-0000-000000006501',
    '00000000-0000-0000-0000-000000006503',
    'cashier',
    'active'
  ),
  (
    '10000000-0000-0000-0000-000000006501',
    '00000000-0000-0000-0000-000000006504',
    'stock_manager',
    'active'
  ),
  (
    '10000000-0000-0000-0000-000000006501',
    '00000000-0000-0000-0000-000000006505',
    'accountant',
    'active'
  ),
  (
    '10000000-0000-0000-0000-000000006501',
    '00000000-0000-0000-0000-000000006506',
    'read_only',
    'active'
  )
on conflict (tenant_id, user_id) do update
set role = excluded.role, status = excluded.status;

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006501',
  true
);

insert into public.warehouses (id, tenant_id, name, created_by)
values (
  '30000000-0000-0000-0000-000000006501',
  '10000000-0000-0000-0000-000000006501',
  'Depot principal',
  '00000000-0000-0000-0000-000000006501'
);

insert into public.products (
  id,
  tenant_id,
  name,
  sku,
  sale_price_ht,
  created_by
)
values (
  '40000000-0000-0000-0000-000000006501',
  '10000000-0000-0000-0000-000000006501',
  'Produit role smoke',
  'ROLE-SMOKE',
  12.500,
  '00000000-0000-0000-0000-000000006501'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006502',
  true
);

update public.products
set description = 'updated by manager',
    updated_by = '00000000-0000-0000-0000-000000006502'
where id = '40000000-0000-0000-0000-000000006501';

do $$
begin
  if not exists (
    select 1
    from public.products
    where id = '40000000-0000-0000-0000-000000006501'
      and description = 'updated by manager'
  ) then
    raise exception 'manager update should be allowed';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006503',
  true
);

insert into public.documents (
  id,
  tenant_id,
  type,
  status,
  number,
  total_ttc,
  remaining_amount,
  created_by
)
values (
  '50000000-0000-0000-0000-000000006503',
  '10000000-0000-0000-0000-000000006501',
  'Facture',
  'Brouillon',
  'FAC-ROLE-001',
  25.000,
  25.000,
  '00000000-0000-0000-0000-000000006503'
);

insert into public.payments (
  id,
  tenant_id,
  document_id,
  amount,
  method,
  created_by
)
values (
  '60000000-0000-0000-0000-000000006503',
  '10000000-0000-0000-0000-000000006501',
  '50000000-0000-0000-0000-000000006503',
  5.000,
  'Espèces',
  '00000000-0000-0000-0000-000000006503'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006504',
  true
);

insert into public.stock_movements (
  id,
  tenant_id,
  product_id,
  warehouse_id,
  quantity_delta,
  type,
  reason,
  created_by
)
values (
  '70000000-0000-0000-0000-000000006504',
  '10000000-0000-0000-0000-000000006501',
  '40000000-0000-0000-0000-000000006501',
  '30000000-0000-0000-0000-000000006501',
  3.000,
  'adjustment',
  'Smoke test',
  '00000000-0000-0000-0000-000000006504'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006505',
  true
);

update public.payments
set note = 'updated by accountant',
    updated_by = '00000000-0000-0000-0000-000000006505'
where id = '60000000-0000-0000-0000-000000006503';

do $$
begin
  if not exists (
    select 1
    from public.payments
    where id = '60000000-0000-0000-0000-000000006503'
      and note = 'updated by accountant'
  ) then
    raise exception 'accountant payment update should be allowed';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006506',
  true
);

do $$
declare
  blocked boolean := false;
begin
  if not exists (
    select 1
    from public.products
    where id = '40000000-0000-0000-0000-000000006501'
  ) then
    raise exception 'read_only member should be able to select tenant rows';
  end if;

  begin
    insert into public.products (tenant_id, name, created_by)
    values (
      '10000000-0000-0000-0000-000000006501',
      'Produit interdit',
      '00000000-0000-0000-0000-000000006506'
    );
  exception when others then
    blocked := true;
  end;

  if not blocked then
    raise exception 'read_only member should not be able to insert products';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065ff',
  true
);

do $$
declare
  blocked boolean := false;
begin
  if exists (select 1 from public.products) then
    raise exception 'non-member should not be able to select tenant products';
  end if;

  begin
    insert into public.products (tenant_id, name, created_by)
    values (
      '10000000-0000-0000-0000-000000006501',
      'Produit non-membre',
      '00000000-0000-0000-0000-0000000065ff'
    );
  exception when others then
    blocked := true;
  end;

  if not blocked then
    raise exception 'non-member should not be able to insert products';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000006501',
  true
);

do $$
begin
  begin
    delete from public.products
    where id = '40000000-0000-0000-0000-000000006501';
  exception when others then
    null;
  end;

  if not exists (
    select 1
    from public.products
    where id = '40000000-0000-0000-0000-000000006501'
  ) then
    raise exception 'owner hard delete should be blocked by missing delete policy';
  end if;
end $$;

update public.products
set deleted_at = now(),
    updated_by = '00000000-0000-0000-0000-000000006501'
where id = '40000000-0000-0000-0000-000000006501';

do $$
begin
  if not exists (
    select 1
    from public.products
    where id = '40000000-0000-0000-0000-000000006501'
      and deleted_at is not null
  ) then
    raise exception 'owner soft delete should be allowed through update';
  end if;
end $$;

rollback;
