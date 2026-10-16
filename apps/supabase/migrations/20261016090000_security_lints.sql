-- Clears three Supabase security-advisor errors.
--
-- 1. recipe_kinds (0010 security_definer_view): run as the caller, so the
--    taxonomy_terms policies apply. taxonomy_terms is world-readable, so no
--    reader loses rows.
-- 2. ingredient_vocabulary (0013 rls_disabled_in_public): shared, non-personal
--    vocabulary. Anyone signed in may read it; only the service role
--    (canonicalize-ingredients) writes it. This also stops clients writing to it
--    through append_ingredient_alias, which runs as the caller.
-- 3. recipe_ingredients_canonical (0013): rows carry a recipe's raw ingredient
--    text, so a row is readable exactly when its recipe is. Only the service
--    role writes it.
--
-- get_flavor_profile aggregates across recipes the viewer may not read (a party
-- member's private recipes), and it ran as the caller. It now runs as definer so
-- its results stay as they were once RLS is on.

alter view public.recipe_kinds set (security_invoker = true);

alter table public.ingredient_vocabulary enable row level security;

create policy ingredient_vocabulary_select on public.ingredient_vocabulary
    for select to authenticated
    using (true);

alter table public.recipe_ingredients_canonical enable row level security;

create policy recipe_ingredients_canonical_select on public.recipe_ingredients_canonical
    for select to authenticated
    using (public.can_read_recipe(recipe_id));

alter function public.get_flavor_profile(text, uuid)
    security definer
    set search_path = public, pg_temp;
