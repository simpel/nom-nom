The one “section header + meter + list of rows” block. Its meal shape is who rated: a count in the header, a progress meter, then one row per person with how they compare to their usual and their score.

**Built from:** Section · ProgressBar `xs` · Card `list` · **ListRow** · Text · Badge (delta, "New") · ScoreValue `xs`.

Its rows are ListRows, so a rater row, a settings row and a SegmentedBar legend row are one implementation and line up to the same rhythm.

New from the Meal Detail Redesign canvas (not yet in the SwiftUI code); React in `components/bundle.js`, styles in `bundle.css`.

## Two shapes

| | pass | renders |
| --- | --- | --- |
| Who rated (the meal shape) | `raters`, `rated`, `total` | "5 of 6" in the header, a Bar `xs`, then **one list of everyone who can rate**, alphabetical: a rated person ends in their delta and ScoreValue `xs`, an unrated person in one soft button (Ask, Remind, Rate) |
| Any other distribution | `rows` `[{ label, note, value }]` and `bar` | your meter above the card, your rows inside it. SegmentedBar's `legend="rows"` is exactly this: the segmented track as `bar`, one row per taste tier |

A row whose value is zero still renders at full strength — a scale keeps every step, and only the figure drops to `text-tertiary`. Dimming a row would read as "not applicable" when it means "nobody".

## The consumer provides
Everyone who can rate, rated or not: `name`, optional `role` ("Chef"), `score` (null until rated), `vsUsual` (delta, 0 = as usual, `'new'`), `you` on the viewer's own row, and for an unrated person `meta` ("Not asked yet", "Asked 2 days ago") and `action` (`{ label, onClick, variant }`). The rated count and the total.

## Rules
- Section: SectionHeader with the count as `primary` trailing text ("5 of 6"), then a ProgressBar `xs` of rated / total, inset `spacing-2`, `spacing-3` above the card.
- Rows are ListRows in a Card `layout="list"` — the card supplies the hairline and the `spacing-14` minimum. Name Text `sans-md`, role `sans-sm` `tertiary`, both in the row's `title`; the note and the score share its `trailing` slot.
- Change vs their usual: the delta Badge `sm` (`primary` +16, `warning` −4); "As usual" and "Not rated yet" as `tertiary` Text; a first rating is a `secondary` "New" Badge.
- Score: ScoreValue `xs` (accent numeral), right-aligned in `spacing-9`. Unrated, a row has no score and shows its action instead.
- **One list, never split by state.** Everyone is in the one Card, alphabetical by the name shown. Never a "Rated" card over a "Not yet" card, and never the viewer's row pinned last or first: state shows on the row (a score, or a button), the order does not move with it. The header's "5 of 6" and the Bar report the split.
- **The viewer is a person, not the word "You".** Their row shows their real name with a small `secondary` `sm` Badge "You" after it, and sorts by that name like everyone else.
- An unrated row's button is `soft` `sm`: Ask and Remind are `secondary`; the viewer's own "Rate" is `primary` (the screen's one solid is the header's "Rate this meal"). A person still waiting on an ask shows the button disabled ("Asked", "Reminded"). Its meta line says where they stand ("Not asked yet", "Asked 2 days ago").

## Use
`NomNom.RatingList` — props are `RatingListProps` in `components/index.d.ts`. Markup it renders: `.nn-section` > `.nn-section-header`, `.nn-progress-bar.nn-rating-list__progress`, `.nn-card[data-layout=list]` > `.nn-row.nn-rating-row` (`.nn-row__body`, `.nn-row__trail` holding `.nn-badge` or `.nn-text` and `.nn-score`).
