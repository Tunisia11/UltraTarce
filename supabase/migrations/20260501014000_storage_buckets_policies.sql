create or replace function public.tenant_id_from_storage_path(p_path text)
returns uuid
language plpgsql
stable
as $$
declare
  first_segment text;
begin
  first_segment := split_part(p_path, '/', 1);
  if first_segment ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return first_segment::uuid;
  end if;
  return null;
end;
$$;

do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public)
    values
      ('tenant-logos', 'tenant-logos', false),
      ('product-images', 'product-images', false),
      ('document-pdfs', 'document-pdfs', false),
      ('backups', 'backups', false),
      ('attachments', 'attachments', false)
    on conflict (id) do nothing;
  end if;

  if to_regclass('storage.objects') is not null then
    execute 'drop policy if exists tenant_storage_select_member on storage.objects';
    execute 'create policy tenant_storage_select_member on storage.objects for select to authenticated using (
      bucket_id in (''tenant-logos'', ''product-images'', ''document-pdfs'', ''backups'', ''attachments'')
      and public.is_tenant_member(public.tenant_id_from_storage_path(name))
    )';

    execute 'drop policy if exists tenant_storage_insert_writer on storage.objects';
    execute 'create policy tenant_storage_insert_writer on storage.objects for insert to authenticated with check (
      bucket_id in (''tenant-logos'', ''product-images'', ''document-pdfs'', ''backups'', ''attachments'')
      and public.can_insert_business_row(public.tenant_id_from_storage_path(name), ''files'')
      and (owner is null or owner = auth.uid())
    )';

    execute 'drop policy if exists tenant_storage_update_writer on storage.objects';
    execute 'create policy tenant_storage_update_writer on storage.objects for update to authenticated using (
      bucket_id in (''tenant-logos'', ''product-images'', ''document-pdfs'', ''backups'', ''attachments'')
      and public.can_update_business_row(public.tenant_id_from_storage_path(name), ''files'')
    ) with check (
      bucket_id in (''tenant-logos'', ''product-images'', ''document-pdfs'', ''backups'', ''attachments'')
      and public.can_update_business_row(public.tenant_id_from_storage_path(name), ''files'')
      and (owner is null or owner = auth.uid())
    )';
  end if;
end $$;
