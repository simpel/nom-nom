-- party_invites_update previously only let the original inviter or the
-- invitee themselves touch a row. That meant once someone declined (or was
-- removed after accepting), NO party member could ever re-invite them: the
-- unique (party_id, invitee_id/email) index blocks a fresh insert, and the
-- update needed to flip the stale row back to 'pending' was rejected by RLS
-- for anyone but the original inviter. Bring this in line with
-- party_invites_delete, which already lets any current member manage
-- invites on the party.
drop policy if exists party_invites_update on public.party_invites;

create policy party_invites_update on public.party_invites
    for update to authenticated
    using (invitee_id = auth.uid() or inviter_id = auth.uid() or public.is_party_member(party_id))
    with check (invitee_id = auth.uid() or inviter_id = auth.uid() or public.is_party_member(party_id));
