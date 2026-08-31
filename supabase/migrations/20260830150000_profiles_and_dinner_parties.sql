-- ===========================================================================
-- Profiles Enhancements & Dinner Parties Architecture
-- ===========================================================================

-- 1. Profiles: add first_name and last_name
alter table public.profiles
    add column if not exists first_name text not null default '',
    add column if not exists last_name  text not null default '';

-- 2. Expand notifications kind constraint
alter table public.notifications
    drop constraint if exists notifications_kind_check;

alter table public.notifications
    add constraint notifications_kind_check
    check (kind in ('rating_request', 'rating_received', 'party_invite', 'party_joined'));

-- 3. Dinner Parties & Memberships
create table if not exists public.parties (
    id          uuid primary key default gen_random_uuid(),
    name        text        not null check (length(btrim(name)) > 0),
    created_by  uuid        not null references auth.users (id) on delete cascade,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create index if not exists parties_created_by_idx on public.parties (created_by);

create table if not exists public.party_members (
    id          uuid primary key default gen_random_uuid(),
    party_id    uuid        not null references public.parties (id) on delete cascade,
    user_id     uuid        not null references auth.users (id) on delete cascade,
    joined_at   timestamptz not null default now(),
    unique (party_id, user_id)
);

create index if not exists party_members_user_idx  on public.party_members (user_id);
create index if not exists party_members_party_idx on public.party_members (party_id);

-- 4. Party Invites
create table if not exists public.party_invites (
    id            uuid primary key default gen_random_uuid(),
    party_id      uuid        not null references public.parties (id) on delete cascade,
    inviter_id    uuid        not null references auth.users (id) on delete cascade,
    invitee_id    uuid        references auth.users (id) on delete cascade,
    invitee_email text,
    status        public.invite_status not null default 'pending',
    created_at    timestamptz not null default now(),
    responded_at  timestamptz,
    constraint party_invitee_identified check (invitee_id is not null or invitee_email is not null)
);

create unique index if not exists party_invites_party_user_idx
    on public.party_invites (party_id, invitee_id) where invitee_id is not null;
create unique index if not exists party_invites_party_email_idx
    on public.party_invites (party_id, lower(invitee_email)) where invitee_id is null;
create index if not exists party_invites_invitee_idx on public.party_invites (invitee_id, status);

-- 5. Meal Parties (Serving meals to dinner parties)
create table if not exists public.meal_parties (
    id          uuid primary key default gen_random_uuid(),
    meal_id     uuid        not null references public.meals (id) on delete cascade,
    party_id    uuid        not null references public.parties (id) on delete cascade,
    created_at  timestamptz not null default now(),
    unique (meal_id, party_id)
);

create index if not exists meal_parties_meal_idx  on public.meal_parties (meal_id);
create index if not exists meal_parties_party_idx on public.meal_parties (party_id);

-- ===========================================================================
-- RLS Helpers
-- ===========================================================================

create or replace function public.is_party_member(p_party_id uuid)
    returns boolean
    language sql
    security definer
    stable
    set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.party_members pm
        where pm.party_id = p_party_id and pm.user_id = auth.uid()
    );
$$;

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
    );
$$;

create or replace function public.can_read_dish(p_dish_id uuid)
    returns boolean
    language sql
    security definer
    stable
    set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.dishes d
        where d.id = p_dish_id and d.owner_id = auth.uid()
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

revoke execute on function public.is_party_member(uuid) from public;
grant  execute on function public.is_party_member(uuid) to authenticated;
grant  execute on function public.is_meal_participant(uuid) to authenticated;
grant  execute on function public.can_read_dish(uuid)       to authenticated;

-- ===========================================================================
-- Row Level Security
-- ===========================================================================

alter table public.parties       enable row level security;
alter table public.party_members enable row level security;
alter table public.party_invites enable row level security;
alter table public.meal_parties  enable row level security;

-- Parties
create policy parties_select on public.parties
    for select to authenticated using (
        created_by = auth.uid() or public.is_party_member(id)
    );

create policy parties_insert on public.parties
    for insert to authenticated with check (
        created_by = auth.uid()
    );

create policy parties_update on public.parties
    for update to authenticated
    using (created_by = auth.uid() or public.is_party_member(id))
    with check (created_by = auth.uid() or public.is_party_member(id));

create policy parties_delete on public.parties
    for delete to authenticated using (
        created_by = auth.uid() or public.is_party_member(id)
    );

-- Party Members
create policy party_members_select on public.party_members
    for select to authenticated using (
        user_id = auth.uid() or public.is_party_member(party_id)
    );

create policy party_members_insert on public.party_members
    for insert to authenticated with check (
        user_id = auth.uid()
        or public.is_party_member(party_id)
        or exists (select 1 from public.parties p where p.id = party_id and p.created_by = auth.uid())
    );

create policy party_members_delete on public.party_members
    for delete to authenticated using (
        user_id = auth.uid() or public.is_party_member(party_id)
    );

-- Party Invites
create policy party_invites_select on public.party_invites
    for select to authenticated using (
        inviter_id = auth.uid() or invitee_id = auth.uid() or public.is_party_member(party_id)
    );

