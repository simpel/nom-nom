The card over the camera while a recipe is being read.

**Built from:** Card · Text · AppButton.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`title` ("Reading the recipe"), `message`, `onCancel`.

## Rules
- A `scrim` over the camera and one Card with `shadow-lg`, capped at `spacing-72`, centred, `role="status"`.
- Copy in the household voice, saying what is happening, never a percentage.
- A native "Cancel" is always there.

## Use
`NomNom.ScannerOverlay`. Markup: `.nn-scanner` > `.nn-card.nn-scanner__card`.
