-- Every account belongs to a dinner party: onboarding either creates one or
-- joins one with an invite. An invite reaches people two ways:
--   * the party's invite link (nomnom.casa/invite?party_id=…)
--   * a short invite code typed or pasted in onboarding
-- Both resolve through request_party_invite(), which files a pending invite
-- for the caller. The usual party_invites trigger then drops a party_invite
-- notification in their inbox, where they accept or decline it.

-- 1. Short invite codes. 8 characters from an alphabet without look-alikes
--    (no 0/O, 1/I/L), so a code read aloud or retyped survives.
create or replace function public.generate_party_invite_code()
    returns text
    language plpgsql
    volatile
    set search_path = public, pg_temp
as $$
declare
    v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    v_code text;
begin
    loop
        v_code := '';
        for i in 1..8 loop
            v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
        end loop;
        exit when not exists (select 1 from public.parties where invite_code = v_code);
    end loop;
    return v_code;
end;
$$;

alter table public.parties
    add column if not exists invite_code text;

update public.parties
   set invite_code = public.generate_party_invite_code()
 where invite_code is null;

alter table public.parties
    alter column invite_code set default public.generate_party_invite_code(),
    alter column invite_code set not null;

create unique index if not exists parties_invite_code_idx on public.parties (invite_code);

-- 2. Turn a link or a code into a pending invite for the caller.
--    Returns the party id. A member gets the id back and nothing changes.
create or replace function public.request_party_invite(
    p_party_id uuid default null,
    p_code text default null
)
    returns uuid
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_party public.parties%rowtype;
    v_existing public.party_invites%rowtype;
begin
    if v_uid is null then
        raise exception 'not authenticated' using errcode = '42501';
    end if;

    if p_party_id is not null then
        select * into v_party from public.parties where id = p_party_id;
    elsif p_code is not null then
        select * into v_party
          from public.parties
         where invite_code = upper(regexp_replace(p_code, '[^A-Za-z0-9]', '', 'g'));
    end if;

    if v_party.id is null then
        raise exception 'invite not found' using errcode = 'P0002';
    end if;

    if v_party.created_by = v_uid or public.is_party_member(v_party.id) then
        return v_party.id;
    end if;

    select * into v_existing
      from public.party_invites
     where party_id = v_party.id and invitee_id = v_uid;

    if v_existing.id is not null and v_existing.status = 'pending' then
        return v_party.id;
    end if;

    -- A declined or used invite can't be flipped back without losing the
    -- notification (the trigger only fires on a fresh invitee), so replace it.
    if v_existing.id is not null then
        delete from public.party_invites where id = v_existing.id;
    end if;

    insert into public.party_invites (party_id, inviter_id, invitee_id)
    values (v_party.id, v_party.created_by, v_uid);

    return v_party.id;
end;
$$;

revoke all on function public.request_party_invite(uuid, text) from public, anon;
grant execute on function public.request_party_invite(uuid, text) to authenticated;
