alter table public.profiles
add column if not exists email text;

create index if not exists idx_profiles_email
on public.profiles(email);

do $$
declare
  col_id boolean;
  col_user_id boolean;
begin
  select exists(
    select 1 from information_schema.columns 
    where table_schema='public' and table_name='profiles' and column_name='id'
  ) into col_id;

  select exists(
    select 1 from information_schema.columns 
    where table_schema='public' and table_name='profiles' and column_name='user_id'
  ) into col_user_id;

  if col_id then
    update public.profiles p
    set email = u.email
    from auth.users u
    where p.id = u.id and p.email is null;
  elsif col_user_id then
    update public.profiles p
    set email = u.email
    from auth.users u
    where p.user_id = u.id and p.email is null;
  end if;
end $$;
