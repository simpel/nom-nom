-- A real admin concept. Before this, /admin only checked "signed in", and
-- ai_feature_configs let every authenticated user write (so any app user could
-- change the AI model of every feature).
--
-- public.admins lists auth users allowed into /admin and allowed to change AI
-- config. Nobody can read or write it through the API (no policies, no grants);
-- the server checks it through public.is_admin(). Add an admin with the service
-- role or the SQL editor:  insert into public.admins (user_id) values ('<uuid>');

create table if not exists public.admins (
    user_id uuid primary key references auth.users (id) on delete cascade,
    created_at timestamptz not null default now()
);

alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (select 1 from public.admins where user_id = (select auth.uid()));
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- Keep the existing admin login working: the dashboard account is the only
-- user who has been using /admin. Other environments add their own row.
insert into public.admins (user_id)
select id from auth.users where email = 'app@nomnom.casa'
on conflict do nothing;

-- ai_feature_configs: everyone signed in may read; only admins write.
drop policy if exists ai_feature_configs_all on public.ai_feature_configs;

create policy ai_feature_configs_insert on public.ai_feature_configs
    for insert to authenticated
    with check (public.is_admin());

create policy ai_feature_configs_update on public.ai_feature_configs
    for update to authenticated
    using (public.is_admin())
    with check (public.is_admin());

create policy ai_feature_configs_delete on public.ai_feature_configs
    for delete to authenticated
    using (public.is_admin());
