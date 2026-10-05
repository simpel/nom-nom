import { notFound } from 'next/navigation'
import RelationGraph, { type GraphEdge, type GraphNode } from '@/components/admin/rating-model/RelationGraph'
import { Chip, ModelPage, Panel, TagChip, VerdictList, modelHref, requireAdmin } from '@/components/admin/rating-model/ModelUI'
import {
  ANY_TRAIT, COOKED_TRAIT, DIMENSION_LABELS, VERDICTS, loadRatingModel, tagTraitId, traitInfo, traitTerms,
} from '@/utils/rating-model'

// One trait: the terms that carry it, the tags it unlocks, and the verdicts those tags
// are offered for.
export default async function TraitPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin()
  const { id } = await params
  const trait = traitInfo(id)
  if (!trait) notFound()

  const { terms, tags } = await loadRatingModel()
  const builtIn = id === ANY_TRAIT.id || id === COOKED_TRAIT.id
  const carriers = builtIn ? [] : traitTerms(terms).filter(t => t.rating_traits.includes(id))
  const traitTags = tags.filter(t => tagTraitId(t) === id)
  const verdicts = VERDICTS.filter(v => traitTags.some(t => t.verdicts.includes(v.value)))

  const nodes: GraphNode[] = [
    ...carriers.map(t => ({
      id: `term:${t.id}`, label: t.name, sub: DIMENSION_LABELS[t.dimension], kind: 'term' as const,
      column: 0, href: modelHref.term(t.id),
    })),
    { id: `trait:${id}`, label: trait.label, sub: trait.description, kind: 'trait', column: 1, focus: true },
    ...traitTags.map(t => ({
      id: `tag:${t.id}`, label: t.label, kind: 'tag' as const, column: 2,
      href: modelHref.tag(t.id), positive: t.scored ? t.is_positive : undefined,
    })),
    ...verdicts.map(v => ({
      id: `verdict:${v.value}`, label: v.label, sub: `Base ${v.score}`, kind: 'verdict' as const, column: 3,
    })),
  ]
  const edges: GraphEdge[] = [
    ...carriers.map(t => ({ from: `term:${t.id}`, to: `trait:${id}` })),
    ...traitTags.map(t => ({ from: `trait:${id}`, to: `tag:${t.id}` })),
    ...traitTags.flatMap(t => t.verdicts.map(v => ({ from: `tag:${t.id}`, to: `verdict:${v}` }))),
  ]

  return (
    <ModelPage eyebrow="Trait" title={trait.label} subtitle={trait.description}>
      <RelationGraph nodes={nodes} edges={edges} />
      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title="Carried by" trailing={builtIn ? 'built in' : `${carriers.length} terms`}>
          {builtIn ? (
            <p className="text-sm text-gray-500">
              {id === ANY_TRAIT.id
                ? 'Not stored on terms: every meal offers these tags.'
                : 'Not stored on terms: every meal whose dish kind and cooking method do not carry raw.'}
            </p>
          ) : carriers.length === 0 ? (
            <p className="text-sm text-gray-500">No dish kind or cooking method carries this trait yet.</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {carriers.map(t => <Chip key={t.id} href={modelHref.term(t.id)}>{t.name}</Chip>)}
            </div>
          )}
        </Panel>
        <Panel title="Tags it offers" trailing={`${traitTags.length}`}>
          <ul className="divide-y">
            {traitTags.map(t => (
              <li key={t.id} className="flex items-center justify-between gap-4 py-2">
                <TagChip tag={t} />
                <VerdictList verdicts={t.verdicts} />
              </li>
            ))}
          </ul>
        </Panel>
      </div>
    </ModelPage>
  )
}
