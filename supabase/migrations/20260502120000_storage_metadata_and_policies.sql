-- Phase 10: Storage Metadata and Advanced Policies

-- 1. Create files metadata table
create table if not exists public.files (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  bucket text not null,
  path text not null,
  file_name text,
  mime_type text,
  size_bytes bigint,
  entity_type text,
  entity_id text,
  purpose text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  synced_at timestamptz,
  
  constraint files_bucket_path_unique unique(bucket, path),
  -- Ensure path starts with tenant_id for bucket isolation safety
  constraint files_path_tenant_check check (path LIKE (tenant_id::text || '/%'))
);

-- 2. Enable RLS
alter table public.files enable row level security;

-- 3. Files RLS Policies
drop policy if exists "Tenant members can view their files" on public.files;
create policy "Tenant members can view their files"
on public.files for select
to authenticated
using (public.is_tenant_member(tenant_id));

drop policy if exists "Tenant writers can manage their files" on public.files;
create policy "Tenant writers can manage their files"
on public.files for insert
to authenticated
with check (public.can_insert_business_row(tenant_id, 'files'));

drop policy if exists "Tenant writers can update their files" on public.files;
create policy "Tenant writers can update their files"
on public.files for update
to authenticated
using (public.can_update_business_row(tenant_id, 'files'))
with check (public.can_update_business_row(tenant_id, 'files'));

-- 4. Ensure all buckets exist and are private
insert into storage.buckets (id, name, public)
values 
  ('product-images', 'product-images', false),
  ('company-logos', 'company-logos', false),
  ('document-pdfs', 'document-pdfs', false),
  ('attachments', 'attachments', false),
  ('backups', 'backups', false)
on conflict (id) do update set public = false;

-- 5. Unified Storage Policies
-- Robust policies based on tenant_id_from_storage_path helper

drop policy if exists "tenant_storage_select_member" on storage.objects;
create policy "tenant_storage_select_member"
on storage.objects for select
to authenticated
using (
  bucket_id in ('product-images', 'company-logos', 'document-pdfs', 'attachments', 'backups')
  and public.is_tenant_member(public.tenant_id_from_storage_path(name))
);

drop policy if exists "tenant_storage_insert_writer" on storage.objects;
create policy "tenant_storage_insert_writer"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('product-images', 'company-logos', 'document-pdfs', 'attachments', 'backups')
  and public.can_insert_business_row(public.tenant_id_from_storage_path(name), 'files')
);

drop policy if exists "tenant_storage_update_writer" on storage.objects;
create policy "tenant_storage_update_writer"
on storage.objects for update
to authenticated
using (
  bucket_id in ('product-images', 'company-logos', 'document-pdfs', 'attachments', 'backups')
  and public.can_update_business_row(public.tenant_id_from_storage_path(name), 'files')
)
with check (
  bucket_id in ('product-images', 'company-logos', 'document-pdfs', 'attachments', 'backups')
  and public.can_update_business_row(public.tenant_id_from_storage_path(name), 'files')
);

drop policy if exists "tenant_storage_delete_admin" on storage.objects;
create policy "tenant_storage_delete_admin"
on storage.objects for delete
to authenticated
using (
  bucket_id in ('product-images', 'company-logos', 'document-pdfs', 'attachments', 'backups')
  and public.is_tenant_admin(public.tenant_id_from_storage_path(name))
);

-- 6. Grant access
grant all on public.files to authenticated;
grant all on public.files to service_role;

notify pgrst, 'reload schema';
