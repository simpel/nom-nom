The one way to set copy: a `Text` takes a type-scale step (`textStyle`) and a tone, so no component writes its own font rules.

**Built from:** —

Defined by the design system; every component in the bundle sets its words through it. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `textStyle` | `serif-xs` · `serif-sm` · `serif-md` · `serif-lg` · `serif-xl` · `sans-xs` · `sans-sm` · `sans-md` · `sans-lg` · `sans-xl` (the Typography tokens) | `sans-md` |
| `tone` | `primary` (`text-primary`) · `secondary` · `tertiary` · `accent` (`primary-text`) | `primary` |
| `weight` | `normal` · `semibold` | `normal` — every step is regular, at every size |
| `italic` | `true` for the cook's note | `false` — no step is italic on its own |
| `numeric` (tabular), `align` (`center`), `lines` (clamp) | | |
| `as` | element (`span`, `p`, `h1`, `div`) | `span` |

## Rules
- A component never declares `font:` for copy; it renders `Text`. Labels and eyebrows are `SectionHeader`; numerals with a verdict are `ScoreValue`.
- `accent` only for scores, live counts and links — never body text.
- Headings keep their element (`as: 'h1'`) so structure survives the styling.

## Use
`NomNom.Text` — props are `TextProps` in `components/index.d.ts`. Markup: `.nn-text[data-style][data-tone][data-weight]` (+ `data-italic`, `data-numeric`, `data-lines`).
