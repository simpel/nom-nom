import { notFound } from 'next/navigation'
import RelationGraph, { type GraphEdge, type GraphNode } from '@/components/admin/rating-model/RelationGraph'
import { Chip, ModelPage, Panel, modelHref, requireAdmin } from '@/components/admin/rating-model/ModelUI'
import {
  DIMENSION_LABELS, VERDICTS, loadRatingModel, tagTraitId, termsOfferingTag, traitInfo,
} from '@/utils/rating-model'

// One tag: which terms (through which trait) offer it, for which verdicts, and what it
// does to a score.
export default async function TagPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin()
  const { id } = await params
  const { terms, tags, tagUsage } = await loadRatingModel()
  const tag = tags.find(t => t.id === id)
  if (!tag) notFound()

  const traitId = tagTraitId(tag)
  const trait = traitInfo(traitId)
  const carriers = termsOfferingTag(tag, terms)
  const verdicts = VERDICTS.filter(v => tag.verdicts.includes(v.value))
  const kind = !tag.scored ? 'Reason (not scored)' : tag.is_positive ? 'Good' : 'Problem'

  const nodes: GraphNode[] = [
    ...carriers.map(t => ({
      id: `term:${t.id}`, label: t.name, sub: DIMENSION_LABELS[t.dimension], kind: 'term' as const,
      column: 0, href: modelHref.term(t.id),
    })),
    {
      id: `trait:${traitId}`, label: trait?.label ?? traitId, sub: trait?.description, kind: 'trait',
      column: 1, href: modelHref.trait(traitId),
    },
    {
      id: `tag:${id}`, label: tag.label, sub: kind, kind: 'tag', column: 2, focus: true,
      positive: tag.scored ? tag.is_positive : undefined,
    },
    ...verdicts.map(v => ({
      id: `verdict:${v.value}`, label: v.label, sub: `Base ${v.score}`, kind: 'verdict' as const, column: 3,
    })),
  ]
  const edges: GraphEdge[] = [
    ...carriers.map(t => ({ from: `term:${t.id}`, to: `trait:${traitId}` })),
    { from: `trait:${traitId}`, to: `tag:${id}` },
    ...verdicts.map(v => ({ from: `tag:${id}`, to: `verdict:${v.value}` })),
  ]

  return (
    <ModelPage eyebrow={`Tag · ${tag.tag_group}`} title={tag.label} subtitle={`${kind} · id ${tag.id}`}>
      <RelationGraph nodes={nodes} edges={edges} height={Math.max(420, carriers.length * 64 + 80)} />
      <div className="grid gap-6 lg:grid-cols-3">
        <Panel title="Score effect">
          <p className="text-sm text-gray-600">
            {!tag.scored
              ? 'None. It explains a Can’t eat, which always scores 0.'
              : `Counts ${tag.is_positive ? 'for' : 'against'} the meal: tags move a score by up to ${tag.is_positive ? '+' : '−'}2, ` +
                'split by the share of good and problem tags the eater picked.'}
          </p>
        </Panel>
        <Panel title="Offered for" trailing={`${verdicts.length} verdicts`}>
          <div className="flex flex-wrap gap-2">{verdicts.map(v => <Chip key={v.value}>{v.label}</Chip>)}</div>
        </Panel>
        <Panel title="Used" trailing="ratings">
          <div className="text-3xl font-bold tabular-nums">{tagUsage.get(id) ?? 0}</div>
        </Panel>
      </div>
      <Panel title="Offered on" trailing={carriers.length > 0 ? `${carriers.length} terms` : undefined}>
        {carriers.length > 0 ? (
          <div className="flex flex-wrap gap-2">
            {carriers.map(t => <Chip key={t.id} href={modelHref.term(t.id)}>{t.name}</Chip>)}
          </div>
        ) : (
          <p className="text-sm text-gray-500">{trait?.description}.</p>
        )}
      </Panel>
    </ModelPage>
  )
}
