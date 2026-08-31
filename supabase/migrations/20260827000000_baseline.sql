-- Nom Nom, whole schema. One file.
--
-- This is the entire database: eight tables, their row level security, the photo
-- bucket, and the triggers that keep the inbox filled. It targets a Supabase
-- project created fresh for this app, so it can simply create things — there is no
-- previous tenant to work around.
--
-- Two habits are kept anyway, because each one cost a real bug rather than being
-- caution for its own sake:
--
--   * The bucket asserts its settings instead of skipping when it already exists.
--     An earlier version used `on conflict do nothing`, met a bucket left behind by
--     another app, and left every meal photo world-readable behind a schema that
--     believed it had made them private.
--   * Privileges are revoked before they are granted. "We deliberately withheld
--     INSERT on notifications" is only true if the role did not already have it,
--     and Supabase's default privileges hand `anon` and `authenticated` everything
--     unless something takes it back.
--
-- Section 8 is last on purpose: it revokes from `anon`, so it has to run after every
-- object it covers exists.

-- ===========================================================================
-- 1. Types
-- ===========================================================================

-- Plain `create type`. The old version wrapped this in
-- `exception when duplicate_object then null`, which is `if not exists` wearing a
-- disguise: a surviving enum missing 'declined' would have been kept, passed the
-- table definition below (the default 'pending' is valid in both), and failed at
-- runtime the first time somebody declined an invite.
create type public.invite_status as enum ('pending', 'accepted', 'declined');

-- ===========================================================================
-- 2. Tables
--
-- Plain `create table` throughout, never `if not exists`. These names have already
-- collided once with a previous project on this instance, and a silent skip leaves
-- a table with the wrong columns in place — far worse than a failed migration.
--
-- Indexes likewise carry no `if not exists`. Postgres matches that guard on the
-- *name* only and explicitly promises nothing about the existing index's shape, and
-- four of the indexes below are the entire implementation of "one invite per person
-- per meal" and "one verdict per rater per meal" — there is no unique constraint
-- behind them to fall back on. A silently-kept non-unique namesake would delete
-- those invariants and emit a NOTICE while doing it.
-- ===========================================================================

-- Profiles: the public face of an auth user. Deliberately thin — display name and
-- an emoji are all another participant needs to see, and it holds no email address,
-- which is what keeps `auth.users` unreadable from any client role.
create table public.profiles (
    id            uuid primary key references auth.users (id) on delete cascade,
    display_name  text        not null default '',
    avatar_emoji  text        not null default '🧑',
    created_at    timestamptz not null default now()
);

-- Dishes: the canonical name of something we cook. `normalized_name` is the folded
-- matching key the client builds, and the unique constraint on it is what stops
-- "Tacos" and "tacos" becoming two dishes. The client's find-or-create is the
-- friendly path; this constraint is the guarantee.
create table public.dishes (
    id              uuid primary key default gen_random_uuid(),
    owner_id        uuid        not null references auth.users (id) on delete cascade,
    name            text        not null check (length(btrim(name)) > 0),
    normalized_name text        not null check (length(btrim(normalized_name)) > 0),
    tags            text[]      not null default '{}',
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    unique (owner_id, normalized_name)
);

create index dishes_owner_idx on public.dishes (owner_id);

