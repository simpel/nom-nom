-- ===========================================================================
-- AI model defaults set from /admin/ai-config, no models in code.
--
-- Two default rows, one per kind of model:
--   default-text   used by every text feature without its own model
--   default-image  used by every image feature without its own model
-- A feature row's model_name is now nullable: null means "use the default".
-- getFeatureModel() (edge functions and web) reads feature then default, and
-- fails loudly when neither is set.
--
-- Feature rows that match the default are cleared so they follow it; any
-- other model picked in the admin stays as that feature's own choice.
-- ===========================================================================

alter table public.ai_feature_configs
    alter column model_name drop not null;

insert into public.ai_feature_configs (feature_id, model_name) values
    ('default-text',  'google/gemini-2.5-flash'),
    ('default-image', 'meta/muse-image-1.0')
on conflict (feature_id) do nothing;

update public.ai_feature_configs f
   set model_name = null,
       updated_at = now()
  from public.ai_feature_configs d
 where f.feature_id not like 'default-%'
   and d.feature_id = case when f.feature_id = 'generate-dish-photo' then 'default-image' else 'default-text' end
   and f.model_name = d.model_name;
