A ListRow with actions behind it: swipe left to reveal (a destructive "Delete"), always reachable without a gesture.

**Built from:** ListRow · AppButton.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`actions: [{ label, variant, onClick }]` (at most two, `destructive` last), `revealed` / `defaultRevealed` / `onRevealedChange`, children = the ListRow.

## Rules
- The row slides left by `spacing-24` and the actions fill that strip edge to edge, solid, labelled, square. A swipe past `spacing-6` opens it; the opposite swipe closes it.
- Never the only way to do something: the same action is in the row's context menu or detail screen, and focusing an action reveals the set for keyboard users.
- Only the destructive action is red; a destructive action confirms with a native alert.

## Use
`NomNom.SwipeRow`. Markup: `.nn-swipe` > `__actions`, `__front`. Sits inside a `Card layout="list"`.
