create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.increment_version()
returns trigger
language plpgsql
as $$
begin
  new.version = coalesce(old.version, 0) + 1;
  return new;
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
    execute format('create index if not exists %I on public.%I (tenant_id)', 'idx_' || table_name || '_tenant_id', table_name);
    execute format('create index if not exists %I on public.%I (tenant_id, updated_at)', 'idx_' || table_name || '_tenant_updated_at', table_name);
    execute format('create index if not exists %I on public.%I (tenant_id, deleted_at)', 'idx_' || table_name || '_tenant_deleted_at', table_name);

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

create index if not exists idx_products_tenant_name
  on public.products (tenant_id, name);
create index if not exists idx_products_tenant_sku
  on public.products (tenant_id, sku);
create index if not exists idx_products_tenant_barcode
  on public.products (tenant_id, barcode);
create unique index if not exists ux_products_tenant_sku_active
  on public.products (tenant_id, lower(sku))
  where sku is not null and btrim(sku) <> '' and deleted_at is null;
create unique index if not exists ux_products_tenant_barcode_active
  on public.products (tenant_id, lower(barcode))
  where barcode is not null and btrim(barcode) <> '' and deleted_at is null;

create index if not exists idx_partners_tenant_type_name
  on public.partners (tenant_id, type, name);
create index if not exists idx_partners_tenant_phone
  on public.partners (tenant_id, phone);

create index if not exists idx_documents_tenant_type
  on public.documents (tenant_id, type);
create index if not exists idx_documents_tenant_status
  on public.documents (tenant_id, status);
create index if not exists idx_documents_tenant_number
  on public.documents (tenant_id, number);
create index if not exists idx_documents_tenant_issue_date
  on public.documents (tenant_id, issue_date);
create unique index if not exists ux_documents_tenant_type_number_active
  on public.documents (tenant_id, type, number)
  where deleted_at is null;

create index if not exists idx_document_lines_tenant_document
  on public.document_lines (tenant_id, document_id);
create index if not exists idx_document_lines_tenant_product
  on public.document_lines (tenant_id, product_id);

create index if not exists idx_payments_tenant_document
  on public.payments (tenant_id, document_id);
create index if not exists idx_payments_tenant_date
  on public.payments (tenant_id, date);

create index if not exists idx_stock_movements_tenant_product
  on public.stock_movements (tenant_id, product_id);
create index if not exists idx_stock_movements_tenant_warehouse
  on public.stock_movements (tenant_id, warehouse_id);
create index if not exists idx_stock_movements_tenant_product_warehouse
  on public.stock_movements (tenant_id, product_id, warehouse_id);
create index if not exists idx_stock_movements_tenant_created_at
  on public.stock_movements (tenant_id, created_at);

create index if not exists idx_audit_events_tenant_created_at
  on public.audit_events (tenant_id, created_at desc);
create index if not exists idx_audit_events_tenant_entity
  on public.audit_events (tenant_id, entity_type, entity_id);

create unique index if not exists ux_settings_tenant_key
  on public.settings (tenant_id, key);

create unique index if not exists ux_warehouses_tenant_default_active
  on public.warehouses (tenant_id)
  where is_default is true and is_active is true and deleted_at is null;

alter table public.categories
  add constraint categories_tenant_id_id_key unique (tenant_id, id);

alter table public.warehouses
  add constraint warehouses_tenant_id_id_key unique (tenant_id, id);

alter table public.products
  add constraint products_tenant_id_id_key unique (tenant_id, id);

alter table public.partners
  add constraint partners_tenant_id_id_key unique (tenant_id, id);

alter table public.documents
  add constraint documents_tenant_id_id_key unique (tenant_id, id);

alter table public.products
  add constraint products_category_same_tenant
  foreign key (tenant_id, category_id)
  references public.categories(tenant_id, id)
  not valid;

alter table public.documents
  add constraint documents_partner_same_tenant
  foreign key (tenant_id, partner_id)
  references public.partners(tenant_id, id)
  not valid,
  add constraint documents_warehouse_same_tenant
  foreign key (tenant_id, warehouse_id)
  references public.warehouses(tenant_id, id)
  not valid,
  add constraint documents_source_same_tenant
  foreign key (tenant_id, source_document_id)
  references public.documents(tenant_id, id)
  not valid;

alter table public.document_lines
  add constraint document_lines_document_same_tenant
  foreign key (tenant_id, document_id)
  references public.documents(tenant_id, id)
  not valid,
  add constraint document_lines_product_same_tenant
  foreign key (tenant_id, product_id)
  references public.products(tenant_id, id)
  not valid;

alter table public.payments
  add constraint payments_document_same_tenant
  foreign key (tenant_id, document_id)
  references public.documents(tenant_id, id)
  not valid;

alter table public.stock_movements
  add constraint stock_movements_product_same_tenant
  foreign key (tenant_id, product_id)
  references public.products(tenant_id, id)
  not valid,
  add constraint stock_movements_warehouse_same_tenant
  foreign key (tenant_id, warehouse_id)
  references public.warehouses(tenant_id, id)
  not valid,
  add constraint stock_movements_document_same_tenant
  foreign key (tenant_id, source_document_id)
  references public.documents(tenant_id, id)
  not valid;

alter table public.products
  add constraint products_purchase_price_non_negative check (purchase_price_ht >= 0) not valid,
  add constraint products_sale_price_non_negative check (sale_price_ht >= 0) not valid,
  add constraint products_stock_minimum_non_negative check (stock_minimum >= 0) not valid;

alter table public.document_lines
  add constraint document_lines_quantity_non_negative check (quantity >= 0) not valid,
  add constraint document_lines_discount_non_negative check (discount >= 0) not valid;

alter table public.payments
  add constraint payments_amount_non_negative check (amount >= 0) not valid;

alter table public.files
  add constraint files_size_bytes_non_negative check (size_bytes is null or size_bytes >= 0) not valid;