create policy party_invites_insert on public.party_invites
    for insert to authenticated with check (
        inviter_id = auth.uid() and public.is_party_member(party_id)
    );

create policy party_invites_update on public.party_invites
    for update to authenticated
    using (invitee_id = auth.uid() or inviter_id = auth.uid())
    with check (invitee_id = auth.uid() or inviter_id = auth.uid());

create policy party_invites_delete on public.party_invites
    for delete to authenticated using (
        inviter_id = auth.uid() or public.is_party_member(party_id)
    );

-- Meal Parties
create policy meal_parties_select on public.meal_parties
    for select to authenticated using (
        public.is_party_member(party_id)
        or exists (select 1 from public.meals m where m.id = meal_id and m.created_by = auth.uid())
    );

create policy meal_parties_insert on public.meal_parties
    for insert to authenticated with check (
        public.is_party_member(party_id)
        and exists (select 1 from public.meals m where m.id = meal_id and m.created_by = auth.uid())
    );

create policy meal_parties_delete on public.meal_parties
    for delete to authenticated using (
        public.is_party_member(party_id)
        or exists (select 1 from public.meals m where m.id = meal_id and m.created_by = auth.uid())
    );

-- ===========================================================================
-- Triggers
-- ===========================================================================

-- Auto-add party creator as member
create or replace function public.add_party_creator_as_member()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    insert into public.party_members (party_id, user_id)
    values (new.id, new.created_by)
    on conflict (party_id, user_id) do nothing;
    return new;
end;
$$;

create trigger parties_add_creator_member
    after insert on public.parties
    for each row execute function public.add_party_creator_as_member();

-- Touch updated_at for parties
create trigger parties_touch
    before update on public.parties
    for each row execute function public.touch_updated_at();

-- Auto-delete party when last member leaves
create or replace function public.cleanup_empty_party()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    if not exists (select 1 from public.party_members where party_id = old.party_id) then
        delete from public.parties where id = old.party_id;
    end if;
    return old;
end;
$$;

create trigger party_members_cleanup_empty
    after delete on public.party_members
    for each row execute function public.cleanup_empty_party();

-- Link party invite by email on insert
create or replace function public.link_party_invitee_by_email()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    if new.invitee_id is null and new.invitee_email is not null then
        select u.id
          into new.invitee_id
          from auth.users u
         where lower(u.email) = lower(btrim(new.invitee_email))
         limit 1;
    end if;

    return new;
end;
$$;

create trigger party_invites_link_invitee
    before insert on public.party_invites
    for each row execute function public.link_party_invitee_by_email();

-- Party invite -> notify invitee
create or replace function public.notify_party_invitee()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_party_name text;
    v_inviter_name text;
begin
    if new.invitee_id is null then
        return new;
    end if;

    if tg_op = 'UPDATE' and old.invitee_id is not null then
        return new;
    end if;

    if new.invitee_id = new.inviter_id then
        return new;
    end if;

    select p.name into v_party_name from public.parties p where p.id = new.party_id;
    select coalesce(nullif(pr.display_name, ''), 'Someone')
      into v_inviter_name
      from public.profiles pr
     where pr.id = new.inviter_id;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        new.invitee_id,
        null,
        'party_invite',
        'Dinner Party Invitation',
        coalesce(v_inviter_name, 'Someone') || ' invited you to join ' || coalesce(v_party_name, 'a dinner party') || '.'
    );

    return new;
end;
$$;

create trigger party_invites_notify
    after insert or update of invitee_id on public.party_invites
    for each row execute function public.notify_party_invitee();

-- Upgrade handle_new_user to support first_name, last_name and claim party_invites
create or replace function public.handle_new_user()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_first_name text;
    v_last_name  text;
    v_full_name  text;
begin
    v_first_name := coalesce(new.raw_user_meta_data ->> 'first_name', '');
    v_last_name  := coalesce(new.raw_user_meta_data ->> 'last_name', '');
    v_full_name  := coalesce(
        nullif(trim(v_first_name || ' ' || v_last_name), ''),
        nullif(new.raw_user_meta_data ->> 'full_name', ''),
        split_part(coalesce(new.email, ''), '@', 1),
        ''
    );

    insert into public.profiles (id, first_name, last_name, display_name)
    values (
        new.id,
        v_first_name,
        v_last_name,
        v_full_name
    )
    on conflict (id) do update
        set first_name   = excluded.first_name,
            last_name    = excluded.last_name,
            display_name = excluded.display_name
        where profiles.display_name = '';

    if new.email is not null then
        update public.meal_invites
           set invitee_id = new.id
         where invitee_id is null
           and lower(invitee_email) = lower(new.email);

        update public.party_invites
           set invitee_id = new.id
         where invitee_id is null
           and lower(invitee_email) = lower(new.email);
    end if;

    return new;
end;
$$;

-- Table privileges
grant select, insert, update, delete on public.parties       to authenticated;
grant select, insert, update, delete on public.party_members to authenticated;
grant select, insert, update, delete on public.party_invites to authenticated;
grant select, insert, update, delete on public.meal_parties  to authenticated;
