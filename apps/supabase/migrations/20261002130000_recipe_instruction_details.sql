-- Cook mode (Nom Nom iOS canvas): per-step timers and "For this step" ingredients.
--
-- dishes.instruction_details is an array aligned with dishes.instructions:
--   [{ "minutes": 20 | null, "ingredients": [0, 3] }, …]
-- where "ingredients" are indexes into dishes.ingredients. The app fills it lazily
-- through the analyze-recipe-steps edge function and treats a length mismatch with
-- instructions as stale (the steps were edited since).

alter table public.dishes
    add column instruction_details jsonb;

alter type public.generation_type add value if not exists 'recipe_steps';

insert into public.ai_feature_configs (feature_id, model_name)
values ('analyze-recipe-steps', 'google/gemini-2.5-flash')
on conflict (feature_id) do nothing;
