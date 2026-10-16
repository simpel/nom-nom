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

## Edit mode (from the app)
Where photos are being added to something (the meal and recipe editors), the strip becomes an editor of PhotoCard `sm` tiles under a Section ("Photos", trailing "Optional"):
- **Remove** is AppButton `secondary elevated` icon-only (the one 44pt size) on the tile.
- The first tile carries a "Cover" Badge `elevated sm`; a recipe's page photos are badged "Page N" and cannot be reordered.
- Add: "Camera" is an AppButton, "Library" a photo picker with an AppButton label. Tapping a tile opens the media viewer (BottomSheet, Media viewer).
- Reorder through each tile's context menu and accessibility actions (Make cover, Move left, Move right), never drag, which would fight the horizontal scroll.

## Adding a photo
- Where a photo can be made as well as taken (a recipe's cover), the add tile's sub-line starts with a `pro soft sm` "AI" Badge with a sparkles glyph, and the tile opens the **Add photo sheet** instead of going straight to the camera.
- **Add photo sheet** (BottomSheet, picker type: fitted to its content, "Add photo" inline title, close on the leading side, a choice dismisses it): first "Generate with AI" as a ProLinkCard (title, and "A photo plated from the name and ingredients"; free viewers who tap it reach the paywall), then a Card `list` of "Take photo" (only with a camera) and "Choose from library". Without AI the sheet is the Card list alone, or the tile skips the sheet and opens the camera and library directly.
- **A photo being made** is a tile in the strip: a PhotoCard `lg`-sized `sunken` tile with the Skeleton sweep, leading the strip until the photo lands there. It carries no caption.
- **In the editors**, choosing AI shows a pending tile in the strip until the recipe is saved: PhotoCard `sm`-sized, `pro-soft`, a sparkles glyph in `pro-text`, "AI photo when you save" (`sans-sm` semibold) over "Tap to undo" (`sans-sm` `text-secondary`). Tapping it takes the AI photo back out.

## Use
`NomNom.PhotoStrip` — props are `PhotoStripProps` in `components/index.d.ts`. The track is `.nn-scroller`, the system's one horizontal scroll area: snap-to-tile, contained overscroll, and a thin `line-control` bar that fades in on hover or focus and is absent on touch, where the platform draws its own. Never hide the scrollbar outright — on a pointer device it is the only sign there is more to the right.

Markup: `.nn-photo-strip[data-format]` > `__track.nn-scroller` > `.nn-photo-card[data-size=lg]` × n, then `button.nn-photo-strip__add-tile[data-format]` > `.nn-icon` + `.nn-text` × 2; nothing to show and nothing to add: `.nn-photo-card[data-size=lg]` (no photo yet).
