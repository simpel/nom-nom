One large square choice in a single-choice grid: the rate-a-meal taste, plate cleared and want-it-again steps; a row of them is the cooking-time selector.

**Built from:** Card's surface · Text.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
| prop | values |
| --- | --- |
| `title` · `sub` | the serif choice over a `sans-sm` line; `numeral` sets the title in `serif-md` tabular |
| `selected` | the tint at `opacity-20` over `panel`, the copy inked, the sub-line semibold |
| `reaction` | tints a taste step with its reaction fill; none = `primary` |
| `square` | `false`: a row of tiles keeps its height to its copy, with `radius-lg` (cooking time) |

## Rules
- Card's surface (`panel`, `radius-3xl`), no border and no shadow, chosen or not. The tint and the inked copy carry the choice, plus `aria-pressed`.
- Grids: taste 3 × 2, plate cleared 2 × 2, want it again 3 × 1, `spacing-3` apart. One question per screen.
- A single-choice step advances a `duration-layout` beat after the pick.
- A compact taste control in a list row is still TasteScoreSelector; ChoiceTile is for the large grids.

## Use
`NomNom.ChoiceTile`. Markup: `button.nn-choice[aria-pressed][data-reaction][data-square]`.
