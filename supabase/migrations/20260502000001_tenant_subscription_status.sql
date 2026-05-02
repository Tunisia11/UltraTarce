create table if not exists public.tenant_subscriptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade unique,
  plan text not null default 'pilot' check (plan in ('pilot', 'basic', 'pro', 'enterprise')),
  status text not null default 'trial' check (status in ('trial', 'active', 'overdue', 'suspended', 'cancelled')),
  billing_cycle text not null default 'monthly' check (billing_cycle in ('monthly', 'yearly', 'custom')),
  price_tnd numeric(12,3) check (price_tnd is null or price_tnd >= 0),
  seats_limit integer check (seats_limit is null or seats_limit > 0),
  trial_started_at timestamptz,
  trial_ends_at timestamptz,
  current_period_started_at timestamptz,
  current_period_ends_at timestamptz,
  suspended_at timestamptz,
  cancelled_at timestamptz,
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger update_tenant_subscriptions_updated_at
  before update on public.tenant_subscriptions
  for each row execute function public.update_updated_at_column();

alter table public.tenant_subscriptions enable row level security;

drop policy if exists "platform_admins_select_subscriptions" on public.tenant_subscriptions;
create policy "platform_admins_select_subscriptions"
on public.tenant_subscriptions
for select
to authenticated
using (public.is_platform_admin());

drop policy if exists "platform_admins_insert_subscriptions" on public.tenant_subscriptions;
create policy "platform_admins_insert_subscriptions"
on public.tenant_subscriptions
for insert
to authenticated
with check (public.is_platform_admin());

drop policy if exists "platform_admins_update_subscriptions" on public.tenant_subscriptions;
create policy "platform_admins_update_subscriptions"
on public.tenant_subscriptions
for update
to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists "tenant_members_select_own_subscription" on public.tenant_subscriptions;
create policy "tenant_members_select_own_subscription"
on public.tenant_subscriptions
for select
to authenticated
using (public.is_tenant_member(tenant_id) or public.is_tenant_owner(tenant_id));

-- Backfill existing tenants
insert into public.tenant_subscriptions (
  tenant_id, 
  plan, 
  status, 
  billing_cycle, 
  trial_started_at, 
  trial_ends_at,
  current_period_started_at
)
select 
  id, 
  'pilot', 
  'active', 
  'monthly', 
  created_at, 
  created_at + interval '14 days',
  created_at
from public.tenants
on conflict (tenant_id) do nothing;
