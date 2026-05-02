-- Create platform admins table
CREATE TABLE public.platform_admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  email text,
  role text not null default 'owner' check (role in ('owner', 'support', 'readonly')),
  status text not null default 'active' check (status in ('active', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
ALTER TABLE public.platform_admins ENABLE ROW LEVEL SECURITY;

-- Helper function
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT exists (
    SELECT 1
    FROM public.platform_admins
    WHERE user_id = auth.uid()
      AND status = 'active'
  );
$$;

-- Admin policies for platform_admins
CREATE POLICY "platform_admins_select_self_or_admin"
  ON public.platform_admins FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR public.is_platform_admin()
  );

CREATE POLICY "platform_admins_no_client_insert"
  ON public.platform_admins FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_platform_admin() AND (SELECT role FROM public.platform_admins WHERE user_id = auth.uid()) = 'owner'
  );

CREATE POLICY "platform_admins_update_owner_only"
  ON public.platform_admins FOR UPDATE
  TO authenticated
  USING (
    public.is_platform_admin() AND (SELECT role FROM public.platform_admins WHERE user_id = auth.uid()) = 'owner'
  );

-- B. Add admin read policies for business tables
-- The policy pattern: Allow SELECT if public.is_platform_admin()

CREATE POLICY "Admin select access profiles" ON public.profiles FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access tenants" ON public.tenants FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access tenant_users" ON public.tenant_users FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access companies" ON public.companies FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access warehouses" ON public.warehouses FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access categories" ON public.categories FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access products" ON public.products FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access partners" ON public.partners FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access documents" ON public.documents FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access document_lines" ON public.document_lines FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access payments" ON public.payments FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access stock_movements" ON public.stock_movements FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access audit_events" ON public.audit_events FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access settings" ON public.settings FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access sync_devices" ON public.sync_devices FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access sync_errors" ON public.sync_errors FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access sync_conflicts" ON public.sync_conflicts FOR SELECT TO authenticated USING (public.is_platform_admin());
CREATE POLICY "Admin select access files" ON public.files FOR SELECT TO authenticated USING (public.is_platform_admin());
