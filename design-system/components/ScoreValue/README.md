A score as type: the numeral in `primary-text` (tabular) and its verdict word, baseline-aligned — used by ScoreCard, BottomSheet and RatingList so a score always looks the same.

**Built from:** Text.

Defined by the design system. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `size` | `xs` (numeral `serif-xs`, no verdict — list rows) · `sm` (`serif-sm` + `serif-sm`) · `md` (`serif-md` + `serif-sm` — featured compact) · `lg` (`serif-xl` + `serif-sm` — hero and sheet) | `lg` |

## The consumer provides
`score` (0–100, or `null`), optional `verdict` (defaults to the six-step word), `showVerdict`.

## Rules
- Numeral `accent` tone, verdict `primary` tone; unrated reads "—" and "Unrated" in `tertiary`.
- Never in a Badge and never on a photo: on photos the verdict alone is a reaction Badge (PhotoCard).

## Use
`NomNom.ScoreValue` — props are `ScoreValueProps` in `components/index.d.ts`. Markup: `.nn-score[data-size]` > `.nn-text` × 2.
