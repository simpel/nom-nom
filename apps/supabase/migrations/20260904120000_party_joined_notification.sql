-- ===========================================================================
-- Notify party creator when a member joins a dinner party
-- ===========================================================================

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

    -- If the creator is the one joining (initial creation), do not notify
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

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        v_creator,
        null,
        'party_joined',
        'New Member Joined',
        coalesce(v_joiner_name, 'Someone') || ' joined ' || coalesce(v_party_name, 'your dinner party') || '.'
    );

    return new;
end;
$$;

drop trigger if exists party_members_notify on public.party_members;

create trigger party_members_notify
    after insert on public.party_members
    for each row execute function public.notify_party_joined();
