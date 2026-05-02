alter table public.warehouses
add column if not exists type text not null default 'depot';
