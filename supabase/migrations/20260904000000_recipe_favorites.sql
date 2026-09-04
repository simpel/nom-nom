-- ===========================================================================
-- Recipe Favorites Table & RLS Policies
-- ===========================================================================

create table if not exists public.recipe_favorites (
    id          uuid primary key default gen_random_uuid(),
    recipe_id   uuid        not null references public.dishes (id) on delete cascade,
    user_id     uuid        not null references auth.users (id) on delete cascade,
    created_at  timestamptz not null default now(),
    unique (recipe_id, user_id)
);

create index if not exists recipe_favorites_recipe_idx on public.recipe_favorites (recipe_id);
create index if not exists recipe_favorites_user_idx   on public.recipe_favorites (user_id);

alter table public.recipe_favorites enable row level security;

create policy recipe_favorites_select on public.recipe_favorites
    for select to authenticated using (
        user_id = auth.uid()
    );

create policy recipe_favorites_insert on public.recipe_favorites
    for insert to authenticated with check (
        user_id = auth.uid()
        and public.can_read_dish(recipe_id)
    );

create policy recipe_favorites_delete on public.recipe_favorites
    for delete to authenticated using (
        user_id = auth.uid()
    );

grant select, insert, delete on public.recipe_favorites to authenticated;
