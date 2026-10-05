A tappable card linking a meal to its recipe: a portrait thumbnail, "RECIPE" label, serif name, meta line and a chevron.

**Built from:** Card (`sm`, pressable), PhotoCard `xs` `portrait`, SectionHeader, Text.

New from the Meal Detail Redesign canvas (not yet in the SwiftUI code); React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
`recipe` (photo, name, time range, method, dish kind), the link, and optionally `format` — PhotoCard's, `portrait` by default.

## Rules
- A pressable Card `sm`; thumb a **PhotoCard `xs` `portrait`** (60 × 80, `radius-xl`); label a SectionHeader (uppercase, `as: 'span'`); name `serif-sm`; meta `sans-sm` `text-tertiary`, parts joined with " · ".
- Portrait because recipe photography is shot upright and a square crop cuts the plate. The shape comes from PhotoCard's `format` axis, not from a size override here, and `format` is exposed so a call site with wide photography can pass `landscape` without the card changing in any other way.
- The chevron is Card's (`text-tertiary`, as on every pressable card). The whole card is one link (`a`), padding `spacing-4`, gap `spacing-3.5`.

## Use
`NomNom.RecipeLinkCard` — props are `RecipeLinkCardProps` in `components/index.d.ts`. Markup it renders: `a.nn-card.nn-recipe-link` > `.nn-card__body` (`.nn-photo-card[data-size=xs][data-format=portrait]`, `__body` > `.nn-section-header` + `.nn-text` × 2) + `.nn-card__chevron`.
