import { notFound } from 'next/navigation'
import RelationGraph, { type GraphEdge, type GraphNode } from '@/components/admin/rating-model/RelationGraph'
import { Chip, ModelPage, Panel, TagChip, modelHref, requireAdmin } from '@/components/admin/rating-model/ModelUI'
import {
  ANY_TRAIT, COOKED_TRAIT, DIMENSION_LABELS, TRAIT_DIMENSIONS, VERDICTS,
  loadRatingModel, loadTermDishes, tagFitsTraits, tagTraitId, traitInfo,
} from '@/utils/rating-model'

const MAX_DISHES_IN_GRAPH = 20

// One taxonomy term: the recipes that use it, the traits it carries, and the tags a
// meal of it offers per verdict (on its own; a recipe adds its other term's traits).
export default async function TermPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin()
  const { id } = await params
  const [{ terms, tags }, dishes] = await Promise.all([loadRatingModel(), loadTermDishes(id)])
  const term = terms.find(t => t.id === id)
  if (!term) notFound()

  const carriesTraits = (TRAIT_DIMENSIONS as readonly string[]).includes(term.dimension)
  const traitIds = carriesTraits
    ? [...term.rating_traits, ...(term.rating_traits.includes('raw') ? [] : [COOKED_TRAIT.id]), ANY_TRAIT.id]
    : []
  const offered = carriesTraits ? tags.filter(t => tagFitsTraits(t, term.rating_traits)) : []

  const nodes: GraphNode[] = [
    ...dishes.slice(0, MAX_DISHES_IN_GRAPH).map(d => ({
      id: `dish:${d.id}`, label: d.name, kind: 'dish' as const, column: 0, href: modelHref.dish(d.id),
    })),
    { id: `term:${id}`, label: term.name, sub: DIMENSION_LABELS[term.dimension], kind: 'term', column: 1, focus: true },
    ...traitIds.map(tr => ({
      id: `trait:${tr}`, label: traitInfo(tr)?.label ?? tr, sub: traitInfo(tr)?.description,
      kind: 'trait' as const, column: 2, href: modelHref.trait(tr),
    })),
    ...offered.map(t => ({
      id: `tag:${t.id}`, label: t.label, kind: 'tag' as const, column: 3,
      href: modelHref.tag(t.id), positive: t.scored ? t.is_positive : undefined,
    })),
  ]
  const edges: GraphEdge[] = [
    ...dishes.slice(0, MAX_DISHES_IN_GRAPH).map(d => ({ from: `dish:${d.id}`, to: `term:${id}` })),
    ...traitIds.map(tr => ({ from: `term:${id}`, to: `trait:${tr}` })),
    ...offered.map(t => ({ from: `trait:${tagTraitId(t)}`, to: `tag:${t.id}` })),
  ]

  return (
    <ModelPage
      eyebrow={DIMENSION_LABELS[term.dimension] ?? term.dimension}
      title={term.name}
      subtitle={term.aliases.length > 0 ? `Also matched as: ${term.aliases.join(', ')}` : undefined}
    >
      <RelationGraph nodes={nodes} edges={edges} height={Math.max(480, nodes.length * 18)} />

      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title="Traits" trailing={carriesTraits ? `${term.rating_traits.length}` : 'n/a'}>
          {!carriesTraits ? (
            <p className="text-sm text-gray-500">Cuisines carry no traits: they never change which tags a meal offers.</p>
          ) : term.rating_traits.length === 0 ? (
            <p className="text-sm text-gray-500">None. Meals of it offer only the tags for any dish and any cooked dish.</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {term.rating_traits.map(tr => <Chip key={tr} tone="indigo" href={modelHref.trait(tr)}>{traitInfo(tr)?.label ?? tr}</Chip>)}
            </div>
          )}
        </Panel>
        <Panel title="Recipes" trailing={`${dishes.length}`}>
          {dishes.length === 0 ? (
            <p className="text-sm text-gray-500">No recipe uses this term yet.</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {dishes.map(d => <Chip key={d.id} href={modelHref.dish(d.id)}>{d.name}</Chip>)}
            </div>
          )}
        </Panel>
      </div>

      {carriesTraits && (
        <Panel title="Tags offered, per verdict" trailing="from this term alone">
          <table className="w-full text-left text-sm">
            <tbody className="divide-y">
              {VERDICTS.map(v => {
                const list = offered.filter(t => t.verdicts.includes(v.value))
                return (
                  <tr key={v.value}>
                    <td className="w-32 py-2 font-medium">{v.label}</td>
                    <td className="py-2">
                      <span className="flex flex-wrap gap-1">{list.map(t => <TagChip key={t.id} tag={t} />)}</span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </Panel>
      )}
    </ModelPage>
  )
}
