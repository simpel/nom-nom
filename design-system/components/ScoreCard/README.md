One score readout in two layouts: `hero`, the meal screen's big numeral with what changed and a progress bar, and `compact`, a smaller card for household, health and per-person scores.

**Built from:** Card, SectionHeader, ScoreValue, Badge (delta), Text, ProgressBar.

Merges the Meal Detail Redesign's ScoreCard with the app's `DividedScoreCard.swift` (DividedScoreCard is removed). React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `layout` | `hero` · `compact` | `hero` |
| `variant` | — · `primary` · `pro` | — (`panel`) |
| `barSegments` | one `chart-series` block per rater, each their share of the score | — |

`variant="primary"` features a score (the health score): the card is tinted `primary` at `opacity-10`, the label turns `primary-text` semibold with its `icon` (leaf), the compact numeral steps up to `serif-md`, and the ProgressBar steps up to `lg` on a `primary` 18% track. One featured score per screen. `layout` is the structural axis for composite components; `variant` stays reserved for colour roles.

| layout | numeral | padding / gap | delta | use |
| --- | --- | --- | --- | --- |
| `hero` | `serif-xl` | `spacing-5` / `spacing-3.5` | own line: Badge `md` + sentence + reference | the meal screen, once |
| `compact` | `serif-sm` | `spacing-4` / `spacing-3` | Badge `sm` at the end of the score row | household score, health score, a person's average, lists of scores |

## Segments, the unrated state and the Pro score (from the app)

- **`barSegments`.** The party score cards (a recipe's "<Party> score", a party's "Average rating") split the Bar into one `chart-series` block per rater, each their share of the average (`score / ratings`), so the blocks add up to the score. No visible key; the blocks are named for VoiceOver only.
- **Unrated is not pressable.** `score` null draws "No score yet" in `serif-sm` over a `sans-sm` secondary line ("0 of 4 have rated"), with no dashed circle and no empty Bar, no chevron and no `onClick`. When someone can be nudged, a "Remind" `secondary soft sm` AppButton sits on the right and opens a sheet of members (a ListRow + Toggle each, all on, then a full-width "Remind"). This replaces the "—" / "Unrated" pressable card: a chevron into an empty breakdown said nothing and led nowhere.
- **The meal screen's score card** composes these parts (Card `md`, ScoreValue `lg`, the delta line) with a SegmentedBar `sm` in place of the Bar, then the "rated so far" caption. One card; the numeral alone carries the score. "How the ratings split" is not a second card.
- **A Pro score** (the health score and the dinner party's insights on a recipe page) sits on ProCard's ground (`pro-soft`, `radius-3xl`, `shadow-lg`) with a ProMark, the numeral in `pro-text` (`ScoreValue` ink `pro`) and a `pro` Bar. With Pro the card is pressable (chevron) and opens a sheet whose hero is also `pro`. Without Pro it shows the score only: no Bar, not pressable, and one "Unlock with Pro" button in the card. It is a ScoreCard `variant="pro"`, not a ProCard (ProCard locked blurs its content instead of showing a score).

## The consumer provides
`score` (0–100, or `null` = unrated), optional `verdict` (defaults to the six-step word), `title` (uppercase label), `delta` (+ `deltaText`, `deltaReference` in hero), `count` ("12 meals"), `onClick` (makes the card a button with a chevron; the app opens the rationale), `icon` (glyph before the title), `caption` (one `sans-sm` `text-secondary` line under the bar: why it scored this way).

## Rules
- Numeral in `primary-text`, verdict in `text-primary`, baseline-aligned. Unrated: see above ("No score yet", not pressable).
- The taste-match score on a member sheet carries a verdict word the scale does not otherwise use: Close (85 and up), Near (65 to 84), Apart (below 65).
- No rank or leaderboard position on the card: an ordinal ("3rd") without its list reads as noise; the leaderboard lives behind `onClick`.
- Delta Badge: `primary` up, `warning` down, `secondary` flat, signed with a true minus.
- Bar: ProgressBar `md` at score/100 in both layouts (`lg` when featured). No gradient, no thumb: the app's red-to-pine health gradient and fixed `pine-600` are dropped, which also removes their dark-theme contrast miss.
- Title: a SectionHeader pre-header (with `icon`; `primary` when featured); count `sans-sm` `text-secondary`.
- The surface is Card (`md` hero, `sm` compact); pressable via Card's `onClick`, with Card's trailing chevron, `opacity-70` press and `focus-ring` outline.
- The numeral and verdict are ScoreValue (`lg` hero, `sm` compact, `md` featured compact).

## Use
`NomNom.ScoreCard` — props are `ScoreCardProps` in `components/index.d.ts`.
```js
h(NomNom.ScoreCard, { score: 88, delta: -2, deltaText: 'from last time this group had it', deltaReference: '(90 on 20 Mar)' })
h(NomNom.ScoreCard, { layout: 'compact', title: 'Household score', score: 82, count: '12 meals', delta: 6 })
h(NomNom.ScoreCard, { layout: 'compact', variant: 'primary', icon: 'leaf', title: 'Health score', score: 64, verdict: 'Balanced', caption: 'Plenty of veg and fibre; on the salty side.', onClick: openRationale })
```
Markup: `.nn-card.nn-score-card[data-layout]` (+ `data-variant`, `data-unrated`; `button` + `.nn-card__body` + chevron when pressable) > `.nn-section-header`, `__head` (`.nn-score`, `__aside` > `.nn-text` + `.nn-badge`), `__delta` (`.nn-badge` + `.nn-text`), `.nn-progress-bar`, `.nn-text` (caption).
