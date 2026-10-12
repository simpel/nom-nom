'use server'

import { createClient } from '@/utils/supabase/server'
import { revalidatePath } from 'next/cache'
import { ALL_FEATURES, DEFAULTS } from './features'

const FEATURE_IDS = new Set(ALL_FEATURES.map(f => f.id))
const DEFAULT_IDS = new Set<string>(DEFAULTS.map(d => d.id))

export async function updateAiConfig(formData: FormData) {
  const supabase = await createClient()

  // The form holds `model-<id>` -> model id. An empty feature value means "use the default".
  const updates: { feature_id: string; model_name: string | null }[] = []

  for (const [key, value] of formData.entries()) {
    if (!key.startsWith('model-')) continue
    const feature_id = key.replace('model-', '')
    const model_name = (value as string) || null

    if (DEFAULT_IDS.has(feature_id)) {
      if (!model_name) return { success: false, error: `Pick a model for ${feature_id}; every feature without its own model uses it.` }
    } else if (!FEATURE_IDS.has(feature_id)) {
      continue
    }
    updates.push({ feature_id, model_name })
  }

  if (updates.length > 0) {
    const { error } = await supabase
      .from('ai_feature_configs')
      .upsert(updates, { onConflict: 'feature_id' })

    if (error) {
      console.error('Failed to update AI configs:', error)
      return { success: false, error: error.message }
    }
  }

  revalidatePath('/admin/ai-config')
  return { success: true }
}
