The photos on a detail screen: equal PhotoCards — square, tall or wide — that scroll sideways and bleed off the right edge, always ending with an Add photo tile the same size as a photo.

**Built from:** PhotoCard `lg`, Icon, Text.

The add affordance is the strip's last tile again (iOS canvas, Oct 2026): a tile the size of a photo reads as part of the set, where the floating button covered the first photo. React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
`photos` (PhotoCard props: `{ src, alt, score? }[]`), `format` (PhotoCard's: `square`, `portrait` by default, or `landscape`), `onAddPhoto` (omit when the viewer can't add photos), optional `emptyTitle`. `collapsed` is deprecated and has no effect.

## Rules
- **Format is a property of the strip, not of a photo.** The strip passes one PhotoCard `format` to every tile — `portrait` 216×288, `square` 288×288, `landscape` 288×216 — so the row keeps an even rhythm. A photo of the other shape is centre-cropped; the cook's photos from one meal are one set. Pick the format they mostly are.
- Tiles are PhotoCard `lg` (`radius-3xl`), all the same size; pass `score` on a photo to show its verdict Badge; gap `spacing-2.5`; the strip runs past the right gutter to signal scroll. Crop from centre; never tint a photo.
- With `onAddPhoto`: the last tile is the Add photo tile, exactly the size and shape of a photo tile in the strip's `format`: transparent (no ground), 2px dashed `line-control` (the border is the only boundary, so it holds 3:1), `radius-3xl`, camera glyph in `primary-text`, "Add photo" `sans-sm` semibold over "Camera or library" `sans-sm` `text-tertiary`. The whole tile is the button; it snaps like a photo.
- No photos and `onAddPhoto`: the add tile alone, labelled `emptyTitle` ("Add a photo").
- No photos and no add: `sunken` tile, fork-and-knife glyph, "No photo yet".

## Use
`NomNom.PhotoStrip` — props are `PhotoStripProps` in `components/index.d.ts`. The track is `.nn-scroller`, the system's one horizontal scroll area: snap-to-tile, contained overscroll, and a thin `line-control` bar that fades in on hover or focus and is absent on touch, where the platform draws its own. Never hide the scrollbar outright — on a pointer device it is the only sign there is more to the right.

Markup: `.nn-photo-strip[data-format]` > `__track.nn-scroller` > `.nn-photo-card[data-size=lg]` × n, then `button.nn-photo-strip__add-tile[data-format]` > `.nn-icon` + `.nn-text` × 2; nothing to show and nothing to add: `.nn-photo-card[data-size=lg]` (no photo yet).
