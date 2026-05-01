create or replace function public.is_tenant_member(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tenant_users tu
    where tu.tenant_id = target_tenant_id
      and tu.user_id = auth.uid()
      and tu.status = 'active'
  );
$$;

create or replace function public.current_tenant_role(target_tenant_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select tu.role
  from public.tenant_users tu
  where tu.tenant_id = target_tenant_id
    and tu.user_id = auth.uid()
    and tu.status = 'active'
  limit 1;
$$;

create or replace function public.is_tenant_owner_or_manager(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_tenant_role(target_tenant_id) in ('owner', 'manager'), false);
$$;

create or replace function public.is_tenant_owner(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_tenant_role(target_tenant_id) = 'owner', false);
$$;

create or replace function public.can_insert_business_row(
  target_tenant_id uuid,
  p_table_name text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case public.current_tenant_role(target_tenant_id)
    when 'owner' then true
    when 'manager' then true
    when 'cashier' then p_table_name in (
      'documents',
      'document_lines',
      'payments',
      'stock_movements',
      'audit_events',
      'files'
    )
    when 'stock_manager' then p_table_name in (
      'warehouses',
      'categories',
      'products',
      'stock_movements',
      'audit_events',
      'files'
    )
    when 'accountant' then p_table_name in (
      'documents',
      'document_lines',
      'payments',
      'audit_events',
      'files'
    )
    else false
  end;
$$;

create or replace function public.can_update_business_row(
  target_tenant_id uuid,
  p_table_name text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case public.current_tenant_role(target_tenant_id)
    when 'owner' then true
    when 'manager' then true
    when 'cashier' then p_table_name in ('documents', 'payments', 'audit_events')
    when 'stock_manager' then p_table_name in (
      'warehouses',
      'categories',
      'products',
      'stock_movements',
      'audit_events',
      'files'
    )
    when 'accountant' then p_table_name in (
      'documents',
      'payments',
      'audit_events',
      'files'
    )
    else false
  end;
$$;

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
    execute format('alter table public.%I enable row level security', table_name);

    execute format(
      'drop policy if exists %I on public.%I',
      table_name || '_select_tenant_member',
      table_name
    );
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.is_tenant_member(tenant_id))',
      table_name || '_select_tenant_member',
      table_name
    );

    execute format(
      'drop policy if exists %I on public.%I',
      table_name || '_insert_tenant_writer',
      table_name
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (public.can_insert_business_row(tenant_id, %L) and (created_by is null or created_by = auth.uid()))',
      table_name || '_insert_tenant_writer',
      table_name,
      table_name
    );

    execute format(
      'drop policy if exists %I on public.%I',
      table_name || '_update_tenant_writer',
      table_name
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (public.can_update_business_row(tenant_id, %L)) with check (public.can_update_business_row(tenant_id, %L) and (updated_by is null or updated_by = auth.uid()))',
      table_name || '_update_tenant_writer',
      table_name,
      table_name,
      table_name
    );
  end loop;
end $$;

comment on policy documents_update_tenant_writer on public.documents is
  'Finalized invoice lifecycle safety stays in app/domain services for now. This policy only gates tenant role access.';

comment on policy documents_insert_tenant_writer on public.documents is
  'Cashiers and accountants may create document rows for their active tenant. Remote sync conflict rules come later.';

comment on policy stock_movements_insert_tenant_writer on public.stock_movements is
  'Stock movements are append-style from the client; hard deletes are intentionally not exposed.';
