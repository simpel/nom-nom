The recipe's content: numbered steps on a rail (StepList) and the checkable ingredient list (IngredientList / CheckRow).

**Built from:** Text · Card `list` · Icon.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## StepList
`steps` (strings or `{ title, text }`), `current`. A `primary-soft` disc (`spacing-8`) with the number in `primary-text`, a `line-strong` rail between discs, the step in `sans-md`. The current step's disc is `primary` with `on-primary` (cook mode).

## IngredientList / CheckRow
`items: [{ name, amount, checked }]`. One `Card layout="list"` of rows: a `spacing-6` check circle, the name (wraps), the amount `sans-sm` semibold secondary on the right. The whole row is the switch (`role="checkbox"`); checked rows strike through in `text-tertiary`. Two columns on a wide screen is the same list set side by side, never a table.

## Rules
- Amounts convert with the recipe's unit choice (UnitToggle).
- A step never repeats its number in its text.

## Use
`NomNom.StepList`, `NomNom.IngredientList`, `NomNom.CheckRow`.
