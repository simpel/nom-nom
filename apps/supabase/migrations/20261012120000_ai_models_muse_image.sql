-- ===========================================================================
-- AI model config: Muse Image for photos, and a row for every AI feature.
--
-- 1. The AI Gateway no longer serves openai/dall-e-3, so every dish photo
--    failed with 404 model_not_found. Photos now use meta/muse-image-1.0; the
--    generate-dish-photo prompts are written for it.
-- 2. Every feature that calls getFeatureModel() gets a row, so /admin/ai-config
--    shows what is actually used. Existing rows (admin choices) are kept.
--    Keep in sync with apps/web/src/app/admin/ai-config/features.ts.
-- 3. Muse returns WebP, so recipe-photos accepts it (category-photos already does).
-- ===========================================================================

update public.ai_feature_configs
   set model_name = 'meta/muse-image-1.0',
       updated_at = now()
 where feature_id = 'generate-dish-photo';

insert into public.ai_feature_configs (feature_id, model_name) values
    ('parse-recipe',             'google/gemini-2.5-flash'),
    ('analyze-recipe-health',    'google/gemini-2.5-flash'),
    ('analyze-recipe-steps',     'google/gemini-2.5-flash'),
    ('recipe-tweaks',            'google/gemini-2.5-flash'),
    ('canonicalize-ingredients', 'google/gemini-2.5-flash'),
    ('taxonomy-traits',          'google/gemini-2.5-flash'),
    ('party-recommendations',    'google/gemini-2.5-flash'),
    ('party-insights',           'google/gemini-2.5-flash'),
    ('profile-insights',         'google/gemini-2.5-flash'),
    ('dish-photo-brief',         'google/gemini-2.5-flash'),
    ('generate-dish-photo',      'meta/muse-image-1.0')
on conflict (feature_id) do nothing;

update storage.buckets
   set allowed_mime_types = array['image/jpeg', 'image/webp']
 where id = 'recipe-photos';
