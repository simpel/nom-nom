'use client'

import { useState, useTransition } from 'react'
import { updateAiConfig } from './actions'
import { ALL_FEATURES, DEFAULTS } from './features'
import ModelSelect, { type GatewayModel } from './ModelSelect'

type Config = {
  feature_id: string
  model_name: string | null
}

function Row({ name, description, meta, children }: {
  name: string
  description: string
  meta?: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <li className="px-6 py-5 flex items-start justify-between gap-x-6">
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold leading-6 text-gray-900">{name}</p>
        <p className="mt-1 flex text-xs leading-5 text-gray-500">{description}</p>
        {meta}
      </div>
      <div className="flex-shrink-0 w-96">{children}</div>
    </li>
  )
}

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

  const saved = (id: string) => currentConfigs.find(c => c.feature_id === id)?.model_name || ''

  return (
    <form action={handleAction} className="bg-white border rounded-xl shadow-sm overflow-hidden">
      <div className="px-6 py-5 border-b bg-gray-50 flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold leading-6 text-gray-900">Feature Configurations</h2>
          <p className="mt-1 text-sm text-gray-500">
            Models come live from the AI Gateway. A feature without its own model uses the default for its kind.
          </p>
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

      <h3 className="px-6 pt-5 text-xs font-semibold uppercase tracking-wide text-gray-500">Defaults</h3>
      <ul className="divide-y divide-gray-100 border-b">
        {DEFAULTS.map(d => (
          <Row key={d.id} name={d.name} description={d.description}>
            <ModelSelect name={`model-${d.id}`} kind={d.kind} value={saved(d.id)} models={availableModels} />
          </Row>
        ))}
      </ul>

      <h3 className="px-6 pt-5 text-xs font-semibold uppercase tracking-wide text-gray-500">Features</h3>
      <ul className="divide-y divide-gray-100">
        {ALL_FEATURES.map((feature) => {
          const fallback = saved(`default-${feature.kind}`)
          return (
            <Row
              key={feature.id}
              name={feature.name}
              description={feature.description}
              meta={<>
                <code className="mt-2 inline-block text-xs text-gray-400 bg-gray-50 px-2 py-0.5 rounded border">{feature.id}</code>
                <span className="ml-2 text-xs text-gray-400">{feature.source}</span>
              </>}
            >
              <ModelSelect
                name={`model-${feature.id}`}
                kind={feature.kind}
                needsVision={feature.needsVision}
                value={saved(feature.id)}
                models={availableModels}
                fallbackLabel={`Use default (${fallback || 'not set'})`}
              />
            </Row>
          )
        })}
      </ul>
    </form>
  )
}
