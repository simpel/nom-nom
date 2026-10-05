-- Rate a meal: every eater answers for themselves.
--
-- 1. A rating carries more than the verdict: what stood out (tags), how much of the
--    plate they ate, whether they want it again, and their own note. All per rater.
-- 2. Nobody rates for anybody else. The "verdict for one of your household eaters"
--    branch is gone; existing eater rows stay readable as history.
-- 3. Rating is for the people who were at the table: the cook, anyone asked to rate,
--    and members of a party the meal was served to. Following a public party lets
--    you read a meal, not rate it.

alter table public.meal_ratings
    add column tags text[] not null default '{}',
    add column plate smallint,
    add column again smallint,
    add column note text;

alter table public.meal_ratings
    add constraint meal_ratings_tags_known check (tags <@ array[
        'tasty', 'bland', 'salty', 'spicy', 'sweet', 'sour',
        'tender', 'crispy', 'dry', 'soggy', 'chewy',
        'justRight', 'overcooked', 'undercooked',
        'comforting', 'fresh', 'heavy'
    ]::text[]),
    -- 0 a few bites · 1 half · 2 cleared · 3 had seconds
    add constraint meal_ratings_plate_range check (plate between 0 and 3),
    -- 0 not again · 1 sometime · 2 soon
    add constraint meal_ratings_again_range check (again between 0 and 2);

create function public.can_rate_meal(p_meal_id uuid)
    returns boolean
    language sql
    security definer
    stable
    set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.meals m
        where m.id = p_meal_id and m.created_by = auth.uid()
    ) or exists (
        select 1 from public.meal_invites i
        where i.meal_id = p_meal_id and i.invitee_id = auth.uid()
    ) or exists (
        select 1 from public.meal_parties mp
        join public.party_members pm on pm.party_id = mp.party_id
        where mp.meal_id = p_meal_id and pm.user_id = auth.uid()
    );
$$;

revoke all on function public.can_rate_meal(uuid) from public;
grant execute on function public.can_rate_meal(uuid) to authenticated;

drop policy if exists meal_ratings_insert on public.meal_ratings;
drop policy if exists meal_ratings_update on public.meal_ratings;
drop policy if exists meal_ratings_delete on public.meal_ratings;

create policy meal_ratings_insert on public.meal_ratings
    for insert to authenticated with check (
        rater_id = auth.uid()
        and eater_id is null
        and public.can_rate_meal(meal_id)
    );

create policy meal_ratings_update on public.meal_ratings
    for update to authenticated
    using (rater_id = auth.uid())
    with check (rater_id = auth.uid() and eater_id is null and public.can_rate_meal(meal_id));

create policy meal_ratings_delete on public.meal_ratings
    for delete to authenticated using (rater_id = auth.uid());
