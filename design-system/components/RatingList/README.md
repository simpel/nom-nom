The one “section header + meter + list of rows” block. Its meal shape is who rated: a count in the header, a progress meter, then one row per person with how they compare to their usual and their score.

**Built from:** Section · ProgressBar `xs` · Card `list` · **ListRow** · Text · Badge (delta, "New") · ScoreValue `xs`.

Its rows are ListRows, so a rater row, a settings row and a SegmentedBar legend row are one implementation and line up to the same rhythm.

New from the Meal Detail Redesign canvas (not yet in the SwiftUI code); React in `components/bundle.js`, styles in `bundle.css`.

## Two shapes

| | pass | renders |
| --- | --- | --- |
| Who rated (the meal shape) | `raters`, `rated`, `total` | "5 of 6" in the header, a ProgressBar `xs`, a row per person with their delta and ScoreValue `xs` |
| Any other distribution | `rows` `[{ label, note, value }]` and `bar` | your meter above the card, your rows inside it. SegmentedBar's `legend="rows"` is exactly this: the segmented track as `bar`, one row per taste tier |

A row whose value is zero still renders at full strength — a scale keeps every step, and only the figure drops to `text-tertiary`. Dimming a row would read as "not applicable" when it means "nobody".

## The consumer provides
Raters (name, optional role such as "chef", score, delta vs their usual or "new"), the viewer's own state, the rated count.

## Rules
- Section: SectionHeader with the count as `primary` trailing text ("5 of 6"), then a ProgressBar `xs` of rated / total, inset `spacing-2`, `spacing-3` above the card.
- Rows are ListRows in a Card `layout="list"` — the card supplies the hairline and the `spacing-14` minimum. Name Text `sans-md`, role `sans-sm` `tertiary`, both in the row's `title`; the note and the score share its `trailing` slot.
- Change vs their usual: the delta Badge `sm` (`primary` +16, `warning` −4); "As usual" and "Not rated yet" as `tertiary` Text; a first rating is a `secondary` "New" Badge.
- Score: ScoreValue `xs` (accent numeral), right-aligned in `spacing-9`. The viewer's row is last; unrated it has no score.

## Use
`NomNom.RatingList` — props are `RatingListProps` in `components/index.d.ts`. Markup it renders: `.nn-section` > `.nn-section-header`, `.nn-progress-bar.nn-rating-list__progress`, `.nn-card[data-layout=list]` > `.nn-row.nn-rating-row` (`.nn-row__body`, `.nn-row__trail` holding `.nn-badge` or `.nn-text` and `.nn-score`).
