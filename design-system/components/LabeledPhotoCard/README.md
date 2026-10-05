A photo tile with a label laid over it: a category, a cuisine, a party cover.

**Built from:** PhotoCard · Text · Icon (the selected check).

Replaces CategoryGridCard, CategoryHeroCoverCard and the cuisine picker tiles.

## Axes

| prop | values | default |
| --- | --- | --- |
| `label` · `meta` | the word over the photo, and an optional second line | — |
| `photo` | the image; without one the tile is the no-photo ground | — |
| `size` | `sm` · `md` · `lg` (PhotoCard's) | `md` |
| `format` | `square` · `portrait` · `landscape` | `square` |
| `selected` | 2px `primary` ring and a check | `false` |
| `onClick` / `href` | makes it a button or a link | — |

## Rules
- The scrim is PhotoCard's, bottom-up: the label has to stay readable over a bright plate, so the tile never shows a label without one.
- `lg` sets the label in `serif-sm`; `sm` and `md` in `sans-md` semibold. One line of meta at most, `sans-xs`.
- **A button gets `aria-pressed`, a link gets `aria-current`.** `aria-pressed` on a link is invalid; a selected link is the page you are on.
- Selected is a ring and a check, never a colour wash over the photo.
- A tile with no label is a PhotoCard. A tile that needs a title, a score and meta is a RecipeCard.

## Use
```js
h(N.LabeledPhotoCard, { label: 'Italian', meta: '12 recipes', photo: src, onClick: open })
h(N.LabeledPhotoCard, { label: 'Thai', photo: src, selected: true, onClick: pick })
```
Markup: `div|button|a.nn-labeled-photo[data-pressable]` > `.nn-photo-card`, `__scrim`, `__label`, `__check`.