-- Meals: one occasion of eating a dish.
create table public.meals (
    id         uuid primary key default gen_random_uuid(),
    dish_id    uuid        not null references public.dishes (id) on delete cascade,
    created_by uuid        not null references auth.users (id) on delete cascade,
    eaten_on   date        not null default current_date,
    notes      text        not null default '',
    -- Object path inside the private `meal-photos` bucket, "<meal_id>/<uuid>.jpg".
    photo_path text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index meals_dish_idx    on public.meals (dish_id);
create index meals_creator_idx on public.meals (created_by, eaten_on desc);

-- Invites. `invitee_id` is null until that person has an account: you may invite an
-- address nobody has signed up with, and it is claimed on first sign-in.
create table public.meal_invites (
    id            uuid primary key default gen_random_uuid(),
    meal_id       uuid        not null references public.meals (id) on delete cascade,
    inviter_id    uuid        not null references auth.users (id) on delete cascade,
    invitee_id    uuid        references auth.users (id) on delete cascade,
    invitee_email text,
    status        public.invite_status not null default 'pending',
    created_at    timestamptz not null default now(),
    responded_at  timestamptz,
    constraint invitee_identified check (invitee_id is not null or invitee_email is not null)
);

-- One invite per person per meal. Two partial indexes rather than one constraint,
-- because an unclaimed invite has a null invitee_id and nulls do not collide.
create unique index meal_invites_meal_user_idx
    on public.meal_invites (meal_id, invitee_id) where invitee_id is not null;
create unique index meal_invites_meal_email_idx
    on public.meal_invites (meal_id, lower(invitee_email)) where invitee_id is null;
create index meal_invites_invitee_idx on public.meal_invites (invitee_id, status);

-- Eaters: household members whose opinion we track but who have no account — the
-- kids. Without this, moving the store to Postgres would quietly have dropped the
-- app's original feature, since only invited adults have an auth.users row.
create table public.eaters (
    id         uuid primary key default gen_random_uuid(),
    owner_id   uuid        not null references auth.users (id) on delete cascade,
    name       text        not null check (length(btrim(name)) > 0),
    emoji      text        not null default '🧒',
    is_active  boolean     not null default true,
    sort_index integer     not null default 0,
    created_at timestamptz not null default now()
);

create index eaters_owner_idx on public.eaters (owner_id, sort_index);

-- Ratings. 0 = not a fan, 1 = it was ok, 2 = loved it — the same scale the client's
-- Reaction enum uses, so the suggestion engine needs no translation.
--
-- A verdict comes from exactly one of two places: an invited account holder
-- (rater_id) or a household member the cook rated on their behalf (eater_id).
create table public.meal_ratings (
    id         uuid primary key default gen_random_uuid(),
    meal_id    uuid        not null references public.meals (id) on delete cascade,
    rater_id   uuid        references auth.users (id) on delete cascade,
    eater_id   uuid        references public.eaters (id) on delete cascade,
    reaction   smallint    not null check (reaction between 0 and 2),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint one_rating_source check (
        (rater_id is not null and eater_id is null)
     or (rater_id is null and eater_id is not null)
    )
);

create unique index meal_ratings_meal_rater_idx
    on public.meal_ratings (meal_id, rater_id) where rater_id is not null;
create unique index meal_ratings_meal_eater_idx
    on public.meal_ratings (meal_id, eater_id) where eater_id is not null;
create index meal_ratings_meal_idx on public.meal_ratings (meal_id);

-- The inbox. Every row here is something a user should see; inserting one is also
-- what the database webhook watches to fan out a push notification.
create table public.notifications (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid        not null references auth.users (id) on delete cascade,
    meal_id    uuid        references public.meals (id) on delete cascade,
    kind       text        not null check (kind in ('rating_request', 'rating_received')),
    title      text        not null,
    body       text        not null,
    read_at    timestamptz,
    created_at timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- APNs device tokens.
create table public.device_tokens (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid        not null references auth.users (id) on delete cascade,
    apns_token  text        not null,
    environment text        not null default 'sandbox'
                    check (environment in ('sandbox', 'production')),
    updated_at  timestamptz not null default now(),
    unique (user_id, apns_token)
);

-- ===========================================================================
-- 3. RLS helpers
--
-- Plain `create function`, never `create or replace`. Postgres is explicit that
-- replacing a function leaves its ownership and permissions alone — and both of
-- these are SECURITY DEFINER, meaning "run as the owner". Owner is precisely the
-- property a replace will not update, so replacing a stranger's function of the
-- same name would silently adopt it and then run this RLS-bypassing body as
-- whoever owned the original. Section 1 drops them first; a collision here is
-- something that should stop the deploy.
--
-- SECURITY DEFINER for a second reason: a policy on `meals` that queries
-- `meal_invites`, whose own policy queries `meals`, recurses forever. Running the
-- lookup as definer skips RLS inside the function and breaks the cycle. They take
-- an id and return a boolean, so they leak nothing beyond "may I see this row",
-- which the caller is about to learn anyway.
-- ===========================================================================

create function public.is_meal_participant(p_meal_id uuid)
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
    );
$$;

create function public.can_read_dish(p_dish_id uuid)
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
    );
$$;

-- Revoke from PUBLIC then grant to exactly who needs it. A new function's EXECUTE
-- defaults to PUBLIC, which includes `anon` — so omitting this would leave the
-- pre-login role able to call an RLS-bypassing helper.
revoke execute on function public.is_meal_participant(uuid) from public;
revoke execute on function public.can_read_dish(uuid)       from public;
grant  execute on function public.is_meal_participant(uuid) to authenticated;
grant  execute on function public.can_read_dish(uuid)       to authenticated;

