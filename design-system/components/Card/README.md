The one surface: a white `panel` card at `radius-3xl` with no border or shadow — every card in the system (SectionCard, ScoreCard, RatingList, RecipeLinkCard, SheetCard) is this component.

**Built from:** Icon (chevron).

Defined by the design system from the Meal Detail Redesign's borderless cards. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `size` | `sm` (padding `spacing-4`) · `md` (`spacing-5`) | `md` |
| `variant` | — · `primary` (`primary` at `opacity-10` over `panel`, the featured card; one per screen) | — |
| `layout` | `block` · `list` (padding `spacing-1` `spacing-4`, 1px `line` between rows) | `block` |
| `onClick` / `href` | makes the card a button or link with a trailing `text-tertiary` chevron; `opacity-70` on press, `focus-ring` outline | — |

## Rules
- Children stack in a column; a component sets the gap with `--nn-gap` (ScoreCard `spacing-3.5`, inset SectionCard `spacing-1.5`).
- Never nest a Card in a Card. Rows go in `layout="list"`, not in their own cards.

## Use
`NomNom.Card` — props are `CardProps` in `components/index.d.ts`. Markup: `.nn-card[data-size][data-variant][data-layout]` (+ `data-pressable` > `__body` + `.nn-icon.__chevron`).
