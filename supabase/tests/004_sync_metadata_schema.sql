-- Phase 6.5 smoke test: sync metadata schema and RLS.
-- Run after migrations against a local/dev Supabase database:
-- psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/004_sync_metadata_schema.sql

begin;

set local statement_timeout = '10s';

do $$
declare
  v_table text;
  v_column text;
begin
  foreach v_table in array array[
    'companies',
    'warehouses',
    'categories',
    'products',
    'partners',
    'documents',
    'document_lines',
    'payments',
    'stock_movements',
    'audit_events',
    'settings',
    'files'
  ]
  loop
    foreach v_column in array array[
      'sync_origin_device_id',
      'sync_last_pushed_at',
      'sync_last_pulled_at',
      'local_updated_at'
    ]
    loop
      if not exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = v_table
          and column_name = v_column
      ) then
        raise exception 'missing sync metadata column %.%', v_table, v_column;
      end if;
    end loop;
  end loop;

  foreach v_table in array array[
    'sync_devices',
    'sync_errors',
    'sync_conflicts'
  ]
  loop
    if to_regclass('public.' || v_table) is null then
      raise exception 'missing sync support table %', v_table;
    end if;
  end loop;
end $$;

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
    '00000000-0000-0000-0000-0000000065d1',
    'authenticated',
    'authenticated',
    'sync-member@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-0000000065df',
    'authenticated',
    'authenticated',
    'sync-outsider@example.test',
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
  '10000000-0000-0000-0000-0000000065d1',
  'Tenant Sync Smoke',
  '00000000-0000-0000-0000-0000000065d1'
)
on conflict (id) do nothing;

insert into public.tenant_users (tenant_id, user_id, role, status)
values (
  '10000000-0000-0000-0000-0000000065d1',
  '00000000-0000-0000-0000-0000000065d1',
  'owner',
  'active'
)
on conflict (tenant_id, user_id) do update
set role = excluded.role, status = excluded.status;

insert into public.sync_conflicts (
  id,
  tenant_id,
  entity_type,
  entity_id,
  local_payload,
  remote_payload
)
values (
  '90000000-0000-0000-0000-0000000065d1',
  '10000000-0000-0000-0000-0000000065d1',
  'products',
  '40000000-0000-0000-0000-0000000065d1',
  '{"name":"local"}'::jsonb,
  '{"name":"remote"}'::jsonb
)
on conflict (id) do nothing;

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065d1',
  true
);

insert into public.sync_devices (
  tenant_id,
  user_id,
  device_id,
  platform,
  app_version,
  last_seen_at
)
values (
  '10000000-0000-0000-0000-0000000065d1',
  '00000000-0000-0000-0000-0000000065d1',
  'device-sync-smoke',
  'test',
  '0.0.0',
  now()
)
on conflict (tenant_id, user_id, device_id) do update
set last_seen_at = excluded.last_seen_at;

insert into public.sync_errors (
  tenant_id,
  user_id,
  device_id,
  entity_type,
  operation,
  error_code,
  error_message
)
values (
  '10000000-0000-0000-0000-0000000065d1',
  '00000000-0000-0000-0000-0000000065d1',
  'device-sync-smoke',
  'products',
  'push',
  'smoke',
  'Smoke test error'
);

do $$
begin
  if not exists (
    select 1
    from public.sync_devices
    where device_id = 'device-sync-smoke'
  ) then
    raise exception 'tenant member should see own sync device';
  end if;

  if not exists (
    select 1
    from public.sync_errors
    where error_code = 'smoke'
  ) then
    raise exception 'tenant member should see own sync error';
  end if;

  if not exists (
    select 1
    from public.sync_conflicts
    where id = '90000000-0000-0000-0000-0000000065d1'
  ) then
    raise exception 'tenant member should see tenant sync conflict';
  end if;
end $$;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065df',
  true
);

do $$
declare
  blocked boolean := false;
begin
  if exists (select 1 from public.sync_devices) then
    raise exception 'non-member should not see sync devices';
  end if;

  if exists (select 1 from public.sync_errors) then
    raise exception 'non-member should not see sync errors';
  end if;

  if exists (select 1 from public.sync_conflicts) then
    raise exception 'non-member should not see sync conflicts';
  end if;

  begin
    insert into public.sync_devices (
      tenant_id,
      user_id,
      device_id
    )
    values (
      '10000000-0000-0000-0000-0000000065d1',
      '00000000-0000-0000-0000-0000000065df',
      'blocked-device'
    );
  exception when others then
    blocked := true;
  end;

  if not blocked then
    raise exception 'non-member should not insert sync devices';
  end if;
end $$;

rollback;
