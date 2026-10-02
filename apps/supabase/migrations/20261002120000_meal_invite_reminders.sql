-- "Remind Oskar" on the rater sheet (Nom Nom iOS canvas, RaterUnrated artboard).
--
-- Anyone who shares the meal's party can nudge someone who was asked to rate and
-- hasn't yet, at most once a day per invite. A reminder files a fresh
-- 'rating_request' notification, so the existing notifications_push_fanout trigger
-- sends the push (or leaves it in the inbox when the invitee has push off).

alter table public.meal_invites
    add column reminded_at  timestamptz,
    add column remind_count integer not null default 0;

create or replace function public.remind_meal_invite(p_invite_id uuid)
    returns public.meal_invites
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_invite    public.meal_invites;
    v_dish_name text;
    v_last      timestamptz;
begin
    select * into v_invite from public.meal_invites where id = p_invite_id for update;
    if not found then
        raise exception 'invite not found' using errcode = 'P0002';
    end if;

    -- Same audience as the insert policy: the cook or anyone sharing the meal's party.
    if not (
        exists (select 1 from public.meals m where m.id = v_invite.meal_id and m.created_by = auth.uid())
        or public.shares_meal_party(v_invite.meal_id)
    ) then
        raise exception 'not allowed' using errcode = '42501';
    end if;

    if v_invite.invitee_id is null or v_invite.status <> 'pending' then
        raise exception 'nothing to remind' using errcode = '22023';
    end if;

    -- Already rated: nothing to nudge.
    if exists (
        select 1 from public.meal_ratings r
         where r.meal_id = v_invite.meal_id and r.rater_id = v_invite.invitee_id
    ) then
        raise exception 'already rated' using errcode = '22023';
    end if;

    v_last := coalesce(v_invite.reminded_at, v_invite.created_at);
    if now() - v_last < interval '24 hours' then
        raise exception 'reminded too recently' using errcode = 'P0001',
            detail = to_char(v_last + interval '24 hours', 'YYYY-MM-DD"T"HH24:MI:SSOF');
    end if;

    update public.meal_invites
       set reminded_at = now(), remind_count = remind_count + 1
     where id = p_invite_id
    returning * into v_invite;

    select d.name
      into v_dish_name
      from public.meals m
      join public.dishes d on d.id = m.dish_id
     where m.id = v_invite.meal_id;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        v_invite.invitee_id,
        v_invite.meal_id,
        'rating_request',
        'Still waiting on you',
        coalesce(v_dish_name, 'A meal') || ' is waiting for your rating.'
    );

    return v_invite;
end;
$$;

revoke execute on function public.remind_meal_invite(uuid) from public;
grant  execute on function public.remind_meal_invite(uuid) to authenticated;
