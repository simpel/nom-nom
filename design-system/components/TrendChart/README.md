Scores over time: the household total and, optionally, one dashed line per member. Drag to scrub.

**Built from:** Card (optional) · Text (tooltip) · `chart-series` colours.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`total` (0–100 per point), `members: [{ name, values }]`, `labels`, `framed` (false bleeds edge to edge), `showsPoints` (a dot on every total value, one per meal).

## Rules
- Total: `primary`, `border-thick`. Members: `border-hairline`, dashed `dash` on / `dash` off, in `chart-series` by stable member index (the palette repeats after seven). With no members the total gets a `primary` area at `opacity-10`.
- Gridlines at 0, 25, 50, 75, 100 in `line`.
- Drag or hover to scrub; a cursor line and a tooltip (Card `sm`, `shadow-lg`) show the point; the tooltip clears on release.
- Colour never carries a member alone: the tooltip and the list under the chart name them.

## Use
`NomNom.TrendChart`. Markup: `.nn-trend` > `svg.nn-trend__svg`, `.nn-trend__tip`.
