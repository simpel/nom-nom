-- 20261005130000_score_insights.sql
-- Nom Nom Pro on the meal score sheet: AI "make it land next time" tips (cached per meal,
-- written by the suggest-recipe-tweaks edge function), one note per party per recipe,
-- and the first server-side Pro check.

alter type public.generation_type add value if not exists 'recipe_tweaks';

insert into public.ai_feature_configs (feature_id, model_name) values
    ('recipe-tweaks', 'google/gemini-2.5-flash')
on conflict (feature_id) do nothing;

-- 1. Pro, as the RevenueCat webhook records it: active, or cancelled but not yet expired.
create or replace function public.has_pro(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1 from public.profiles
        where id = p_user_id
          and subscription_status in ('active', 'canceled')
          and (subscription_expires_at is null or subscription_expires_at > now())
    );
$$;

revoke execute on function public.has_pro(uuid) from public, anon, authenticated;
grant  execute on function public.has_pro(uuid) to service_role;

-- 2. Tips cache: written with the service role key, read by the meal's party members.
create table if not exists public.meal_score_tweaks (
    meal_id      uuid        primary key references public.meals (id) on delete cascade,
    party_id     uuid        not null references public.parties (id) on delete cascade,
    payload      jsonb       not null,
    generated_at timestamptz not null default now()
);

alter table public.meal_score_tweaks enable row level security;

create policy meal_score_tweaks_select on public.meal_score_tweaks
    for select to authenticated using (public.is_party_member(party_id));

-- 3. Party recipe notes: what a party has learned about a recipe ("Halve the chilli").
-- One per party per recipe, so a recipe can carry several notes, one per table.
create table if not exists public.party_recipe_notes (
    id         uuid        primary key default gen_random_uuid(),
    party_id   uuid        not null references public.parties (id) on delete cascade,
    dish_id    uuid        not null references public.dishes (id) on delete cascade,
    body       text        not null default '',
    updated_by uuid        references auth.users (id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (party_id, dish_id)
);

create index if not exists party_recipe_notes_dish_idx on public.party_recipe_notes (dish_id);

create trigger party_recipe_notes_updated_at
    before update on public.party_recipe_notes
    for each row execute procedure extensions.moddatetime (updated_at);

alter table public.party_recipe_notes enable row level security;

create policy party_recipe_notes_select on public.party_recipe_notes
    for select to authenticated using (public.is_party_member(party_id));

create policy party_recipe_notes_insert on public.party_recipe_notes
    for insert to authenticated
    with check (public.is_party_member(party_id) and public.can_read_dish(dish_id));

create policy party_recipe_notes_update on public.party_recipe_notes
    for update to authenticated
    using (public.is_party_member(party_id))
    with check (public.is_party_member(party_id) and public.can_read_dish(dish_id));

create policy party_recipe_notes_delete on public.party_recipe_notes
    for delete to authenticated using (public.is_party_member(party_id));
