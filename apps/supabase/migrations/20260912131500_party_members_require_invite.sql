-- party_members_insert previously allowed any authenticated user to add
-- themselves to any party (user_id = auth.uid() alone satisfied the check),
-- with no verification that they were ever invited. Require a pending
-- invite to self-join; keep the existing-member/creator branches for the
-- server-side trigger (add_party_creator_as_member) which bypasses RLS
-- anyway as a security definer function.
drop policy if exists party_members_insert on public.party_members;

create policy party_members_insert on public.party_members
    for insert to authenticated with check (
        (
            user_id = auth.uid()
            and exists (
                select 1
                from public.party_invites pi
                where pi.party_id = party_members.party_id
                  and pi.invitee_id = auth.uid()
                  and pi.status = 'pending'
            )
        )
        or public.is_party_member(party_id)
        or exists (select 1 from public.parties p where p.id = party_id and p.created_by = auth.uid())
    );
