import { createClient } from '@/utils/supabase/server'
import { requireAdmin } from '@/utils/supabase/admin-auth'
import AiConfigForm from './AiConfigForm'

export const dynamic = 'force-dynamic'

async function getAvailableModels() {
  // The model list is public; the key (same names the rest of the web app reads) is optional.
  const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY
    || process.env.AI_GATEWAY_API_KEY || process.env.VERCEL_OIDC_TOKEN

  try {
    const res = await fetch('https://ai-gateway.vercel.sh/v1/models', {
      headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {},
      cache: 'no-store', // always the Gateway's current list
    })

    if (!res.ok) {
      console.error('Failed to fetch AI gateway models:', res.status, await res.text())
      return []
    }

    const json = await res.json()
    return json.data || []
  } catch (error) {
    console.error('Error fetching AI gateway models:', error)
    return []
  }
}

export default async function AiConfigPage() {
  await requireAdmin()
  const supabase = await createClient()

  // 1. Fetch current configs from Postgres
  const { data: configs, error: configError } = await supabase
    .from('ai_feature_configs')
    .select('*')

  // 2. Fetch available models from Vercel AI Gateway
  const availableModels = await getAvailableModels()

  return (
    <div className="max-w-6xl mx-auto px-8 py-10">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 tracking-tight">AI Configuration</h1>
        <p className="mt-2 text-lg text-gray-500">
          Map specific AI models to app features.
        </p>
      </div>

      {configError && (
        <div className="mb-6 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          Could not read the current configuration ({configError.message}). Sign in again before saving.
        </div>
      )}
      {availableModels.length === 0 && (
        <div className="mb-6 rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Could not load the model list from the AI Gateway; only saved models are shown.
        </div>
      )}

      <AiConfigForm 
        availableModels={availableModels} 
        currentConfigs={configs || []} 
      />
    </div>
  )
}
