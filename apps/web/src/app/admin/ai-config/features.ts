// Every AI feature whose model is read from public.ai_feature_configs.
// `id` must match the feature id passed to getFeatureModel(): in the edge functions
// (apps/supabase/functions/_shared/ai-config.ts) or on the web (src/utils/ai-config.ts).
// No model lives in code: a feature without its own model uses the default for its kind,
// and both defaults are set on /admin/ai-config.
//
// Embeddings (text-embedding-3-small) are deliberately not here: stored vectors only compare
// with vectors from the same model, so switching it means re-embedding every recipe and
// ingredient. Change it in code with a backfill, not from a dropdown.

export type FeatureKind = 'text' | 'image'

export type AiDefault = {
  /** Row id in ai_feature_configs, `default-<kind>`. */
  id: `default-${FeatureKind}`
  kind: FeatureKind
  name: string
  description: string
}

export type AiFeature = {
  id: string
  name: string
  description: string
  kind: FeatureKind
  /** Only offer models tagged `vision` by the Gateway (the feature sends images). */
  needsVision?: boolean
  /** Where the call is made, shown on the admin page. */
  source: string
}

export const DEFAULTS: AiDefault[] = [
  { id: 'default-text', kind: 'text', name: 'Default text model', description: 'Used by every text feature below that has no model of its own.' },
  { id: 'default-image', kind: 'image', name: 'Default image model', description: 'Used by every image feature below that has no model of its own.' },
]

export const ALL_FEATURES: AiFeature[] = [
  { id: 'parse-recipe', name: 'Recipe Parsing from Photos', description: 'Extracts structured data from uploaded recipe photos.', kind: 'text', needsVision: true, source: 'parse-recipe' },
  { id: 'analyze-recipe-health', name: 'Recipe Health Analysis', description: 'Scores ingredients and generates health verdicts.', kind: 'text', source: 'analyze-recipe-health' },
  { id: 'analyze-recipe-steps', name: 'Cook Mode Steps', description: 'Splits instructions into steps with timers and ingredients.', kind: 'text', source: 'analyze-recipe-steps' },
  { id: 'recipe-tweaks', name: 'Recipe Tweaks', description: 'Suggests tweaks to a recipe based on how it was rated.', kind: 'text', source: 'suggest-recipe-tweaks' },
  { id: 'canonicalize-ingredients', name: 'Ingredient Canonicalization', description: 'Maps raw ingredients to standard database entities.', kind: 'text', source: 'canonicalize-ingredients' },
  { id: 'taxonomy-traits', name: 'Rating Traits', description: 'Describes the taste traits of cuisines and recipe kinds for the rating model.', kind: 'text', source: '_shared/rating-traits' },
  { id: 'party-recommendations', name: 'Party Recipe Recommendations', description: 'Recommends recipes for a dinner party.', kind: 'text', source: 'recommend-party-recipes' },
  { id: 'party-insights', name: 'Party Taste Profiles', description: 'Generates group taste summaries and member matches.', kind: 'text', source: 'web: utils/party-insights' },
  { id: 'profile-insights', name: 'Personal Taste Profiles', description: "Summarises one person's tastes and suggests meals.", kind: 'text', source: 'web: api/admin/trigger-profile-insight' },
  { id: 'recipe-photo-brief', name: 'Photo Brief', description: 'Turns a recipe or category into the food description the photo model draws. Used for recipe, category and meal photos.', kind: 'text', source: 'generate-recipe-photo, generate-meal-photo' },
  { id: 'generate-recipe-photo', name: 'Recipe / Category Photo', description: 'Generates cover photos. The prompt is written for Meta Muse Image; other models may need prompt changes.', kind: 'image', source: 'generate-recipe-photo' },
  { id: 'generate-meal-photo', name: 'Meal Photo', description: 'Generates the photo of a meal: the recipe plated and laid for eating. Follows the image default unless set.', kind: 'image', source: 'generate-meal-photo' },
]
