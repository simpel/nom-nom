A screen section: a SectionHeader (uppercase title, optional trailing count) above any content — the rail of a Timeline, the card of a RatingList, a SectionCard.

**Built from:** SectionHeader.

Defined by the design system. React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
`title`, optional `trailing` + `trailingVariant`, `uppercase`, `icon` (all passed to SectionHeader), and the content.

## Rules
- The header sits `spacing-2` above the content and is inset `spacing-2`, so it lines up with the card corners below.
- Sections stack `spacing-7` apart on a detail screen.

## Use
`NomNom.Section` — props are `SectionProps` in `components/index.d.ts`. Markup: `section.nn-section` > `.nn-section-header` + content.
