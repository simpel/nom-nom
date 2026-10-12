import type { SupabaseClient } from '@supabase/supabase-js'
import { ALL_FEATURES } from '@/app/admin/ai-config/features'

/**
 * The model set for `featureId` at /admin/ai-config (public.ai_feature_configs), the web
 * twin of the edge functions' getFeatureModel: the feature's own model, else the default
 * for its kind. There is no model in code; if neither is set this throws.
 */
export async function getFeatureModel(client: SupabaseClient, featureId: string): Promise<string> {
  const feature = ALL_FEATURES.find((f) => f.id === featureId)
  if (!feature) throw new Error(`Unknown AI feature ${featureId}; add it to admin/ai-config/features.ts`)

  const defaultId = `default-${feature.kind}`
  const { data, error } = await client
    .from('ai_feature_configs')
    .select('feature_id, model_name')
    .in('feature_id', [featureId, defaultId])

  if (error) throw new Error(`Cannot read the AI model for ${featureId}: ${error.message}`)

  const model = (id: string) => data?.find((row) => row.feature_id === id)?.model_name
  const resolved = model(featureId) || model(defaultId)
  if (!resolved) throw new Error(`No AI model set for ${featureId} and no ${feature.kind} default; set one at /admin/ai-config`)
  return resolved
}
