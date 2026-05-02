-- Phase 8C: Tenant team management and invitations
-- =================================================

-- A. Add 'status' check constraint for tenant_users if not yet applied.
-- The original migration has a role check but no status constraint.
alter table public.tenant_users
  drop constraint if exists tenant_users_status_check;

alter table public.tenant_users
  add constraint tenant_users_status_check
  check (status in ('active', 'invited', 'disabled'));

-- B. Helper function: can_manage_tenant_users
create or replace function public.can_manage_tenant_users(target_tenant_id uuid)
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
  ) or public.is_platform_admin();
$$;

-- C. Create tenant_invites table
create table if not exists public.tenant_invites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  email text not null,
  role text not null default 'cashier'
    check (role in ('owner', 'manager', 'cashier', 'stock_manager', 'accountant', 'read_only')),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'cancelled', 'expired')),
  invited_by uuid references auth.users(id),
  accepted_by uuid references auth.users(id),
  invite_token uuid not null default gen_random_uuid(),
  expires_at timestamptz,
  accepted_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Unique active invite per tenant/email
create unique index if not exists idx_tenant_invites_pending
  on public.tenant_invites(tenant_id, lower(email))
  where status = 'pending';

create index if not exists idx_tenant_invites_token
  on public.tenant_invites(invite_token);

create index if not exists idx_tenant_invites_email
  on public.tenant_invites(lower(email));

-- Auto-update trigger
create trigger update_tenant_invites_updated_at
  before update on public.tenant_invites
  for each row execute function public.update_updated_at_column();

-- D. RLS for tenant_invites
alter table public.tenant_invites enable row level security;

-- Platform admin SELECT all
drop policy if exists "platform_admins_select_invites" on public.tenant_invites;
create policy "platform_admins_select_invites"
on public.tenant_invites
for select
to authenticated
using (public.is_platform_admin());

-- Tenant owner/manager can SELECT own tenant invites
drop policy if exists "tenant_owners_select_invites" on public.tenant_invites;
create policy "tenant_owners_select_invites"
on public.tenant_invites
for select
to authenticated
using (
  public.is_tenant_member(tenant_invites.tenant_id)
);

-- Invited user can SELECT own pending invites by email
drop policy if exists "invited_user_select_own" on public.tenant_invites;
create policy "invited_user_select_own"
on public.tenant_invites
for select
to authenticated
using (
  lower(email) = lower(auth.jwt()->>'email')
  and status = 'pending'
);

-- Owner INSERT invites
drop policy if exists "owner_insert_invites" on public.tenant_invites;
create policy "owner_insert_invites"
on public.tenant_invites
for insert
to authenticated
with check (
  public.is_tenant_owner(tenant_invites.tenant_id)
  and invited_by = auth.uid()
);

-- Owner UPDATE/cancel invites
drop policy if exists "owner_update_invites" on public.tenant_invites;
create policy "owner_update_invites"
on public.tenant_invites
for update
to authenticated
using (
  public.is_tenant_owner(tenant_invites.tenant_id)
);

-- E. Updated RLS for tenant_users
-- Allow platform admins to select all tenant_users
drop policy if exists "platform_admins_select_tenant_users" on public.tenant_users;
create policy "platform_admins_select_tenant_users"
on public.tenant_users
for select
to authenticated
using (public.is_platform_admin());

-- Users can select their own memberships (regardless of tenant membership)
drop policy if exists "users_select_own_memberships" on public.tenant_users;
create policy "users_select_own_memberships"
on public.tenant_users
for select
to authenticated
using (user_id = auth.uid());

-- F. SECURITY DEFINER function: accept_tenant_invite
create or replace function public.accept_tenant_invite(p_invite_token uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite record;
  v_user_id uuid;
  v_user_email text;
  v_tenant_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Non authentifié';
  end if;

  v_user_email := lower(auth.jwt()->>'email');

  -- Find the invite
  select * into v_invite
  from public.tenant_invites
  where invite_token = p_invite_token;

  if not found then
    raise exception 'Invitation introuvable';
  end if;

  if v_invite.status != 'pending' then
    raise exception 'Invitation déjà traitée (statut: %)', v_invite.status;
  end if;

  if lower(v_invite.email) != v_user_email then
    raise exception 'Email ne correspond pas à l''invitation';
  end if;

  if v_invite.expires_at is not null and v_invite.expires_at < now() then
    -- Mark as expired
    update public.tenant_invites
    set status = 'expired', updated_at = now()
    where id = v_invite.id;
    raise exception 'Invitation expirée';
  end if;

  v_tenant_id := v_invite.tenant_id;

  -- Insert or update tenant_users
  insert into public.tenant_users (tenant_id, user_id, role, status)
  values (v_tenant_id, v_user_id, v_invite.role, 'active')
  on conflict (tenant_id, user_id)
  do update set role = excluded.role, status = 'active', updated_at = now();

  -- Mark invite as accepted
  update public.tenant_invites
  set status = 'accepted',
      accepted_by = v_user_id,
      accepted_at = now(),
      updated_at = now()
  where id = v_invite.id;

  -- Create profile if not exists
  insert into public.profiles (id)
  values (v_user_id)
  on conflict (id) do nothing;

  return v_tenant_id;
end;
$$;
