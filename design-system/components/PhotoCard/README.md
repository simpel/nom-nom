The one photo tile, shared by RecipeCard, PhotoStrip and Timeline: a rounded, centre-cropped photo (or the no-photo tile) with the verdict as a Badge in its bottom-right corner.

**Built from:** Badge (verdict), AppButton `secondary elevated iconOnly` (the favourite heart, 44 × 44), Icon, Text.

## The favourite heart
- 44 × 44, the touch minimum, so it is deliberately large against an `xs` or `sm` tile. Favouriting from a thumbnail that small is not a thing to design for — put the heart on `md` and `lg` tiles.
- Outlined (`heart-outline`) when the thing is not a favourite; **filled** (`heart`) and `destructive-text` when it is. Fill is the state; the button, its ground and its position never change, so the tile doesn't shift as you tap.
- The button appears whenever `onToggleFavorite` is given, favourited or not — an outlined heart is how a person knows they *can* favourite. Passing `favorite` alone shows it as a read-only marker.
- `aria-pressed` carries the state, so it is a toggle to a screen reader, and the label reads "Add to favourites" / "Remove from favourites".

Defined by the design system to replace RecipeCard's photo, PhotoStrip's tiles, Timeline's tiles and RecipeLinkCard's thumbnail; the PhotoStrip's "No photo yet" state is a PhotoCard `lg` too. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `size` | `xs` · `sm` · `md` · `lg` — the tile's **long edge** | `md` |
| `format` | `square` · `portrait` · `landscape` — its **shape** | per size (below) |

Size and shape are separate axes. A size sets the long edge; `portrait` and `landscape` are both **3:4**, so the short edge is three quarters of it. Twelve tiles from four sizes and three formats, all on the spacing scale:

| size | long edge | square | portrait | landscape | radius |
| --- | --- | --- | --- | --- | --- |
| `xs` | `spacing-20` (80) | 80 × 80 | 60 × 80 | 80 × 60 | `radius-xl` |
| `sm` | `spacing-48` (192) | 192 × 192 | 144 × 192 | 192 × 144 | `radius-2xl` |
| `md` | `spacing-48` (192) | 192 × 192 | 144 × 192 | 192 × 144 | `radius-2xl` |
| `lg` | `spacing-72` (288) | 288 × 288 | 216 × 288 | 288 × 216 | `radius-3xl` |

| default format | where |
| --- | --- |
| `xs` square, no badge | RecipeLinkCard thumbnail |
| `sm` portrait | Timeline |
| `md` square (fills its column in a grid) | RecipeCard |
| `lg` portrait | PhotoStrip |

`sm` and `md` share a long edge and differ only in their default format; `md` square is the grid tile, `sm` portrait the timeline tile.

## The consumer provides
`src` + `alt`, optional `score` (0–100: renders the verdict Badge) or `verdict`, or any `badge` (Badge props), `favorite` + `onToggleFavorite` (the heart, top-right: outlined when not a favourite, filled and `destructive-text` when it is), `selected`, and any overlay children.

## Rules
- Photo fills the tile, cropped from centre, 0.5px `line` ring at 30%; never tinted.
- Badge: `elevated sm`, `spacing-2` from the bottom-right (`spacing-3` at `lg`); for a score it is a `reaction` Badge with the verdict word only, colour-coded by step. The numeral never sits on the photo.
- No photo: `sunken` tile, fork-and-knife glyph in `text-tertiary`, "No photo yet" (sm, lg); the badge still shows.
- `selected`: 2px `primary` ring (the current meal in a Timeline).

## Use
`NomNom.PhotoCard` — props are `PhotoCardProps` in `components/index.d.ts`. Markup: `.nn-photo-card[data-size]` (+ `data-selected`) > `img` or `__none`, overlays (`__fav`), `.nn-badge.nn-photo-card__badge`.
