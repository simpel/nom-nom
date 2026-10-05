Every time this recipe was cooked, as a horizontal rail of dots over PhotoCards, each with its verdict badge and date.

**Built from:** Section, PhotoCard `sm`, Text.

New from the Meal Detail Redesign canvas (not yet in the SwiftUI code); tiles are the shared PhotoCard, like PhotoStrip and RecipeCard. React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
`occasions` (date, score, optional verdict and photo, `current`, `href`), optional `title`.

## Rules
- The track is `.nn-scroller`: it scrolls, snapping to each occasion. It used to be `overflow: hidden`, which clipped everything past the fourth item with no way to reach it.
- Heading: SectionHeader with "N times".
- Rail: 2px `line-strong`; dots `spacing-5` with a 4px `bg` ring; current `primary`, past `primary-muted`.
- Tiles: PhotoCard `sm` (`spacing-36` × `spacing-48`) with the verdict Badge bottom-right; the current meal is `selected` (2px `primary` ring). No photo: the no-photo tile, badge kept.
- Under each tile: the date `sans-sm` (current reads "This meal", semibold). No score numeral: the verdict badge carries the result; `score` drives the badge and its tooltip.
- Past items link to that meal. The rail bleeds off the right edge.

## Mini variant (`size="mini"`)
For a card that needs to show recent meals without becoming a second detail screen: PartyCard's recent meals, and anywhere a short history sits inside a Card.

- Tiles: PhotoCard `xs` square (`spacing-20`), no verdict Badge.
- Label: the date only, `sans-xs` `tertiary`, tabular; the current one semibold `text-primary` (it keeps its date, never "This meal").
- Rail: the same 2px `line-strong`; dots `spacing-3` with a 2px ring in `--nn-timeline-ring` (default `panel`, since mini lives on cards).
- No header unless `title` is passed; no "N times" count.
- Gap `spacing-2`; the rail still bleeds off the right edge of the card.

```js
h(N.Timeline, { size: 'mini', occasions: [{ date: '1 Oct', photo: a }, { date: '29 Sep', photo: b }, { date: '25 Sep', photo: c }] })
```

## Use
`NomNom.Timeline` — props are `TimelineProps` in `components/index.d.ts`. Markup: `.nn-section` > `.nn-section-header`, `.nn-timeline` > `__track` > `__item` (`.is-current`; `a` for past) > `__dot`, `.nn-photo-card[data-size=sm]`, `__date`.
