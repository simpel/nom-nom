The one bar: a horizontal meter that holds one fill or several blocks, in five thicknesses.

**Built from:** nothing — a leaf.

Replaces ProgressBar, which is now a deprecated single-fill Bar, and the track SegmentedBar used to draw itself.

## Axes

| prop | values | default |
| --- | --- | --- |
| `value` · `max` | a single fill, 0–max; `null` draws an empty track | — · `100` |
| `segments` | `[{ value, reaction? , color?, label? }]` — each block's width is its share of the sum | — |
| `size` | `xs` 4 · `sm` 6 · `md` 8 · `lg` 10 · `xl` 12 px (`spacing-1` … `spacing-3`) | `md` |
| `label` | accessible name | `"{value} out of {max}"` for a single fill |

- Ground is `track`, corners `radius-full`, overflow hidden. The track is deliberately quiet against the page: a bar is read by where its fill ends, and fill-against-track is 5.2:1 light / 3.6:1 dark, which is the ratio 1.4.11 asks of the part that carries the meaning. A block with no `reaction` or `color` is `primary`.
- Blocks are separated by a 1px `panel` seam, not a gap. Widths animate; `prefers-reduced-motion` turns that off.
- Passing `max` alongside `segments` sizes the blocks against that total instead of their sum, so the bar can sit part-empty ("4 of 10 rated, split by tier").
- A single fill is `role="meter"` with real `aria-value*`; a segmented bar is `role="img"` and needs a `label`.

## Rules
- **One fill means one quantity.** Score, rated-of-total, effort. Several blocks mean a distribution that adds up to a whole — taste tiers, macros. Never use blocks to put two unrelated numbers on one bar.
- Only taste distributions use the `reaction` ramp. Everything else takes `chart-series*` by a stable index, never cycled.
- A bar carries no text. The number lives beside it (ScoreValue, a SectionHeader's trailing figure) or under it in a key — see SegmentedBar, which is this component plus that key.
- `xs` under a section header, `md` in a card, `lg`/`xl` only when the bar is the subject.
- Read-only. A bar a person can drag is not this component.

## Use
```js
h(N.Bar, { value: 83 })                                  // a score
h(N.Bar, { size: 'xs', value: 5, max: 6, label: '5 of 6 rated' })
h(N.Bar, { size: 'lg', label: 'How the household rated', segments:
  N.REACTIONS.map(function (r) { return { value: counts[r.key] || 0, reaction: r.key, label: r.name }; }) })
```
Markup: `.nn-bar[data-size]` > `.nn-bar__seg`.
