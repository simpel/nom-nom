A selectable pill for multi-select tags ("What stood out?": Tender, Too salty): the sm capsule with a selected state.

**Built from:** Text. The AppButton `sm` capsule, plus a selected state.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
| prop | values |
| --- | --- |
| `label` | the tag |
| `selected` | `primary-soft` + `primary-text` semibold when on; `panel` + `text-primary` at rest |
| `disabled` | `opacity-50` |

## Rules
- `spacing-11` tall, `spacing-3` side padding, `sans-sm`, capsule. No icon, no check: the soft ground and the semibold carry the state.
- A toggle button, not a radio: `aria-pressed`. Tap again to clear.
- Lay them out wrapping, `spacing-2` apart. They sit on `sheet`, so the rest ground is `panel`.
- For one choice out of a few, use ChoiceTile or TasteScoreSelector.

## Use
`NomNom.TagToggle`. Markup: `button.nn-tag[aria-pressed]`.
