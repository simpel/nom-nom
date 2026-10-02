The six-step taste scale used when you rate a meal yourself: a row of `lg` AppButtons labelled −1…5, with the chosen verdict word underneath.

**Built from:** AppButton × 6, Text.

Hand-written from `apps/ios/NomNom/Core/Components/TasteScoreSelector.swift`, rebuilt on AppButton to match the Meal Detail Redesign. React in `components/bundle.js`, styles in `bundle.css`. (ReactionPicker, the per-eater row of small cells, is removed.)

## The consumer provides
`value` / `defaultValue` + `onChange` with a `Reaction` or `null`; optional `label` (group name), `showVerdict` (default true), `disabled`.

## Toggle buttons, not radios

The row is `role="group"` and each step is a button with `aria-pressed`. It looks like a radio group and nearly is one, but **tapping the chosen step clears the rating** — something a radio cannot do, and something this scale needs: a person who mis-tapped should be able to un-rate rather than being stuck on a wrong verdict. `aria-pressed` says "this is on, you can turn it off"; `aria-checked` would promise behaviour the component does not have, and would also demand arrow-key navigation and a roving tabindex.

## Rules
- Each step is a standard AppButton `size="lg"` (`spacing-12` circle, `sans-lg` semibold numeral, tabular); the group is centred, gap `spacing-2`.
- Unselected: `secondary elevated` (white `panel`, `shadow-xs`, `text-primary`).
- Selected: AppButton `variant="reaction"` with its step, `soft` (the step's fill at 15%, its `reaction-<step>-text` numeral, semibold) plus a 1.5px fill ring.
- Verdict line: one Text `sans-sm`, centred, the same size and weight in both states — "Great" in `primary`, "Not rated yet" in `tertiary`.
- Radio group: `role="radio"` + `aria-checked`, each labelled "4: Great". Tap again to clear. Spring 0.25 / 0.75.

## Use
`NomNom.TasteScoreSelector` — props are `TasteScoreSelectorProps` in `components/index.d.ts`. Markup: `.nn-taste` > `.nn-taste__row[role=radiogroup]` > `.nn-button[role=radio]` + `.nn-text`.
