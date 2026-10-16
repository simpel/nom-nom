The platform's top-bar control: a glass circle with a text-primary glyph, for a sheet's or screen's bar. Also BarAction, the bar's text action.

**Built from:** Icon. Not an AppButton.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
| prop | values |
| --- | --- |
| `icon` + `label` | glyph name · the accessible name (required: the control has no text) |
| `active` | swaps to `<icon>-fill` and sets `aria-pressed`: a filter that is on |
| `unread` | ListRow's primary dot at the top-right, `spacing-1` in |
| `disabled` | `opacity-50` |

BarAction: `label` · `disabled` · `loading`. "Next", "Mark all read": `sans-sm` semibold `primary-text`, 44 tall, no ground.

## Rules
- Every control in a bar (close, back, Next, checkmark, heart, "…", filter) is one of these two. Never an AppButton in a bar, never the `primary` tint on a glyph.
- The circle is `glass` (`spacing-11`, `shadow-xs`); the glyph is `text-primary`. Close sits alone on the leading side; a primary action on the trailing side.
- A state is a different glyph (filled for "on") or a dot (unread), never a colour change on the circle.
- The sheet's own bar (BottomSheet) is built from these.

## Use
```js
h(N.BarButton, { icon: 'x', label: 'Close', onClick: close })
h(N.BarButton, { icon: 'filter', label: 'Filter recipes', active: filtered })
h(N.BarAction, { label: 'Mark all read', onClick: markAll })
```
Markup: `button.nn-bar-button` (+ `.nn-bar-button__dot`), `button.nn-bar-action`.
