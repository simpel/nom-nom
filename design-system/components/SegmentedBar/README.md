A distribution as one bar: how a dish's ratings split across the taste scale, how a recipe's macros split, how a week's meals split by tier.

**Built from:** Bar · Section + SectionHeader (when given a `title`) · Text (the keys) · **RatingList** (`legend="rows"`).

Replaces the four hand-built segmented bars (reaction distribution, macros, health tiers, party split).

## Axes

| prop | values | default |
| --- | --- | --- |
| `segments` | `[{ label, value, reaction? , color? }]` — widths are each value's share of the sum | — |
| `legend` | `true` (badges and dots under the bar) · `'rows'` (a Card list of ListRows) | — |
| `format` | `count` · `percent` | `count` |
| `size` | `sm` (`spacing-1.5`) · `md` (`spacing-2.5`) · `lg` (`spacing-4`) | `md` |
| `title` · `trailing` | wraps the bar in a Section with that SectionHeader and right-hand figure | — |
| `label` | the bar's accessible name when there is no `title` | — |

- **Every key is a swatch and a label**, whatever the segment is: a rounded square in the segment's own colour — `reaction-<step>-fill` or whatever `color` holds — then the label in Text. `spacing-2.5` and `sans-sm secondary` in the inline legend, `spacing-3` and `sans-md primary` in the rows.
- **Not a Badge.** A legend key names a slice of the bar; a badge is a label the thing itself carries. Six verdict badges stacked down a column read as six statuses to act on, and they set the tier word in semibold against the figure beside it.
- The unfilled remainder is `track`. Segments are separated by a 1px `panel` seam, not a gap.

## Which legend

| | use |
| --- | --- |
| `legend` | up to about six short tiers that fit on two lines — the taste scale, macros |
| `legend="rows"` | when each tier needs a figure read down a column, or the labels are long. **The breakdown is a RatingList**: SegmentedBar passes its Bar as that list's `bar` and one row per tier, so a tier breakdown and a rater list are the same block with different rows. Figures are set `serif-xs` tabular, the step a ScoreValue `xs` uses, so a tier column and a score column read as the same kind of number |
| no legend | a bar inside a row or card that a nearby label already explains |

## Its relationship to RatingList

RatingList is the system's "section header + meter + list of rows" block. SegmentedBar is a meter. With `legend="rows"` the two compose directly: the bar becomes the list's `bar`, each tier becomes one of its `rows`, and the header, spacing and row rhythm all come from RatingList. Nothing about the breakdown is drawn here.

The data still differs — RatingList's `raters` shape answers *who rated and what each gave*, the tiers answer *how the ratings fell across the scale*. A meal screen usually shows both.

## Rules
- **A tier at zero is never dimmed.** It keeps its full-strength Badge and its place in the scale; only the figure goes `text-tertiary`. Zero is a reading — "nobody couldn't eat it" is information about the dish, and fading it reads as "not applicable". This matters most at the ends of the scale: Can't eat at 0% is the single most reassuring thing on the screen, and Amazing at 0% is the most telling.
- **The key carries the meaning, the bar carries the proportion.** More than two segments without a legend is unreadable.
- Reaction segments go in scale order, Can't eat → Amazing, always. Never sort by size.
- Only taste distributions use the reaction ramp. Macros and other non-taste splits use `chart-series*`, assigned by a stable index, never cycled.
- Not a progress bar: a single filled proportion is ProgressBar. Not a chart: a value over time is TrendChart.
- Pass `title` rather than putting a SectionHeader beside the bar yourself — the Section owns that spacing.
- `lg` only as the subject of its own card; `sm` for a bar inside a row.

## Use
```js
// How the household rated — a Section, a bar, and the verdict Badges as its key
h(N.SegmentedBar, { title: 'How the household rated', trailing: '18 ratings', legend: true,
  segments: N.REACTIONS.map(function (r) { return { label: r.name, value: counts[r.key] || 0, reaction: r.key }; }) })

// The same split as a readable column
h(N.SegmentedBar, { title: 'How the household rated', legend: 'rows', format: 'percent',
  segments: N.REACTIONS.map(function (r) { return { label: r.name, value: counts[r.key] || 0, reaction: r.key }; }) })

h(N.SegmentedBar, { title: 'Macros', legend: true, format: 'percent', segments: [
  { label: 'Protein', value: 32, color: 'var(--chart-series1)' },
  { label: 'Carbs', value: 48, color: 'var(--chart-series2)' },
  { label: 'Fat', value: 20, color: 'var(--chart-series3)' }] })
```
Markup: `.nn-segbar` > `.nn-bar`, with `.nn-segbar__legend` > `.nn-segbar__key` > `.nn-segbar__key-label` (`__swatch` + `.nn-text`), or the RatingList's `.nn-card[data-layout=list]` > `.nn-row`.