-- ===========================================================================
-- 4. Row level security
--
-- Deny by default. These policies are the only way data leaves the database.
-- ===========================================================================

alter table public.profiles       enable row level security;
alter table public.dishes         enable row level security;
alter table public.meals          enable row level security;
alter table public.meal_invites   enable row level security;
alter table public.eaters         enable row level security;
alter table public.meal_ratings   enable row level security;
alter table public.notifications  enable row level security;
alter table public.device_tokens  enable row level security;

-- Profiles ------------------------------------------------------------------
-- Readable by any signed-in user: to show "Vidar loved it" you need his name, and
-- the table holds nothing more sensitive than that.
create policy profiles_select on public.profiles
    for select to authenticated using (true);

create policy profiles_insert_own on public.profiles
    for insert to authenticated with check (id = auth.uid());

create policy profiles_update_own on public.profiles
    for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Dishes --------------------------------------------------------------------
-- The `owner_id = auth.uid()` branch is not redundant with can_read_dish: it is
-- what makes INSERT ... RETURNING work. can_read_dish is STABLE, so mid-statement
-- it sees the snapshot from before the insert and cannot find the new row, which
-- would fail the RETURNING read that supabase-swift's .insert().select() performs.
-- Comparing the column directly has no such blind spot, and short-circuits the
-- common case before any function call.
create policy dishes_select on public.dishes
    for select to authenticated using (
        owner_id = auth.uid() or public.can_read_dish(id)
    );

create policy dishes_insert_own on public.dishes
    for insert to authenticated with check (owner_id = auth.uid());

create policy dishes_update_own on public.dishes
    for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy dishes_delete_own on public.dishes
    for delete to authenticated using (owner_id = auth.uid());

-- Meals ---------------------------------------------------------------------
create policy meals_select on public.meals
    for select to authenticated using (
        created_by = auth.uid() or public.is_meal_participant(id)
    );

-- You may only attach a meal to a dish you own.
create policy meals_insert_own on public.meals
    for insert to authenticated with check (
        created_by = auth.uid()
        and exists (select 1 from public.dishes d where d.id = dish_id and d.owner_id = auth.uid())
    );

create policy meals_update_own on public.meals
    for update to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());

create policy meals_delete_own on public.meals
    for delete to authenticated using (created_by = auth.uid());

-- Invites -------------------------------------------------------------------
create policy meal_invites_select on public.meal_invites
    for select to authenticated using (inviter_id = auth.uid() or invitee_id = auth.uid());

create policy meal_invites_insert on public.meal_invites
    for insert to authenticated with check (
        inviter_id = auth.uid()
        and exists (select 1 from public.meals m where m.id = meal_id and m.created_by = auth.uid())
    );

-- The invitee may respond; the inviter may correct the row.
create policy meal_invites_update on public.meal_invites
    for update to authenticated
    using (invitee_id = auth.uid() or inviter_id = auth.uid())
    with check (invitee_id = auth.uid() or inviter_id = auth.uid());

create policy meal_invites_delete on public.meal_invites
    for delete to authenticated using (inviter_id = auth.uid());

-- Eaters --------------------------------------------------------------------
-- Owner manages them. Participants of a meal may read the cook's household
-- members, otherwise an invitee would see "someone loved it" with no name.
create policy eaters_select on public.eaters
    for select to authenticated using (
        owner_id = auth.uid()
        or exists (
            select 1
            from public.meal_invites i
            join public.meals m on m.id = i.meal_id
            where i.invitee_id = auth.uid() and m.created_by = public.eaters.owner_id
        )
    );

create policy eaters_insert_own on public.eaters
    for insert to authenticated with check (owner_id = auth.uid());

create policy eaters_update_own on public.eaters
    for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy eaters_delete_own on public.eaters
    for delete to authenticated using (owner_id = auth.uid());

-- Ratings -------------------------------------------------------------------
create policy meal_ratings_select on public.meal_ratings
    for select to authenticated using (public.is_meal_participant(meal_id));

-- Two legitimate writes: your own verdict on a meal you are part of, or a verdict
-- you record for one of your own household members.
create policy meal_ratings_insert on public.meal_ratings
    for insert to authenticated with check (
        public.is_meal_participant(meal_id)
        and (
            rater_id = auth.uid()
            or exists (select 1 from public.eaters e where e.id = eater_id and e.owner_id = auth.uid())
        )
    );

