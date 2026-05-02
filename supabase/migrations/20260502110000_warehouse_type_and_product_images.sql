-- Fix warehouse type schema and product image storage
-- 1. Add warehouses.type
alter table public.warehouses
add column if not exists type text not null default 'depot';

-- 2. Add check constraint safely
alter table public.warehouses
drop constraint if exists warehouses_type_check;

alter table public.warehouses
add constraint warehouses_type_check check (type in ('depot', 'mobile'));

-- 3. Backfill
update public.warehouses
set type = coalesce(type, 'depot')
where type is null;

-- 4. Product image path normalization
-- products table already has image_path in business_schema.sql
-- Ensure we have image_url if needed for legacy or compatibility
alter table public.products
add column if not exists image_url text;

-- 5. Ensure storage buckets exist
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('company-logos', 'company-logos', true)
on conflict (id) do nothing;

-- 6. Storage RLS policies for product images
-- Delete existing policies to avoid duplicates during migration retry
drop policy if exists "Tenant members can read product images" on storage.objects;
drop policy if exists "Tenant writers can upload product images" on storage.objects;

create policy "Tenant members can read product images"
on storage.objects for select
using (
  bucket_id = 'product-images' 
  AND (storage.foldername(name))[1] IN (
    select tenant_id::text from public.profiles where id = auth.uid()
  )
);

create policy "Tenant writers can upload product images"
on storage.objects for insert
with check (
  bucket_id = 'product-images'
  AND (storage.foldername(name))[1] IN (
    select tenant_id::text from public.profiles where id = auth.uid()
  )
);

drop policy if exists "Tenant members can read logos" on storage.objects;
drop policy if exists "Tenant writers can upload logos" on storage.objects;

create policy "Tenant members can read logos"
on storage.objects for select
using (
  bucket_id = 'company-logos'
  AND (storage.foldername(name))[1] IN (
    select tenant_id::text from public.profiles where id = auth.uid()
  )
);

create policy "Tenant writers can upload logos"
on storage.objects for insert
with check (
  bucket_id = 'company-logos'
  AND (storage.foldername(name))[1] IN (
    select tenant_id::text from public.profiles where id = auth.uid()
  )
);

-- 7. Trigger PostgREST schema reload
notify pgrst, 'reload schema';
