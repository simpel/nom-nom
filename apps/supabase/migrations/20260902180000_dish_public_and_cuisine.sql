-- ===========================================================================
-- Dish Public Visibility & Cuisine Classification
-- ===========================================================================

-- 1. Add is_public and cuisine columns
alter table public.dishes
    add column if not exists is_public boolean not null default true,
    add column if not exists cuisine text;

create index if not exists dishes_cuisine_idx on public.dishes (cuisine);
create index if not exists dishes_is_public_idx on public.dishes (is_public);

-- 2. Update can_read_dish function to include public dishes
create or replace function public.can_read_dish(p_dish_id uuid)
    returns boolean
    language sql
    security definer
    stable
    set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.dishes d
        where d.id = p_dish_id and (d.is_public = true or d.owner_id = auth.uid())
    ) or exists (
        select 1
        from public.meals m
        join public.meal_invites i on i.meal_id = m.id
        where m.dish_id = p_dish_id and i.invitee_id = auth.uid()
    ) or exists (
        select 1
        from public.meals m
        join public.meal_parties mp on mp.meal_id = m.id
        join public.party_members pm on pm.party_id = mp.party_id
        where m.dish_id = p_dish_id and pm.user_id = auth.uid()
    );
$$;

-- 3. Update dishes_select policy
drop policy if exists dishes_select on public.dishes;

create policy dishes_select on public.dishes
    for select to authenticated using (
        owner_id = auth.uid() or is_public = true or public.can_read_dish(id)
    );
