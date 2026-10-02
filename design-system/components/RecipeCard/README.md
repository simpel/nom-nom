A grid tile for a recipe: one fixed square photo with the verdict word as a badge in its corner, an uppercase category eyebrow and a two-line title.

**Built from:** PhotoCard `md`, SectionHeader (eyebrow), Text.

Hand-written from `apps/ios/NomNom/Core/Components/RecipeCard.swift` as a React rendition (`components/bundle.js` + `bundle.css`); the SwiftUI view is the source of truth for behaviour.

## The consumer provides
`title`, `photo`, `category` (eyebrow; the app falls back cuisine → dish kind → method → "Recipe"), `by` (owner when it isn't the viewer), `favorite`, `score` (0–100; shown as its verdict word) or `verdict`.

## Rules
- One size: `spacing-48` wide; the photo is a PhotoCard `md` (1:1, `radius-2xl`). In a grid the card fills its column at the same ratio.
- Verdict: PhotoCard's badge — a `reaction` Badge `elevated sm` with the word only ("Great", "Bad"), bottom-right, colour-coded by step (`reaction-<step>-fill` at 15% over `panel`, `reaction-<step>-text`). No numeral on the card; the score is the badge's tooltip and lives on the recipe screen.
- Favourite: PhotoCard's heart, top-right — outlined until it is a favourite, then filled.
- Fallbacks: recipe photo → cuisine category photo (see Photography) → `sunken` tile with a fork-and-knife glyph in `text-tertiary`.
- Label: a SectionHeader — category uppercase, "by Name" as its trailing text. Title `sans-sm` semibold, two lines; label block a fixed `spacing-14` so rows align.
- Long-press menu: add/remove favourite; delete (owner only).

## Use
`NomNom.RecipeCard` — props are `RecipeCardProps` in `components/index.d.ts`. Markup: `.nn-recipe-card` > `.nn-photo-card` (`img`, `.nn-photo-card__fav`, `.nn-badge.nn-photo-card__badge`) + `__meta` (`.nn-section-header`, `__title`).
