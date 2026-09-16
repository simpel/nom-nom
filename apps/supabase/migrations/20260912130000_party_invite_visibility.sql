-- Allow a user with a pending invite to see the (possibly private) party
-- they were invited to, so invite links resolve instead of 404ing.
drop policy if exists parties_select on public.parties;

create policy parties_select on public.parties
    for select to authenticated using (
        created_by = auth.uid()
        or public.is_party_member(id)
        or is_public = true
        or exists (
            select 1
            from public.party_invites pi
            where pi.party_id = parties.id
              and pi.status = 'pending'
              and (pi.invitee_id = auth.uid() or pi.invitee_email = auth.email())
        )
    );
