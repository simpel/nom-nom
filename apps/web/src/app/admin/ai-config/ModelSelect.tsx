import type { FeatureKind } from './features'

export type GatewayModel = {
  id: string
  name: string
  owned_by: string
  type?: string
  tags?: string[]
  pricing?: { input?: string; output?: string; image?: string }
}

// The Gateway's model `type` for each kind of feature.
const GATEWAY_TYPE: Record<FeatureKind, string> = { text: 'language', image: 'image' }

function price(model: GatewayModel): string {
  const p = model.pricing
  if (p?.image) return ` · $${Number(p.image)}/img`
  if (p?.input && p?.output) {
    const perM = (v: string) => `$${+(Number(v) * 1e6).toFixed(2)}`
    return ` · ${perM(p.input)} in / ${perM(p.output)} out per 1M`
  }
  return ''
}

/**
 * A dropdown of the Gateway models a feature can use, grouped by provider. `fallbackLabel`
 * adds a first "use the default" option (saved as no model); without it a model is required.
 */
export default function ModelSelect({
  name,
  kind,
  needsVision,
  value,
  models,
  fallbackLabel,
}: {
  name: string
  kind: FeatureKind
  needsVision?: boolean
  value: string
  models: GatewayModel[]
  fallbackLabel?: string
}) {
  const usable = models.filter(m => m.type === GATEWAY_TYPE[kind] && (!needsVision || m.tags?.includes('vision')))
  const byProvider = usable.reduce((acc, model) => {
    const provider = model.owned_by || 'Other'
    ;(acc[provider] ??= []).push(model)
    return acc
  }, {} as Record<string, GatewayModel[]>)

  return (
    <select
      name={name}
      defaultValue={value}
      required={!fallbackLabel}
      className="block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-black sm:text-sm sm:leading-6"
    >
      {fallbackLabel
        ? <option value="">{fallbackLabel}</option>
        : <option value="" disabled>Select a model</option>}

      {Object.entries(byProvider).sort(([a], [b]) => a.localeCompare(b)).map(([provider, group]) => (
        <optgroup key={provider} label={provider.toUpperCase()}>
          {group.map(model => (
            <option key={model.id} value={model.id}>
              {(model.name || model.id) + price(model)}
            </option>
          ))}
        </optgroup>
      ))}

      {/* Keep a saved model selectable even when the Gateway no longer lists it */}
      {value && !usable.some(m => m.id === value) && (
        <optgroup label="CURRENT (not in Gateway list)">
          <option value={value}>{value}</option>
        </optgroup>
      )}
    </select>
  )
}
