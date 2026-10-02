# Pro — ProMark, ProCard, ProView, ProGate

One language for everything that needs Nom Nom Pro. Violet appears nowhere else.

| Level | Use for | Look |
|---|---|---|
| **ProMark** | Heading every Pro surface; entry points (rows, link cards) | sparkles + "PRO", `pro-text`, `sans-xs` semibold, `tracking-widest` |
| **ProCard** | A Pro block inside a free view (rater reasons, health detail, Recommended) | `pro-soft`, `radius-3xl`, `spacing-5`, `shadow-lg`, ProMark, `serif-sm` title |
| **ProView** | A whole Pro-only screen or sheet (Insights) | the ground is `pro-soft` (`--bg`, `--sheet`), ProMark above the title, plain `panel` cards on it |
| **ProGate** | A Pro-only view for someone without Pro | the real layout blurred at 60%, a `panel` card with `shadow-xl`: mark, title, one sentence, ≤4 checked benefits, Unlock with Pro, Not now |

## Rules
- Locked never means empty: a ProCard shows a teaser and a blurred preview of the real content; a ProGate blurs the real view.
- One CTA wording: **Unlock with Pro** (`pro` solid, `lg`, full width, sparkles).
- Cards inside a ProView don't repeat the mark (`mark={false}` on ProCard there, or use plain `Card`).
- Shelves inside a ProCard run edge to edge of the card automatically.

```jsx
<ProCard title="Why Anna scored it this way" sub="Based on Anna's 34 ratings">…</ProCard>
<ProCard locked title="Cooking for Anna" teaser="See what Anna rates highest…" onUnlock={buy}>{preview}</ProCard>
<ProView><ProMark/><h1>Insights</h1>…</ProView>
<ProGate title="Insights are part of Nom Nom Pro" benefits={[…]} onUnlock={buy} onDismiss={back}>{view}</ProGate>
```
