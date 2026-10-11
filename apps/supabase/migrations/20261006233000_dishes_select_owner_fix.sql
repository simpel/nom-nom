-- entity_lifecycle replaced dishes_select with can_read_dish(id) alone. That
-- STABLE function runs on the pre-insert snapshot, so it cannot see a row the
-- same statement just inserted, and INSERT ... RETURNING fails the SELECT
-- policy (403 / 42501). Restore the direct owner check from the baseline.
drop policy if exists dishes_select on public.dishes;
create policy dishes_select on public.dishes
    for select to authenticated using (
        owner_id = auth.uid() or public.can_read_dish(id)
    );
