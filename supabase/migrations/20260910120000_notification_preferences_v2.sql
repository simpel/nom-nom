-- ===========================================================================
-- Notification preferences v2 + two missing events (recipe likes, party follows)
--
-- The v1 model was two "push/email/both/off" pickers covering only invites. This
-- moves to: one on/off switch per event, plus two global delivery-channel
-- switches (push, email). The in-app inbox is unaffected — every trigger still
-- writes its `notifications` row unconditionally; the prefs only gate what
-- `notify-invitees` fans out over APNs and Resend.
--
-- The v1 columns (`notify_push_*`, `notify_email_*`) are kept, not dropped: a
-- build carrying the old schema may still be in review or briefly live. Nothing
-- writes them after this; a later migration removes them once that build is dead.
-- ===========================================================================

-- 1. notifications: let party/recipe events carry a deep-link target the way
--    meal events already carry meal_id.
alter table public.notifications
    add column if not exists party_id uuid references public.parties (id) on delete cascade,
    add column if not exists dish_id  uuid references public.dishes  (id) on delete cascade;

-- 2. Two new kinds.
alter table public.notifications
    drop constraint if exists notifications_kind_check;

alter table public.notifications
    add constraint notifications_kind_check
    check (kind in (
        'rating_request', 'rating_received',
        'party_invite', 'party_joined', 'party_followed',
        'recipe_liked'
    ));

-- 3. Per-event switches + delivery channels.
alter table public.profiles
    add column if not exists notify_meal_invite    boolean not null default true,
    add column if not exists notify_meal_rating    boolean not null default true,
    add column if not exists notify_party_invite   boolean not null default true,
    add column if not exists notify_party_activity boolean not null default true,
    add column if not exists notify_recipe_like    boolean not null default true,
    add column if not exists notify_via_push       boolean not null default true,
    add column if not exists notify_via_email      boolean not null default false;

-- Carry over whatever the v1 users had actually changed. Email starts off for
-- everyone (v1 defaulted it on for invites, but a clean launch opts in).
update public.profiles set
    notify_meal_invite  = (notify_push_meal_invite  or notify_email_meal_invite),
    notify_party_invite = (notify_push_party_invite or notify_email_party_invite),
    notify_via_push     = (notify_push_meal_invite  or notify_push_party_invite);

-- 4. Recipe likes -> notify the recipe owner.
create or replace function public.notify_recipe_favorited()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_owner     uuid;
    v_dish_name text;
    v_liker     text;
begin
    select d.owner_id, d.name
      into v_owner, v_dish_name
      from public.dishes d
     where d.id = new.recipe_id;

    -- Owner gone, or you liked your own recipe: nothing to report.
    if v_owner is null or v_owner = new.user_id then
        return new;
    end if;

    select coalesce(
        nullif(pr.display_name, ''),
        nullif(btrim(pr.first_name || ' ' || coalesce(pr.last_name, '')), ''),
        'Someone'
    )
      into v_liker
      from public.profiles pr
     where pr.id = new.user_id;

    insert into public.notifications (user_id, dish_id, kind, title, body)
    values (
        v_owner,
        new.recipe_id,
        'recipe_liked',
        'New like',
        coalesce(v_liker, 'Someone') || ' liked ' || coalesce(v_dish_name, 'your recipe') || '.'
    );

    return new;
end;
$$;

drop trigger if exists recipe_favorites_notify on public.recipe_favorites;

create trigger recipe_favorites_notify
    after insert on public.recipe_favorites
    for each row execute function public.notify_recipe_favorited();

-- 5. Party follows -> notify the party creator.
create or replace function public.notify_party_followed()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_creator    uuid;
    v_party_name text;
    v_follower   text;
begin
    select p.created_by, p.name
      into v_creator, v_party_name
      from public.parties p
     where p.id = new.party_id;

    if v_creator is null or v_creator = new.user_id then
        return new;
    end if;

    select coalesce(
        nullif(pr.display_name, ''),
        nullif(btrim(pr.first_name || ' ' || coalesce(pr.last_name, '')), ''),
        'Someone'
    )
      into v_follower
      from public.profiles pr
     where pr.id = new.user_id;

    insert into public.notifications (user_id, party_id, kind, title, body)
    values (
        v_creator,
        new.party_id,
        'party_followed',
        'New follower',
        coalesce(v_follower, 'Someone') || ' is now following ' || coalesce(v_party_name, 'your dinner party') || '.'
    );

    return new;
end;
$$;

drop trigger if exists party_followers_notify on public.party_followers;

create trigger party_followers_notify
    after insert on public.party_followers
    for each row execute function public.notify_party_followed();

-- 6. Backfill party_id on the existing party events so they deep-link too.
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

    insert into public.notifications (user_id, party_id, meal_id, kind, title, body)
    values (
        new.invitee_id,
        new.party_id,
        null,
        'party_invite',
        'Dinner Party Invitation',
        coalesce(v_inviter_name, 'Someone') || ' invited you to join ' || coalesce(v_party_name, 'a dinner party') || '.'
    );

    return new;
end;
$$;

create or replace function public.notify_party_joined()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_party_name text;
    v_joiner_name text;
    v_creator uuid;
begin
    select name, created_by
      into v_party_name, v_creator
      from public.parties
     where id = new.party_id;

    if v_creator is null or v_creator = new.user_id then
        return new;
    end if;

    select coalesce(
        nullif(pr.display_name, ''),
        nullif(trim(pr.first_name || ' ' || coalesce(pr.last_name, '')), ''),
        'Someone'
    )
      into v_joiner_name
      from public.profiles pr
     where pr.id = new.user_id;

    insert into public.notifications (user_id, party_id, meal_id, kind, title, body)
    values (
        v_creator,
        new.party_id,
        null,
        'party_joined',
        'New Member Joined',
        coalesce(v_joiner_name, 'Someone') || ' joined ' || coalesce(v_party_name, 'your dinner party') || '.'
    );

    return new;
end;
$$;
