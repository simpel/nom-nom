A pressable card that leads to a Pro screen (Party detail "See insights"): ProCard's ground with the ProMark, a title, a subtitle and a chevron.

**Built from:** ProMark · Text · Icon.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`title`, `subtitle`, `href` / `onClick`.

## Rules
- Ground `pro-soft`, `radius-3xl`, `shadow-lg`, `spacing-5` padding; ProMark above a `serif-sm` title, a `sans-sm` secondary subtitle, a `pro-text` chevron.
- It is an entry point, not a Pro block: it holds no content. A card that is both preview and entry is a ProCard with `action`.
- Press `opacity-70`.

## Use
`NomNom.ProLinkCard`. Markup: `button|a.nn-pro-link` > `__body`, `.nn-pro-card__chevron`.
