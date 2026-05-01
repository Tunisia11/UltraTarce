do $$
declare
  table_name text;
begin
  foreach table_name in array array[
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
    execute format('alter table public.%I add column if not exists sync_origin_device_id text', table_name);
    execute format('alter table public.%I add column if not exists sync_last_pushed_at timestamptz', table_name);
    execute format('alter table public.%I add column if not exists sync_last_pulled_at timestamptz', table_name);
    execute format('alter table public.%I add column if not exists local_updated_at timestamptz', table_name);
    execute format('create index if not exists %I on public.%I (tenant_id, sync_origin_device_id)', 'idx_' || table_name || '_tenant_sync_device', table_name);
  end loop;
end $$;

create table if not exists public.sync_devices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  platform text,
  app_version text,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  unique (tenant_id, user_id, device_id)
);

create table if not exists public.sync_errors (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  device_id text,
  entity_type text,
  entity_id uuid,
  operation text,
  error_code text,
  error_message text not null,
  payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  version bigint not null default 1
);

create table if not exists public.sync_conflicts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  local_payload jsonb,
  remote_payload jsonb,
  resolution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete set null,
  version bigint not null default 1
);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'sync_devices',
    'sync_errors',
    'sync_conflicts'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('create index if not exists %I on public.%I (tenant_id)', 'idx_' || table_name || '_tenant_id', table_name);
    execute format('create index if not exists %I on public.%I (tenant_id, updated_at)', 'idx_' || table_name || '_tenant_updated_at', table_name);
    execute format('drop trigger if exists trg_%I_touch_updated_at on public.%I', table_name, table_name);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.touch_updated_at()',
      'trg_' || table_name || '_touch_updated_at',
      table_name
    );
    execute format('drop trigger if exists trg_%I_increment_version on public.%I', table_name, table_name);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.increment_version()',
      'trg_' || table_name || '_increment_version',
      table_name
    );
  end loop;
end $$;

create index if not exists idx_sync_devices_tenant_user_device
  on public.sync_devices (tenant_id, user_id, device_id);
create index if not exists idx_sync_errors_tenant_created_at
  on public.sync_errors (tenant_id, created_at desc);
create index if not exists idx_sync_conflicts_tenant_entity
  on public.sync_conflicts (tenant_id, entity_type, entity_id);

drop policy if exists sync_devices_select_member on public.sync_devices;
create policy sync_devices_select_member
on public.sync_devices
for select
to authenticated
using (public.is_tenant_member(tenant_id));

drop policy if exists sync_devices_insert_self on public.sync_devices;
create policy sync_devices_insert_self
on public.sync_devices
for insert
to authenticated
with check (
  public.is_tenant_member(tenant_id)
  and user_id = auth.uid()
);

drop policy if exists sync_devices_update_self on public.sync_devices;
create policy sync_devices_update_self
on public.sync_devices
for update
to authenticated
using (
  public.is_tenant_member(tenant_id)
  and user_id = auth.uid()
)
with check (
  public.is_tenant_member(tenant_id)
  and user_id = auth.uid()
);

drop policy if exists sync_errors_select_member on public.sync_errors;
create policy sync_errors_select_member
on public.sync_errors
for select
to authenticated
using (public.is_tenant_member(tenant_id));

drop policy if exists sync_errors_insert_member on public.sync_errors;
create policy sync_errors_insert_member
on public.sync_errors
for insert
to authenticated
with check (
  public.is_tenant_member(tenant_id)
  and (user_id is null or user_id = auth.uid())
);

drop policy if exists sync_errors_update_owner_manager on public.sync_errors;
create policy sync_errors_update_owner_manager
on public.sync_errors
for update
to authenticated
using (public.is_tenant_owner_or_manager(tenant_id) or user_id = auth.uid())
with check (public.is_tenant_owner_or_manager(tenant_id) or user_id = auth.uid());

drop policy if exists sync_conflicts_select_member on public.sync_conflicts;
create policy sync_conflicts_select_member
on public.sync_conflicts
for select
to authenticated
using (public.is_tenant_member(tenant_id));

drop policy if exists sync_conflicts_insert_writer on public.sync_conflicts;
create policy sync_conflicts_insert_writer
on public.sync_conflicts
for insert
to authenticated
with check (
  public.current_tenant_role(tenant_id) in ('owner', 'manager', 'cashier', 'stock_manager', 'accountant')
);

drop policy if exists sync_conflicts_update_resolver on public.sync_conflicts;
create policy sync_conflicts_update_resolver
on public.sync_conflicts
for update
to authenticated
using (
  public.current_tenant_role(tenant_id) in ('owner', 'manager', 'accountant')
)
with check (
  public.current_tenant_role(tenant_id) in ('owner', 'manager', 'accountant')
  and (resolved_by is null or resolved_by = auth.uid())
);
