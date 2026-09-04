-- ===========================================================================
-- Public Dinner Parties, About Description & Party Followers
-- ===========================================================================

-- 1. Parties: add is_public and about columns
alter table public.parties
    add column if not exists is_public boolean not null default false,
    add column if not exists about     text    not null default '';

create index if not exists parties_is_public_idx on public.parties (is_public);

-- 2. Party Followers
create table if not exists public.party_followers (
    id          uuid primary key default gen_random_uuid(),
    party_id    uuid        not null references public.parties (id) on delete cascade,
    user_id     uuid        not null references auth.users (id) on delete cascade,
    created_at  timestamptz not null default now(),
    unique (party_id, user_id)
);

create index if not exists party_followers_party_idx on public.party_followers (party_id);
create index if not exists party_followers_user_idx  on public.party_followers (user_id);

alter table public.party_followers enable row level security;

-- 3. Party Followers RLS Policies
create policy party_followers_select on public.party_followers
    for select to authenticated using (
        user_id = auth.uid()
        or public.is_party_member(party_id)
        or exists (select 1 from public.parties p where p.id = party_id and p.is_public = true)
    );

create policy party_followers_insert on public.party_followers
    for insert to authenticated with check (
        user_id = auth.uid()
        and exists (
            select 1 from public.parties p
            where p.id = party_id
              and (p.is_public = true or public.is_party_member(party_id))
        )
    );

create policy party_followers_delete on public.party_followers
    for delete to authenticated using (
        user_id = auth.uid()
    );

-- 4. Follow & Unfollow helper functions (Atomic RPCs)
create or replace function public.follow_party(p_party_id uuid)
    returns void
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    if not exists (
        select 1 from public.parties
        where id = p_party_id
          and (is_public = true or public.is_party_member(p_party_id))
    ) then
        raise exception 'Party not found or is private';
    end if;

    insert into public.party_followers (party_id, user_id)
    values (p_party_id, auth.uid())
    on conflict (party_id, user_id) do nothing;
end;
$$;

create or replace function public.unfollow_party(p_party_id uuid)
    returns void
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    delete from public.party_followers
    where party_id = p_party_id and user_id = auth.uid();
end;
$$;

-- 5. Update RLS on Parties
drop policy if exists parties_select on public.parties;

create policy parties_select on public.parties
    for select to authenticated using (
        created_by = auth.uid()
        or public.is_party_member(id)
        or is_public = true
    );

-- 6. Update RLS on Party Members
drop policy if exists party_members_select on public.party_members;

create policy party_members_select on public.party_members
    for select to authenticated using (
        user_id = auth.uid()
        or public.is_party_member(party_id)
        or exists (select 1 from public.parties p where p.id = party_id and p.is_public = true)
    );

-- 7. Update RLS on Meal Parties
drop policy if exists meal_parties_select on public.meal_parties;

create policy meal_parties_select on public.meal_parties
    for select to authenticated using (
        public.is_party_member(party_id)
        or exists (select 1 from public.meals m where m.id = meal_id and m.created_by = auth.uid())
        or exists (select 1 from public.parties p where p.id = party_id and p.is_public = true)
    );

-- 8. Update is_meal_participant to include public party meals
create or replace function public.is_meal_participant(p_meal_id uuid)
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
    ) or exists (
        select 1 from public.meal_parties mp
        join public.parties p on p.id = mp.party_id
        where mp.meal_id = p_meal_id and p.is_public = true
    );
$$;

-- 9. Update can_read_dish to include dishes served to public parties
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
        join public.parties p on p.id = mp.party_id
        where m.dish_id = p_dish_id and (p.is_public = true or public.is_party_member(p.id))
    );
$$;

-- 10. Table Privileges & Function Execution
grant select, insert, delete on public.party_followers to authenticated;
grant execute on function public.follow_party(uuid) to authenticated;
grant execute on function public.unfollow_party(uuid) to authenticated;
