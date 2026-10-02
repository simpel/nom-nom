A Card whose label sits inside it: a SectionHeader, an optional quote, then the content. One shape.

**Built from:** Card · SectionHeader · Text (quote).

Merges `apps/ios/NomNom/Core/Components/SectionCard.swift` with the Meal Detail Redesign's NoteCard (NoteCard is removed). React in `components/bundle.js`, styles in `bundle.css`.

## One shape, not two

It used to take `layout: 'stacked' | 'inset'`. `stacked` put the label *above* the card — which is `Section` wrapping a `Card`, already in the system. Two ways to write the same thing, one of them hiding the composition. `layout` is gone; SectionCard is the inside-the-card form only.

| what you want | write |
| --- | --- |
| label inside the card | `<SectionCard title="Household verdict" trailing="4 of 4 rated">` |
| label above the card | `<Section title="Ingredients"><Card>…</Card></Section>` |

Prefer the label inside. A screen of cards each carrying its own label reads as a set of objects; labels floating above them read as a document outline, and the eye has to pair each one with the box below it.

## Axes

| prop | values | default |
| --- | --- | --- |
| `title` | the SectionHeader inside the card | — |
| `trailing` + `trailingVariant` | one figure beside the label; `primary` for a live count | — · `secondary` |
| `uppercase` | `false` for a possessive label ("Joel's note") | `true` |
| `icon` | one glyph before the label | — |
| `variant` | `primary` — tints the card, label `primary-text` semibold | — (`panel`) |
| `quote` | the cook's note | — |

## Rules
- The surface is Card — `panel`, `radius-3xl`, `spacing-5` padding — the same one ScoreCard, RatingList and SheetCard use. SectionCard draws nothing of its own; it only places the label and the quote.
- One SectionHeader per card, with at most one figure beside it.
- `primary`: `primary` at `opacity-10` over `panel`, the same tint as a featured ScoreCard. Reaction colour never tints a card.
- `quote`: italic `serif-xs` in `text-primary`, no quotation marks — the italic is the quote.
- Other content follows the type scale: `serif-sm` for a verdict sentence, `sans-md` `text-secondary` for prose.

## Use
`NomNom.SectionCard` — props are `SectionCardProps` in `components/index.d.ts`.
```js
h(N.SectionCard, { title: 'Household verdict', trailing: '4 of 4 rated', trailingVariant: 'primary' },
  h(N.Text, { as: 'p', textStyle: 'serif-sm' }, 'Everyone finished their plate.'))

h(N.SectionCard, { title: 'Joel\u2019s note', uppercase: false, quote: 'End of summer pizza night on the deck.' })
```
Markup: `section.nn-card.nn-section-card` > `.nn-section-header`, `p.nn-text` (quote), children.
