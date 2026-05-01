-- Phase 6.5 smoke test: file metadata RLS and storage policy installation.
-- Run after migrations against a local/dev Supabase database:
-- psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/003_storage_policies.sql

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
    '00000000-0000-0000-0000-0000000065c1',
    'authenticated',
    'authenticated',
    'storage-a@example.test',
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-0000000065c2',
    'authenticated',
    'authenticated',
    'storage-b@example.test',
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
    '10000000-0000-0000-0000-0000000065c1',
    'Tenant Storage A',
    '00000000-0000-0000-0000-0000000065c1'
  ),
  (
    '10000000-0000-0000-0000-0000000065c2',
    'Tenant Storage B',
    '00000000-0000-0000-0000-0000000065c2'
  )
on conflict (id) do nothing;

insert into public.tenant_users (tenant_id, user_id, role, status)
values
  (
    '10000000-0000-0000-0000-0000000065c1',
    '00000000-0000-0000-0000-0000000065c1',
    'owner',
    'active'
  ),
  (
    '10000000-0000-0000-0000-0000000065c2',
    '00000000-0000-0000-0000-0000000065c2',
    'owner',
    'active'
  )
on conflict (tenant_id, user_id) do update
set role = excluded.role, status = excluded.status;

insert into public.files (
  id,
  tenant_id,
  bucket,
  path,
  type,
  created_by
)
values (
  '80000000-0000-0000-0000-0000000065c2',
  '10000000-0000-0000-0000-0000000065c2',
  'tenant-logos',
  '10000000-0000-0000-0000-0000000065c2/logos/logo.png',
  'logo',
  '00000000-0000-0000-0000-0000000065c2'
)
on conflict (id) do nothing;

do $$
begin
  if to_regclass('storage.objects') is not null then
    insert into storage.objects (
      bucket_id,
      name,
      owner,
      metadata
    )
    values (
      'tenant-logos',
      '10000000-0000-0000-0000-0000000065c2/logos/object.png',
      '00000000-0000-0000-0000-0000000065c2',
      '{}'::jsonb
    );
  end if;
end $$;

do $$
begin
  if public.tenant_id_from_storage_path(
    '10000000-0000-0000-0000-0000000065c1/logos/logo.png'
  ) <> '10000000-0000-0000-0000-0000000065c1'::uuid then
    raise exception 'storage path helper should extract tenant uuid prefix';
  end if;

  if public.tenant_id_from_storage_path('not-a-uuid/logos/logo.png') is not null then
    raise exception 'storage path helper should reject non-uuid prefixes';
  end if;
end $$;

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000065c1',
  true
);

insert into public.files (
  id,
  tenant_id,
  bucket,
  path,
  type,
  created_by
)
values (
  '80000000-0000-0000-0000-0000000065c1',
  '10000000-0000-0000-0000-0000000065c1',
  'tenant-logos',
  '10000000-0000-0000-0000-0000000065c1/logos/logo.png',
  'logo',
  '00000000-0000-0000-0000-0000000065c1'
);

do $$
declare
  blocked boolean := false;
begin
  if not exists (
    select 1
    from public.files
    where id = '80000000-0000-0000-0000-0000000065c1'
  ) then
    raise exception 'tenant A should read its own file metadata';
  end if;

  if exists (
    select 1
    from public.files
    where id = '80000000-0000-0000-0000-0000000065c2'
  ) then
    raise exception 'tenant A should not read tenant B file metadata';
  end if;

  begin
    insert into public.files (
      tenant_id,
      bucket,
      path,
      type,
      created_by
    )
    values (
      '10000000-0000-0000-0000-0000000065c2',
      'tenant-logos',
      '10000000-0000-0000-0000-0000000065c2/logos/blocked.png',
      'logo',
      '00000000-0000-0000-0000-0000000065c1'
    );
  exception when others then
    blocked := true;
  end;

  if not blocked then
    raise exception 'tenant A should not insert tenant B file metadata';
  end if;
end $$;

do $$
begin
  if to_regclass('storage.objects') is not null then
    if not exists (
      select 1
      from pg_policies
      where schemaname = 'storage'
        and tablename = 'objects'
        and policyname = 'tenant_storage_select_member'
    ) then
      raise exception 'storage select policy is not installed';
    end if;

    if not exists (
      select 1
      from pg_policies
      where schemaname = 'storage'
        and tablename = 'objects'
        and policyname = 'tenant_storage_insert_writer'
    ) then
      raise exception 'storage insert policy is not installed';
    end if;

    if not exists (
      select 1
      from pg_policies
      where schemaname = 'storage'
        and tablename = 'objects'
        and policyname = 'tenant_storage_update_writer'
    ) then
      raise exception 'storage update policy is not installed';
    end if;
  end if;
end $$;

do $$
declare
  blocked boolean := false;
begin
  if to_regclass('storage.objects') is null then
    return;
  end if;

  insert into storage.objects (
    bucket_id,
    name,
    owner,
    metadata
  )
  values (
    'tenant-logos',
    '10000000-0000-0000-0000-0000000065c1/logos/object.png',
    '00000000-0000-0000-0000-0000000065c1',
    '{}'::jsonb
  );

  if not exists (
    select 1
    from storage.objects
    where bucket_id = 'tenant-logos'
      and name = '10000000-0000-0000-0000-0000000065c1/logos/object.png'
  ) then
    raise exception 'tenant A should read its own storage object row';
  end if;

  if exists (
    select 1
    from storage.objects
    where bucket_id = 'tenant-logos'
      and name = '10000000-0000-0000-0000-0000000065c2/logos/object.png'
  ) then
    raise exception 'tenant A should not read tenant B storage object row';
  end if;

  begin
    insert into storage.objects (
      bucket_id,
      name,
      owner,
      metadata
    )
    values (
      'tenant-logos',
      '10000000-0000-0000-0000-0000000065c2/logos/blocked-object.png',
      '00000000-0000-0000-0000-0000000065c1',
      '{}'::jsonb
    );
  exception when others then
    blocked := true;
  end;

  if not blocked then
    raise exception 'tenant A should not insert a storage object under tenant B path';
  end if;
end $$;

rollback;
