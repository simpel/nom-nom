A sentence with its positive and negative fragments coloured: the verdict summary and insight copy.

**Built from:** Text `serif-xs`.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`parts`: plain strings and `{ text, tone: 'positive' | 'negative' }`.

## Rules
- `serif-xs`. Positive is `primary-text`, negative is `warning-text` (not `destructive`: a verdict is not an error).
- Colour never carries the meaning alone: the words say it ("loved", "too salty") and the colour agrees.
- At most two coloured fragments per sentence.

## Use
`NomNom.EditorialText`. Markup: `p.nn-editorial` > `.nn-editorial__pos` / `__neg`.
