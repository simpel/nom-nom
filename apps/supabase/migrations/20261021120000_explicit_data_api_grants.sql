-- From 2026-10-30 Supabase stops granting Data API access to new tables in `public`
-- automatically. These tables were created relying on that default, so a project,
-- preview branch or `supabase db reset` built from these migrations would hand
-- `authenticated` nothing and every request would fail with 42501.
--
-- Grant exactly what each table's RLS policies allow, and no more: the defaults gave
-- `authenticated` TRUNCATE, REFERENCES and TRIGGER too. `anon` stays at nothing (see
-- the baseline). `service_role` is the edge functions' role and keeps full access.
--
-- Production already has these tables, so for it this only narrows privileges.

revoke all privileges on
  public.ai_feature_configs,
  public.categories,
  public.generation_logs,
  public.ingredient_vocabulary,
  public.meal_score_tweaks,
  public.party_insights,
  public.party_recipe_notes,
  public.party_recommendations,
  public.profile_insights,
  public.rating_tags,
  public.recipe_insights,
  public.recipe_ingredients_canonical,
  public.taxonomy_terms
from anon, authenticated;

grant select, insert, update, delete on public.ai_feature_configs to authenticated;
grant select, insert, update         on public.categories         to authenticated;
grant select, insert, update         on public.taxonomy_terms     to authenticated;
grant select, insert, update, delete on public.party_recipe_notes to authenticated;
grant select, insert, update, delete on public.recipe_insights    to authenticated;

-- Read-only for the app; written by edge functions and triggers.
grant select on
  public.generation_logs,
  public.ingredient_vocabulary,
  public.meal_score_tweaks,
  public.party_insights,
  public.party_recommendations,
  public.profile_insights,
  public.rating_tags,
  public.recipe_ingredients_canonical
to authenticated;

grant select, insert, update, delete on
  public.ai_feature_configs,
  public.categories,
  public.generation_logs,
  public.ingredient_vocabulary,
  public.meal_score_tweaks,
  public.party_insights,
  public.party_recipe_notes,
  public.party_recommendations,
  public.profile_insights,
  public.rating_tags,
  public.recipe_insights,
  public.recipe_ingredients_canonical,
  public.taxonomy_terms
to service_role;
