# Pro — ProMark, ProCard, ProView, ProGate

One language for everything that needs Nom Nom Pro. Violet appears nowhere else.

| Level | Use for | Look |
|---|---|---|
| **ProMark** | Heading every Pro surface; entry points (rows, link cards) | sparkles + "PRO", `pro-text`, `sans-xs` semibold, `tracking-widest` |
| **ProCard** | A Pro block inside a free view (rater reasons, health detail, Recommended) | `pro-soft`, `radius-3xl`, `spacing-5`, `shadow-lg`, ProMark, `serif-sm` title |
| **ProView** | A whole Pro-only screen or sheet (Insights) | the ground is `pro-soft` (`--bg`, `--sheet`), ProMark above the title, plain `panel` cards on it |
| **ProGate** | A Pro-only view for someone without Pro | the real layout blurred at 60%, a `panel` card with `shadow-xl`: mark, title, one sentence, ≤4 checked benefits, Unlock with Pro, Not now |

## Entry points and pressable cards (from the app)

- **ProLinkCard** is the pressable card that leads to a Pro screen (Party detail "See insights"): ProCard's ground (`pro-soft`, `radius-3xl`, `shadow-lg`, `spacing-5` padding) holding the ProMark, a `serif-sm` title, a `sans-sm` secondary subtitle and a `pro-text` chevron.
- **`ProCard action`**: unlocked, the whole card is one button (press `opacity-70`) with the same `pro-text` chevron on the title row; locked, `action` is ignored. Use it when a card is both a preview and the way in (the meal score sheet's "Why it landed at"), so no separate "See the full breakdown" button is needed.
- **`teaser` is optional.** A block whose title already says what it holds ("Picked for …", "Safe bets for …") omits it and keeps the blurred preview and "Unlock with Pro".
- **A Pro score** is ScoreCard `variant="pro"`, not a ProCard (see ScoreCard).

## Selling Pro instead of previewing it

Two locked Pro cards in a row (a recipe's party insights and health score) read as two purchases, and a card that shows a score while hiding its detail mixes display with hint. When two or more Pro blocks sit together without Pro, show **one short pitch**: a locked ProCard with **no children**, so no blurred preview and no scores.

- ProMark, a `serif-sm` title that frames the gain ("Get more from every meal"), one `sans-md` secondary `teaser` that names what Pro brings ("Dinner party insights, health scores and more."), one **Unlock with Pro**.
- Name two or three concrete benefits and end on "and more"; never a list of scores or a half-shown number.
- With Pro the blocks are separate pressable cards again, each opening its own sheet.

## Rules
- Locked never means empty: a ProCard shows a teaser and a blurred preview of the real content (a pitch has no content to blur, see above); a ProGate blurs the real view.
- One CTA wording: **Unlock with Pro** (`pro` solid, `lg`, full width, sparkles).
- Cards inside a ProView don't repeat the mark (`mark={false}` on ProCard there, or use plain `Card`).
- Shelves inside a ProCard run edge to edge of the card automatically.

```jsx
<ProCard title="Why Anna scored it this way" sub="Based on Anna's 34 ratings">…</ProCard>
<ProCard locked title="Cooking for Anna" teaser="See what Anna rates highest…" onUnlock={buy}>{preview}</ProCard>
<ProCard locked title="Get more from every meal" teaser="Dinner party insights, health scores and more." onUnlock={buy}/>
<ProView><ProMark/><h1>Insights</h1>…</ProView>
<ProGate title="Insights are part of Nom Nom Pro" benefits={[…]} onUnlock={buy} onDismiss={back}>{view}</ProGate>
```
