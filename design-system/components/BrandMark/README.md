The app icon, as given: a photograph of a white stoneware plate on oak, at Avatar xl size with radius-2xl and a hairline.

**Built from:** Image only.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`src` (the app icon asset), `alt` ("Nom Nom"), `size` (`xl` 80, `lg` 112).

## Rules
- Never redraw the icon as a vector or recolour it. The name next to it is "Nom Nom" in Newsreader (weight 600, `tracking-tight`), set as text.
- `radius-2xl`, `border-hairline` `line` ring. Used on the welcome screen; nowhere else, since it is not an Avatar.

## Use
`NomNom.BrandMark`. Markup: `span.nn-brand-mark > img`.