create policy meal_ratings_update on public.meal_ratings
    for update to authenticated
    using (
        rater_id = auth.uid()
        or exists (select 1 from public.eaters e where e.id = eater_id and e.owner_id = auth.uid())
    )
    with check (
        rater_id = auth.uid()
        or exists (select 1 from public.eaters e where e.id = eater_id and e.owner_id = auth.uid())
    );

create policy meal_ratings_delete on public.meal_ratings
    for delete to authenticated using (
        rater_id = auth.uid()
        or exists (select 1 from public.eaters e where e.id = eater_id and e.owner_id = auth.uid())
    );

-- Notifications -------------------------------------------------------------
-- No insert policy: rows are only ever created by the SECURITY DEFINER triggers,
-- so a client cannot fabricate a notification for somebody else's inbox.
create policy notifications_select_own on public.notifications
    for select to authenticated using (user_id = auth.uid());

create policy notifications_update_own on public.notifications
    for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy notifications_delete_own on public.notifications
    for delete to authenticated using (user_id = auth.uid());

-- Device tokens -------------------------------------------------------------
create policy device_tokens_all_own on public.device_tokens
    for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ===========================================================================
-- 5. Storage
--
-- This section is the reason the squash happened. `storage.objects` and
-- `storage.buckets` belong to Supabase, not to this app, so anything we put there
-- outlives every cleanup of our own tables — and anything already there when we
-- arrive is invisible to a migration that only knows how to create.
-- ===========================================================================

-- Assert the bucket's settings; do not merely create it. The old version used
-- `on conflict (id) do nothing`, so on the hosted project — where a *public*
-- `meal-photos` bucket already existed from an unrelated app — the insert hit the
-- conflict, did nothing, and left every meal photo world-readable behind a schema
-- that believed it had made them private.
--
-- Every column the app depends on is named. `public` is the one that bit us, but a
-- pre-existing bucket with a small `file_size_limit` or a restrictive
-- `allowed_mime_types` would reject the client's 1600px JPEGs at runtime with no
-- migration ever complaining.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('meal-photos', 'meal-photos', false, 10485760, array['image/jpeg'])
on conflict (id) do update
    set name              = excluded.name,
        public            = excluded.public,
        file_size_limit   = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- Policies on a table with RLS disabled are stored, shown in the dashboard, and
-- enforce precisely nothing. Supabase enables it on storage.objects by default and
-- we do not own that table, so this asserts rather than sets — a deploy that
-- silently produced unenforced photo policies is worth stopping.
do $$
begin
    if not (select relrowsecurity from pg_class where oid = 'storage.objects'::regclass) then
        raise exception
            'RLS is disabled on storage.objects — the meal-photos policies below would not be enforced';
    end if;
end $$;

