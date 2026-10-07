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

    -- Delete any existing unread or read party invite notifications for this user and party
    delete from public.notifications 
    where user_id = new.invitee_id 
      and party_id = new.party_id 
      and kind = 'party_invite';

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
