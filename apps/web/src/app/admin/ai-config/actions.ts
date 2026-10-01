'use server'

import { createClient } from '@/utils/supabase/server'
import { revalidatePath } from 'next/cache'

export async function updateAiConfig(formData: FormData) {
  const supabase = await createClient()

  // The form will contain a list of feature_id -> model_name pairs
  const updates: { feature_id: string; model_name: string }[] = []

  for (const [key, value] of formData.entries()) {
    if (key.startsWith('model-')) {
      const feature_id = key.replace('model-', '')
      updates.push({
        feature_id,
        model_name: value as string,
      })
    }
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