-- The regex guard matters: without it a path whose first segment is not a uuid
-- makes the ::uuid cast raise, and a raising policy is a broken policy.
create policy meal_photos_read on storage.objects
    for select to authenticated
    using (
        bucket_id = 'meal-photos'
        and split_part(name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        and public.is_meal_participant(split_part(name, '/', 1)::uuid)
    );

create policy meal_photos_write on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'meal-photos'
        and split_part(name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        and exists (
            select 1 from public.meals m
             where m.id = split_part(name, '/', 1)::uuid
               and m.created_by = auth.uid()
        )
    );

create policy meal_photos_delete on storage.objects
    for delete to authenticated
    using (
        bucket_id = 'meal-photos'
        and split_part(name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        and exists (
            select 1 from public.meals m
             where m.id = split_part(name, '/', 1)::uuid
               and m.created_by = auth.uid()
        )
    );

-- ===========================================================================
-- 6. Triggers
--
-- Everything that happens automatically: profile creation, claiming invites
-- addressed to an email before that person had an account, and filling the inbox.
-- All SECURITY DEFINER, because they write rows the caller may not write directly.
-- ===========================================================================

-- New auth user -> profile, and adopt any invites addressed to their email.
--
-- Claiming only sets invitee_id; the notification is left to the invite trigger
-- below, so there is exactly one place that creates a rating_request.
create function public.handle_new_user()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
begin
    insert into public.profiles (id, display_name)
    values (
        new.id,
        coalesce(
            nullif(new.raw_user_meta_data ->> 'full_name', ''),
            split_part(coalesce(new.email, ''), '@', 1),
            ''
        )
    )
    -- Correct as written, unlike the bucket above: profiles.id cascades from
    -- auth.users, so the only reachable conflict is this trigger firing twice for
    -- one user, where keeping their existing display name is the right answer.
    on conflict (id) do nothing;

    if new.email is not null then
        update public.meal_invites
           set invitee_id = new.id
         where invitee_id is null
           and lower(invitee_email) = lower(new.email);
    end if;

    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Links an invite to an account that *already exists*.
--
-- `handle_new_user` claims pending invites, but only on INSERT into auth.users —
-- only when the invited address signs up after being invited. Nothing handled the
-- opposite and more common order: inviting somebody who already has an account.
-- That invite kept invitee_id null forever, and everything downstream keys off it:
-- notify_invitee returned early so no notification existed, meal_invites_select
-- never matched so the invitee could not see the invite, is_meal_participant was
-- false so they could not read the meal or dish, and meal_ratings_insert refused
-- their rating with 42501. The invite was accepted and then silently did nothing.
--
-- The client cannot fix this: `profiles` holds no email and no client role may read
-- auth.users. A trigger rather than an RPC keeps it off the API surface, so this
-- adds no account-enumeration oracle — the caller learns nothing it did not supply.
--
-- BEFORE INSERT, so the AFTER trigger below sees the resolved invitee_id on the
-- same statement and files the inbox entry itself.
create function public.link_invitee_by_email()
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

create trigger meal_invites_link_invitee
    before insert on public.meal_invites
    for each row execute function public.link_invitee_by_email();

-- Invite -> inbox entry. Fires both when an invite is created for a known user and
-- when an email-only invite is later claimed, but never twice for the same invite,
-- and never for inviting yourself.
create function public.notify_invitee()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_dish_name text;
begin
    if new.invitee_id is null then
        return new;
    end if;

    -- Already notified when the row was first linked to this user.
    if tg_op = 'UPDATE' and old.invitee_id is not null then
        return new;
    end if;

    if new.invitee_id = new.inviter_id then
        return new;
    end if;

    select d.name
      into v_dish_name
      from public.meals m
      join public.dishes d on d.id = m.dish_id
     where m.id = new.meal_id;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        new.invitee_id,
        new.meal_id,
        'rating_request',
        'How was it?',
        coalesce(v_dish_name, 'A meal') || ' is waiting for your rating.'
    );

    return new;
end;
$$;

create trigger meal_invites_notify
    after insert or update of invitee_id on public.meal_invites
    for each row execute function public.notify_invitee();

-- Rating -> tell whoever cooked it.
--
-- The guard asks "is the person who *recorded* this the cook", not "is the rater
-- the cook". rater_id is null for a household member's verdict, and `uuid = null`
-- is null rather than true — so the older comparison never fired on that path and
-- every verdict a cook entered for their own kid filed a notification in the cook's
-- own inbox. Seeding a few months of history produced 42 of them.
--
-- Comparing owners also keeps the case that was being reached for: a guest at the
-- table may record their own child's verdict on the cook's meal, and the cook
-- should still hear about that one. It also lets the notification name the child,
-- which looking display_name up by a null rater_id never could.
create function public.notify_rating()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_creator   uuid;
    v_dish_name text;
    v_actor     uuid;
    v_who       text;
begin
    select m.created_by, d.name
      into v_creator, v_dish_name
      from public.meals m
      join public.dishes d on d.id = m.dish_id
     where m.id = new.meal_id;

    if v_creator is null then
        return new;
    end if;

    if new.rater_id is not null then
        v_actor := new.rater_id;
        select nullif(p.display_name, '')
          into v_who
          from public.profiles p
         where p.id = new.rater_id;
    else
        -- meal_ratings_insert only permits an eater rating from
        -- eaters.owner_id = auth.uid(), so the owner is by construction whoever
        -- entered it.
        select e.owner_id, nullif(e.name, '')
          into v_actor, v_who
          from public.eaters e
         where e.id = new.eater_id;
    end if;

    -- Your own doing: nothing to report.
    if v_actor is null or v_creator = v_actor then
        return new;
    end if;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        v_creator,
        new.meal_id,
        'rating_received',
        'New rating',
        coalesce(v_who, 'Someone') || ' rated ' || coalesce(v_dish_name, 'a meal') || '.'
    );

    return new;
