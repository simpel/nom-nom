The photos at the top of a detail screen: equal PhotoCards — square, tall or wide — that scroll sideways and bleed off the right edge, with an Add photo button that stays put and shrinks to its icon once you scroll.

**Built from:** PhotoCard `lg`, AppButton (Add photo), Text.

From the Meal Detail Redesign canvas; the add affordance moved out of the strip's end, where it scrolled out of view. React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
`photos` (PhotoCard props: `{ src, alt, score? }[]`), `format` (PhotoCard's: `square`, `portrait` by default, or `landscape`), `onAddPhoto` (omit when the viewer can't add photos), optional `emptyTitle`, optional `collapsed` (force the icon-only state, e.g. when the screen itself has scrolled; otherwise the strip sets it from its own scroll).

## Rules
- **Format is a property of the strip, not of a photo.** The strip passes one PhotoCard `format` to every tile — `portrait` 216×288, `square` 288×288, `landscape` 288×216 — so the row keeps an even rhythm. A photo of the other shape is centre-cropped; the cook's photos from one meal are one set. Pick the format they mostly are.
- Tiles are PhotoCard `lg` (`radius-3xl`), all the same size; pass `score` on a photo to show its verdict Badge; gap `spacing-2.5`; the strip runs past the right gutter to signal scroll. Crop from centre; never tint a photo.
- With photos and `onAddPhoto`: an AppButton `secondary elevated sm`, camera icon + "Add photo", fixed `spacing-3` from the strip's bottom-left — it does not move with the photos.
- As soon as the strip scrolls (more than 8px), the button collapses to a `spacing-9` icon-only circle: the label fades out (150ms) while its width and the padding animate to zero (250ms ease-out). Scrolling back to the start expands it again. Reduce Motion: fade only. The accessible name stays "Add photo".
- No photos and `onAddPhoto`: a quiet `spacing-20` row tile (`spacing-24` when the strip is landscape), 1.5px dashed `line-placeholder`, camera glyph in `primary-text`, "Add a photo" `sans-sm` semibold over "Camera or library" `sans-sm` `text-tertiary`. The whole tile is the button.
- No photos and no add: `sunken` tile, fork-and-knife glyph, "No photo yet".

## Use
`NomNom.PhotoStrip` — props are `PhotoStripProps` in `components/index.d.ts`. The track is `.nn-scroller`, the system's one horizontal scroll area: snap-to-tile, contained overscroll, and a thin `line-control` bar that fades in on hover or focus and is absent on touch, where the platform draws its own. Never hide the scrollbar outright — on a pointer device it is the only sign there is more to the right.

Markup: `.nn-photo-strip[data-format]` > `__track` > `.nn-photo-card[data-size=lg]`, then `.nn-button.nn-photo-strip__add` (+ `data-collapsed`) > `.nn-icon` + `__add-label`; empty: `button.nn-photo-strip__empty` > `.nn-icon` + `.nn-text` × 2, or `.nn-photo-card[data-size=lg]` when nothing can be added.
