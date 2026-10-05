import Link from 'next/link'
import RelationGraph, { type GraphEdge, type GraphNode } from '@/components/admin/rating-model/RelationGraph'
import { Chip, ModelPage, Panel, TagChip, VerdictList, modelHref, requireAdmin } from '@/components/admin/rating-model/ModelUI'
import {
  ANY_TRAIT, COOKED_TRAIT, DIMENSION_LABELS, TRAITS, loadRatingModel, tagTraitId, traitTerms,
} from '@/utils/rating-model'

// Every option in the rating model and how it connects: dish kinds and cooking methods
// carry traits, traits decide which tags a meal offers.
export default async function RatingModelPage() {
  await requireAdmin()
  const { terms, tags, dishCounts, tagUsage } = await loadRatingModel()
  const carriers = traitTerms(terms)
  const traitNodes = [...TRAITS, COOKED_TRAIT, ANY_TRAIT]

  const nodes: GraphNode[] = [
    ...carriers.map(t => ({
      id: `term:${t.id}`, label: t.name, sub: DIMENSION_LABELS[t.dimension], kind: 'term' as const,
      column: 0, href: modelHref.term(t.id),
    })),
    ...traitNodes.map(t => ({
      id: `trait:${t.id}`, label: t.label, sub: t.description, kind: 'trait' as const,
      column: 1, href: modelHref.trait(t.id),
    })),
    ...tags.map(t => ({
      id: `tag:${t.id}`, label: t.label, sub: t.scored ? undefined : 'Not scored', kind: 'tag' as const,
      column: 2, href: modelHref.tag(t.id), positive: t.scored ? t.is_positive : undefined,
    })),
  ]
  const edges: GraphEdge[] = [
    ...carriers.flatMap(t => t.rating_traits.map(tr => ({ from: `term:${t.id}`, to: `trait:${tr}` }))),
    ...tags.map(t => ({ from: `trait:${tagTraitId(t)}`, to: `tag:${t.id}` })),
  ]

  const untraited = carriers.filter(t => t.rating_traits.length === 0)

  return (
    <ModelPage
      eyebrow="Ratings"
      title="Rating model"
      subtitle="Dish kinds and cooking methods carry traits; traits decide which “what stood out” tags a meal offers. Click any box."
      back={null}
    >
      <RelationGraph nodes={nodes} edges={edges} height={720} maxRows={10} />

      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title="Traits" trailing={`${TRAITS.length} + 2 built in`}>
          <ul className="divide-y">
            {traitNodes.map(t => {
              const termCount = carriers.filter(c => c.rating_traits.includes(t.id)).length
              const tagCount = tags.filter(tag => tagTraitId(tag) === t.id).length
              return (
                <li key={t.id} className="flex items-center justify-between gap-4 py-2">
                  <div>
                    <Link href={modelHref.trait(t.id)} className="font-medium hover:underline">{t.label}</Link>
                    <div className="text-xs text-gray-500">{t.description}</div>
                  </div>
                  <div className="whitespace-nowrap text-sm text-gray-500">
                    {t.id === ANY_TRAIT.id || t.id === COOKED_TRAIT.id ? 'all' : termCount} terms · {tagCount} tags
                  </div>
                </li>
              )
            })}
          </ul>
        </Panel>

        <Panel title="Terms without traits" trailing={`${untraited.length}`}>
          {untraited.length === 0 ? (
            <p className="text-sm text-gray-500">Every dish kind and cooking method has traits.</p>
          ) : (
            <>
              <p className="mb-3 text-sm text-gray-500">These only offer the tags for any dish and any cooked dish.</p>
              <div className="flex flex-wrap gap-2">
                {untraited.map(t => <Chip key={t.id} href={modelHref.term(t.id)}>{t.name}</Chip>)}
              </div>
            </>
          )}
        </Panel>
      </div>

      <Panel title="Tags" trailing={`${tags.length}`}>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-xs uppercase tracking-wider text-gray-500">
              <tr><th className="py-2">Tag</th><th>Kind</th><th>Trait</th><th>Group</th><th>Verdicts</th><th className="text-right">Used</th></tr>
            </thead>
            <tbody className="divide-y">
              {tags.map(t => (
                <tr key={t.id}>
                  <td className="py-2"><TagChip tag={t} /></td>
                  <td className="text-gray-600">{!t.scored ? 'Reason' : t.is_positive ? 'Good' : 'Problem'}</td>
                  <td><Chip tone="indigo" href={modelHref.trait(tagTraitId(t))}>{tagTraitId(t)}</Chip></td>
                  <td className="text-gray-600">{t.tag_group}</td>
                  <td><VerdictList verdicts={t.verdicts} /></td>
                  <td className="text-right tabular-nums text-gray-600">{tagUsage.get(t.id) ?? 0}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>

      <div className="grid gap-6 lg:grid-cols-3">
        {Object.keys(DIMENSION_LABELS).map(dim => {
          const list = terms.filter(t => t.dimension === dim)
          return (
            <Panel key={dim} title={`${DIMENSION_LABELS[dim]}s`} trailing={`${list.length}`}>
              <ul className="divide-y text-sm">
                {list.map(t => (
                  <li key={t.id} className="flex items-center justify-between gap-2 py-1.5">
                    <Link href={modelHref.term(t.id)} className="hover:underline">{t.name}</Link>
                    <span className="flex flex-wrap justify-end gap-1">
                      {t.rating_traits.map(tr => <Chip key={tr} tone="indigo">{tr}</Chip>)}
                      <span className="tabular-nums text-gray-500">{dishCounts.get(t.id) ?? 0}</span>
                    </span>
                  </li>
                ))}
              </ul>
            </Panel>
          )
        })}
      </div>
    </ModelPage>
  )
}
