The person at the top of a rater or member sheet: Avatar, serif name, a meta line and a chevron, bare on the sheet.

**Built from:** Avatar `lg` · Text.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`name`, `photo`, `meta` (a `sans-sm` `text-tertiary` line), `large` (`serif-md` name on the member sheet, else `serif-sm`), `onClick` (adds a `primary-text` chevron and makes it a button).

## Rules
- `spacing-14` minimum height. No Card around it, no hairline: it opens the sheet's content.
- The name is serif, which a ListRow's title never is; that is why this is not a ListRow.

## Use
`NomNom.PersonHeaderRow`. Markup: `.nn-person-row` > `.nn-avatar`, `__body`, `__chevron`.
