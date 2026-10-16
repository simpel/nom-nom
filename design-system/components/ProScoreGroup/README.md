Two or more Pro scores side by side for someone without Pro, as one card with one Unlock with Pro instead of a card and a button each.

**Built from:** ProMark, ScoreValue (ink `pro`), Text, AppButton (`pro`).

Drawn in the iOS app first (recipe page: the party's insights and the health score). React in `components/bundle.js`, styles in `bundle.css`. The rule lives in the Pro README ("Locked Pro scores side by side").

## Axes
`scores` (`{title, score, verdict}` per row), `teaser`, `onUnlock`, `unlockLabel`.

## Rules
- ProCard's ground (`pro-soft`, `radius-3xl`, `spacing-5`, `shadow-lg`) and the ProMark once.
- One row per score: `sans-xs` secondary label over ScoreValue `md`, rows divided by a `border-hairline` `line`. Score only: no Bar, no chevron, not pressable.
- One `sans-md` secondary sentence (`teaser`) naming everything Pro opens, then one **Unlock with Pro**.
- A lone Pro score stays a ScoreCard `variant="pro"`. With Pro the scores are separate pressable cards.

## Use
`NomNom.ProScoreGroup` — props are `ProScoreGroupProps` in `components/index.d.ts`. Markup: `section.nn-pro-card.nn-pro-group` > `.nn-pro-mark`, `__rows` > `__row` (`.nn-text` + `.nn-score`), `.nn-text`, `.nn-button`.
