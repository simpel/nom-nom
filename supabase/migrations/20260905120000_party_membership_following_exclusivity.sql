-- ===========================================================================
-- Enforce Exclusivity: Party Members Cannot Follow Their Own Parties
-- ===========================================================================

-- 1. Remove any legacy follower records where the user is already a member or creator
delete from public.party_followers pf
where exists (
    select 1 from public.party_members pm
    where pm.party_id = pf.party_id and pm.user_id = pf.user_id
) or exists (
    select 1 from public.parties p
    where p.id = pf.party_id and p.created_by = pf.user_id
);

-- 2. Update follow_party RPC function to strictly prohibit members & creators
create or replace function public.follow_party(p_party_id uuid)
    returns void
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    -- Disallow if user is already a member or creator of the party
    if exists (
        select 1 from public.party_members
        where party_id = p_party_id and user_id = auth.uid()
    ) or exists (
        select 1 from public.parties
        where id = p_party_id and created_by = auth.uid()
    ) then
        raise exception 'Cannot follow a dinner party you are already a member of';
    end if;

    -- Disallow if party does not exist or is private
    if not exists (
        select 1 from public.parties
        where id = p_party_id and is_public = true
    ) then
        raise exception 'Party not found or is private';
    end if;

    insert into public.party_followers (party_id, user_id)
    values (p_party_id, auth.uid())
    on conflict (party_id, user_id) do nothing;
end;
$$;

-- 3. Update party_followers_insert RLS policy
drop policy if exists party_followers_insert on public.party_followers;

create policy party_followers_insert on public.party_followers
    for insert to authenticated with check (
        user_id = auth.uid()
        and not exists (
            select 1 from public.party_members pm
            where pm.party_id = party_id and pm.user_id = auth.uid()
        )
        and exists (
            select 1 from public.parties p
            where p.id = party_id and p.is_public = true and p.created_by != auth.uid()
        )
    );

-- 4. Auto-remove follower if the user joins or is added as a member
create or replace function public.cleanup_follower_on_member_join()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    delete from public.party_followers
    where party_id = new.party_id and user_id = new.user_id;
    return new;
end;
$$;

drop trigger if exists party_members_cleanup_follower on public.party_members;

create trigger party_members_cleanup_follower
    after insert on public.party_members
    for each row execute function public.cleanup_follower_on_member_join();
