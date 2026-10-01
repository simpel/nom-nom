import { createClient } from '@/utils/supabase/server'
import AiConfigForm from './AiConfigForm'

export const dynamic = 'force-dynamic'

async function getAvailableModels() {
  const apiKey = process.env.AI_GATEWAY_API_KEY || process.env.VERCEL_OIDC_TOKEN || ''
  
  if (!apiKey) {
    console.warn('No AI_GATEWAY_API_KEY found in environment.')
    return []
  }

  try {
    const res = await fetch('https://ai-gateway.vercel.sh/v1/models', {
      headers: {
        Authorization: `Bearer ${apiKey}`,
      },
      next: { revalidate: 3600 } // cache for an hour
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
  const supabase = await createClient()

  // 1. Fetch current configs from Postgres
  const { data: configs } = await supabase
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

      <AiConfigForm 
        availableModels={availableModels} 
        currentConfigs={configs || []} 
      />
    </div>
  )
}