end;
$$;

create trigger meal_ratings_notify
    after insert or update of reaction on public.meal_ratings
    for each row execute function public.notify_rating();

-- updated_at maintenance.
--
-- `set search_path` was the one thing the old version of this function lacked, and
-- the only advisor warning on the hosted project that named a real gap. Every other
-- function in the old set had it.
--
-- It now covers `dishes` and `meals` as well as `meal_ratings`. Those two are
-- exactly what the README names as blocking any future offline mode — "no
-- updated_at on dishes or meals, no tombstones, so there is nothing to resolve a
-- conflict with". This is the cheap half of that, taken while the file was being
-- rewritten anyway. Tombstones are deliberately not here: they would change delete
-- semantics, every policy and every read path, for a feature with no design yet.
create function public.touch_updated_at()
    returns trigger
    language plpgsql
    set search_path = public, pg_temp
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger dishes_touch
    before update on public.dishes
    for each row execute function public.touch_updated_at();

create trigger meals_touch
    before update on public.meals
    for each row execute function public.touch_updated_at();

create trigger meal_ratings_touch
    before update on public.meal_ratings
    for each row execute function public.touch_updated_at();

-- ===========================================================================
-- 7. Table privileges
--
-- Distinct from RLS and easy to forget: a policy says *which rows* a role may
-- see, a GRANT says whether the role may touch the table at all. Without these,
-- every request fails with 42501 however correct the policies are.
--
-- The revoke first is the point. Granting alone is additive, so "we deliberately
-- withheld INSERT on notifications" only holds if the role did not already have
-- it — and Supabase installs default privileges in `public` granting all of
-- arwdDxtm to anon, authenticated *and* service_role when the creating role is
-- supabase_admin. That is exactly how `anon` came to hold SELECT on all eight
-- tables of the hosted project while the schema believed it had granted nothing.
-- The old set caught that for `anon` and concluded "authenticated is untouched",
-- which was the intent but was never checked. Start from nothing, then grant.
-- ===========================================================================

revoke all privileges on all tables in schema public from anon, authenticated;

grant usage on schema public to anon, authenticated;

-- No DELETE on profiles: a profile is removed by the auth.users cascade, not by
-- its owner, so the app has no reason to hold the privilege.
grant select, insert, update          on public.profiles      to authenticated;
grant select, insert, update, delete  on public.dishes        to authenticated;
grant select, insert, update, delete  on public.meals         to authenticated;
grant select, insert, update, delete  on public.eaters        to authenticated;
grant select, insert, update, delete  on public.meal_invites  to authenticated;
grant select, insert, update, delete  on public.meal_ratings  to authenticated;
grant select, insert, update, delete  on public.device_tokens to authenticated;

-- No INSERT: notifications are only ever written by the SECURITY DEFINER triggers
-- above, so nobody can post an entry into somebody else's inbox.
grant select, update, delete on public.notifications to authenticated;

-- ===========================================================================
-- 8. Lock down `anon`
--
-- Last in the file, deliberately. In the old set this block sat in the middle, so
-- the two functions added by later migrations were created *after* it and were
-- never covered — the revoke could only ever apply to what already existed.
--
-- `anon` is the pre-login role and this app gives it nothing to do: sign-up goes
-- through GoTrue, and handle_new_user is SECURITY DEFINER so it needs no
-- privileges of its own. RLS is meant to be the second line of defence, not the
-- only one.
-- ===========================================================================

revoke all privileges on all tables    in schema public from anon;
revoke all privileges on all sequences in schema public from anon;
revoke all privileges on all routines  in schema public from anon;

-- Stop the same grants reappearing on anything created later by this role. The old
-- version covered only tables and sequences, but a new function's EXECUTE defaults
-- to PUBLIC, which `anon` belongs to.
--
-- This applies to `postgres`, the role migrations run as. It cannot reach
-- `supabase_admin`, whose defaults are the ones that actually grant `anon`
-- everything and which `postgres` is not a member of. The explicit revokes above
-- cover every object that exists now; #10 checks what the deployed project really
-- ends up with rather than assuming this was enough.
alter default privileges in schema public revoke all on tables    from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke all on routines  from anon;
alter default privileges in schema public revoke all on types     from anon;

-- `usage` on the schema is deliberately kept: without it PostgREST cannot resolve
-- names for anon at all and answers with a confusing 404 instead of a clean 401.
grant usage on schema public to anon;
