A row that picks one of a few options, and the unit toggle that sits above a recipe's ingredients.

**Built from:** ListRow · Icon · the platform picker.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## SelectRow
`title`, `meta`, `value`, `options` (strings or `{ value, label }`), `onChange`. A ListRow whose value is the current choice with a `chevron-up-down` glyph; tapping opens the platform's own picker (a real `select` laid over the row), so keyboard and VoiceOver work. Use it for a choice of 3 to 12 that does not deserve its own screen (a filter's sort order, cuisine).

## UnitToggle and convertAmount
The recipe's "Imperial units" row: a ListRow with a Toggle, above the ingredients and next to the Servings stepper. The choice is the viewer's, remembered on the account; the recipe shows its own amounts until it is on. `convertAmount(quantity, unit, to)` converts g, kg, ml, l, oz, lb, cups and fl oz (g to oz below 454, to lb above; ml to fl oz below 240, to cups above). **tsp and tbsp never convert**, nor do counts or an unknown unit: they come back unchanged.

## Use
`NomNom.SelectRow`, `NomNom.UnitToggle`, `NomNom.convertAmount`.
