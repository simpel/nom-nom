-- entity_lifecycle dropped created_by from parties_select. The creator becomes a
-- member only via an AFTER trigger, which is_party_member() (STABLE) cannot see
-- inside the inserting statement, so INSERT ... RETURNING fails the SELECT
-- policy (403 / 42501). Let the creator read the row only inside the transaction
-- that created it (created_at defaults to now(), the transaction start), so a
-- creator who later leaves the party has no access: membership alone decides.
drop policy if exists parties_select on public.parties;
create policy parties_select on public.parties
    for select to authenticated using (
        (created_by = auth.uid() and created_at = now())
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
