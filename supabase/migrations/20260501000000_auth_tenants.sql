create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  owner_user_id uuid references auth.users(id) on delete set null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tenant_users (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (
    role in (
      'owner',
      'manager',
      'cashier',
      'stock_manager',
      'accountant',
      'read_only'
    )
  ),
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, user_id)
);

create index if not exists idx_tenant_users_user_id on public.tenant_users(user_id);
create index if not exists idx_tenant_users_tenant_id on public.tenant_users(tenant_id);

create or replace function public.is_tenant_member(target_tenant_id uuid)
returns boolean
language sql
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

create or replace function public.is_tenant_owner(target_tenant_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tenant_users tu
    where tu.tenant_id = target_tenant_id
      and tu.user_id = auth.uid()
      and tu.role = 'owner'
      and tu.status = 'active'
  );
$$;

alter table public.profiles enable row level security;
alter table public.tenants enable row level security;
alter table public.tenant_users enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "tenants_insert_owner" on public.tenants;
create policy "tenants_insert_owner"
on public.tenants
for insert
to authenticated
with check (owner_user_id = auth.uid());

drop policy if exists "tenants_select_members" on public.tenants;
create policy "tenants_select_members"
on public.tenants
for select
to authenticated
using (
  public.is_tenant_member(tenants.id)
  or tenants.owner_user_id = auth.uid()
);

drop policy if exists "tenants_update_owner" on public.tenants;
create policy "tenants_update_owner"
on public.tenants
for update
to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "tenant_users_insert_self_owner" on public.tenant_users;
create policy "tenant_users_insert_self_owner"
on public.tenant_users
for insert
to authenticated
with check (
  user_id = auth.uid()
  and role = 'owner'
  and exists (
    select 1
    from public.tenants t
    where t.id = tenant_users.tenant_id
      and t.owner_user_id = auth.uid()
  )
);

drop policy if exists "tenant_users_select_members" on public.tenant_users;
create policy "tenant_users_select_members"
on public.tenant_users
for select
to authenticated
using (
  public.is_tenant_member(tenant_users.tenant_id)
);

drop policy if exists "tenant_users_owner_manage" on public.tenant_users;
create policy "tenant_users_owner_manage"
on public.tenant_users
for all
to authenticated
using (
  public.is_tenant_owner(tenant_users.tenant_id)
)
with check (
  public.is_tenant_owner(tenant_users.tenant_id)
);
