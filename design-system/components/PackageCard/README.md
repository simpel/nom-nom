One plan on the paywall: a pressable radio card with the plan, its price and an optional badge.

**Built from:** Card's surface · Badge `pro` · Text.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`title`, `note`, `price`, `period`, `badge` ("Best value"), `selected`, `onSelect`.

## Rules
- A radio: `role="radio"` with `aria-checked`, inside a `role="radiogroup"`. One is always chosen.
- Chosen: the `pro-soft` ground and a filled `pro` check; unchosen: `panel` and an empty ring. No border ring on the card.
- Title `serif-sm`, note `sans-sm` secondary, price `serif-xs` tabular in `pro-text`, period `sans-xs` tertiary. The badge is `pro` `sm`.
- The Subscribe button under the group is `pro solid lg`; the feature checklist above it is ProGate's benefits.

## Use
`NomNom.PackageCard`. Markup: `button.nn-package[role=radio]`.
