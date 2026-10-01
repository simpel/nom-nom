'use client'

import { useState, useTransition } from 'react'
import { updateAiConfig } from './actions'

type GatewayModel = {
  id: string
  name: string
  owned_by: string
}

type Config = {
  feature_id: string
  model_name: string
}

const ALL_FEATURES = [
  { id: 'analyze-recipe-health', name: 'Recipe Health Analysis', description: 'Scores ingredients and generates health verdicts.' },
  { id: 'parse-recipe', name: 'Recipe Parsing from Photos', description: 'Extracts structured data from uploaded recipe photos.' },
  { id: 'canonicalize-ingredients', name: 'Ingredient Canonicalization', description: 'Maps raw ingredients to standard database entities.' },
  { id: 'party-insights', name: 'Party Taste Profiles', description: 'Generates group taste recommendations.' },
  { id: 'generate-dish-photo', name: 'Category / Recipe Photo Generation', description: 'Generates cover images (requires image model).' }
]

export default function AiConfigForm({
  availableModels,
  currentConfigs,
}: {
  availableModels: GatewayModel[]
  currentConfigs: Config[]
}) {
  const [isPending, startTransition] = useTransition()
  const [saveMessage, setSaveMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null)

  const handleAction = async (formData: FormData) => {
    setSaveMessage(null)
    startTransition(async () => {
      const result = await updateAiConfig(formData)
      if (result.success) {
        setSaveMessage({ type: 'success', text: 'Configurations saved successfully.' })
      } else {
        setSaveMessage({ type: 'error', text: result.error || 'Failed to save.' })
      }
    })
  }

  // Group models by provider
  const modelsByProvider = availableModels.reduce((acc, model) => {
    const provider = model.owned_by || 'Other'
    if (!acc[provider]) acc[provider] = []
    acc[provider].push(model)
    return acc
  }, {} as Record<string, GatewayModel[]>)

  return (
    <form action={handleAction} className="bg-white border rounded-xl shadow-sm overflow-hidden">
      <div className="px-6 py-5 border-b bg-gray-50 flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold leading-6 text-gray-900">Feature Configurations</h2>
          <p className="mt-1 text-sm text-gray-500">Select the AI model used for each feature in the app.</p>
        </div>
        <button
          type="submit"
          disabled={isPending}
          className="rounded-md bg-black px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-800 disabled:opacity-50"
        >
          {isPending ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

      {saveMessage && (
        <div className={`px-6 py-3 text-sm font-medium border-b ${saveMessage.type === 'success' ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}`}>
          {saveMessage.text}
        </div>
      )}

      <ul className="divide-y divide-gray-100">
        {ALL_FEATURES.map((feature) => {
          const currentConfig = currentConfigs.find(c => c.feature_id === feature.id)
          const defaultValue = currentConfig?.model_name || ''

          return (
            <li key={feature.id} className="px-6 py-5 flex items-start justify-between gap-x-6">
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold leading-6 text-gray-900">{feature.name}</p>
                <p className="mt-1 flex text-xs leading-5 text-gray-500">{feature.description}</p>
                <code className="mt-2 inline-block text-xs text-gray-400 bg-gray-50 px-2 py-0.5 rounded border">{feature.id}</code>
              </div>
              <div className="flex-shrink-0 w-72">
                <select
                  name={`model-${feature.id}`}
                  defaultValue={defaultValue}
                  className="block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-black sm:text-sm sm:leading-6"
                >
                  <option value="" disabled>Select a model</option>
                  
                  {/* We always include Jev option prominently if available, or just from the list */}
                  {Object.entries(modelsByProvider).sort(([a], [b]) => a.localeCompare(b)).map(([provider, models]) => (
                    <optgroup key={provider} label={provider.toUpperCase()}>
                      {models.map(model => (
                        <option key={model.id} value={model.id}>
                          {model.name || model.id}
                        </option>
                      ))}
                    </optgroup>
                  ))}
                  
                  {/* Fallback option in case current DB value isn't in API list */}
                  {defaultValue && !availableModels.some(m => m.id === defaultValue) && (
                    <optgroup label="CURRENT (Not in Gateway)">
                      <option value={defaultValue}>{defaultValue}</option>
                    </optgroup>
                  )}
                </select>
              </div>
            </li>
          )
        })}
      </ul>
    </form>
  )
}
