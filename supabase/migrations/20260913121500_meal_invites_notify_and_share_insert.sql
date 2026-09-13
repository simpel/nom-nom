-- "Ask to rate" (client: FoodStore.askToRate) inserts a meal_invites row.
-- meal_invites_insert only allowed the MEAL'S CREATOR to insert a row, but
-- the "Ask to rate" button is shown to any party member viewing the meal
-- (MealDetailPartyRatingsCard has no isMe/creator gate — see MealDetailView.swift:159,
-- rendered for every viewer regardless of meal.createdBy). Anyone else tapping
-- it hit a silent RLS rejection: the client ignores the returned Bool, so the
-- button just flipped back with no visible error.
--
-- (The notifications side of this — meal_invites already has a
-- meal_invites_notify trigger firing notify_invitee(), which files a
-- 'rating_request' row exactly like this migration's changelog assumed was
-- missing — turned out to already exist from the baseline migration. Only
-- the insert policy needed widening.)
create or replace function public.shares_meal_party(p_meal_id uuid)
    returns boolean
    language sql
    security definer
    stable
    set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.meal_parties mp
        join public.party_members pm on pm.party_id = mp.party_id
        where mp.meal_id = p_meal_id and pm.user_id = auth.uid()
    );
$$;

revoke execute on function public.shares_meal_party(uuid) from public;
grant  execute on function public.shares_meal_party(uuid) to authenticated;

drop policy if exists meal_invites_insert on public.meal_invites;

create policy meal_invites_insert on public.meal_invites
    for insert to authenticated with check (
        inviter_id = auth.uid()
        and (
            exists (select 1 from public.meals m where m.id = meal_id and m.created_by = auth.uid())
            or public.shares_meal_party(meal_id)
        )
    );
