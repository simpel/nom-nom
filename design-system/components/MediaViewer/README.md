The one full-screen photo viewer: a dark BottomSheet, paged, titled "Photo 2 of 5".

**Built from:** BottomSheet `media` · BarButton.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`photos` (`[{ src, alt }]`), `index`, `onClose`.

## Rules
- Ground `stone-1000`, the bar at `opacity-90`, text `stone-0`; the close on the leading side, previous / next on the trailing side when there is more than one photo.
- No state changes: free to swipe away.
- Every photo in the app opens here (a strip tile, a note, a profile photo).

## Use
`NomNom.MediaViewer`. Markup: a BottomSheet with `data-kind="media"` and `img.nn-viewer__img`.
