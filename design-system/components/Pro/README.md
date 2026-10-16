# Pro — ProMark, ProCard, ProScoreGroup, ProView, ProGate

One language for everything that needs Nom Nom Pro. Violet appears nowhere else.

| Level | Use for | Look |
|---|---|---|
| **ProMark** | Heading every Pro surface; entry points (rows, link cards) | sparkles + "PRO", `pro-text`, `sans-xs` semibold, `tracking-widest` |
| **ProCard** | A Pro block inside a free view (rater reasons, health detail, Recommended) | `pro-soft`, `radius-3xl`, `spacing-5`, `shadow-lg`, ProMark, `serif-sm` title |
| **ProScoreGroup** | Two or more Pro scores together, viewer without Pro (a recipe's health score and the party's insights) | one `ProCard` ground, ProMark once, a readout row per score, one sentence, one Unlock with Pro |
| **ProView** | A whole Pro-only screen or sheet (Insights) | the ground is `pro-soft` (`--bg`, `--sheet`), ProMark above the title, plain `panel` cards on it |
| **ProGate** | A Pro-only view for someone without Pro | the real layout blurred at 60%, a `panel` card with `shadow-xl`: mark, title, one sentence, ≤4 checked benefits, Unlock with Pro, Not now |

## Entry points and pressable cards (from the app)

- **ProLinkCard** is the pressable card that leads to a Pro screen (Party detail "See insights"): ProCard's ground (`pro-soft`, `radius-3xl`, `shadow-lg`, `spacing-5` padding) holding the ProMark, a `serif-sm` title, a `sans-sm` secondary subtitle and a `pro-text` chevron.
- **`ProCard action`**: unlocked, the whole card is one button (press `opacity-70`) with the same `pro-text` chevron on the title row; locked, `action` is ignored. Use it when a card is both a preview and the way in (the meal score sheet's "Why it landed at"), so no separate "See the full breakdown" button is needed.
- **`teaser` is optional.** A block whose title already says what it holds ("Picked for …", "Safe bets for …") omits it and keeps the blurred preview and "Unlock with Pro".
- **A Pro score** is ScoreCard `variant="pro"`, not a ProCard (see ScoreCard).

## Locked Pro scores side by side (ProScoreGroup)

Two Pro cards in a row, each with its own "Unlock with Pro", read as two purchases. Without Pro, Pro scores that sit together are **one card**:

- ProCard's ground (`pro-soft`, `radius-3xl`, `spacing-5`, `shadow-lg`) and the ProMark **once**.
- One row per score: a `sans-xs` secondary label over the ScoreValue `md` (ink `pro`), rows divided by a `border-hairline` `line`. Score only: no Bar, no chevron, not pressable.
- One `sans-md` secondary sentence that **names everything Pro opens** ("Pro opens the health score breakdown and The Friday Feast Club's insights."), then one **Unlock with Pro**.
- A lone Pro score stays a ScoreCard `variant="pro"`. With Pro the scores are separate pressable cards again, each opening its own sheet.

## Rules
- Locked never means empty: a ProCard shows a teaser and a blurred preview of the real content; a ProGate blurs the real view.
- One CTA wording: **Unlock with Pro** (`pro` solid, `lg`, full width, sparkles).
- Cards inside a ProView don't repeat the mark (`mark={false}` on ProCard there, or use plain `Card`).
- Shelves inside a ProCard run edge to edge of the card automatically.

```jsx
<ProCard title="Why Anna scored it this way" sub="Based on Anna's 34 ratings">…</ProCard>
<ProCard locked title="Cooking for Anna" teaser="See what Anna rates highest…" onUnlock={buy}>{preview}</ProCard>
<ProScoreGroup scores={[{title:'Health score',score:null},{title:'The Friday Feast Club insights',score:85}]} teaser="Pro opens …" onUnlock={buy}/>
<ProView><ProMark/><h1>Insights</h1>…</ProView>
<ProGate title="Insights are part of Nom Nom Pro" benefits={[…]} onUnlock={buy} onDismiss={back}>{view}</ProGate>
```
