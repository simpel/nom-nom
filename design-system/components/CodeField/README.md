A one-time code: one cell per digit over a single real input.

**Built from:** Text · the field ground (`sunken`).

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## Axes
`length` (6), `value` / `onChange`, `label`, `error` (boolean or the message).

## Rules
- Cells are `spacing-14` tall, `sunken`, `radius-xl`, `spacing-2` apart, the digit in `serif-md` tabular. No border at rest or on focus (the field rule).
- The active cell shows a `primary` caret: `border-thick` wide, blinking over `duration-layout`. Reduce Motion stops the blink.
- Error: `border-thick` `destructive` on every cell and the message in `destructive-text` below.
- It is one `input` (`inputmode=numeric`, `autocomplete=one-time-code`), so paste and autofill work; the cells are drawn from its value.

## Use
`NomNom.CodeField`. Markup: `.nn-code` > `.nn-code__cells` > `input.nn-code__input`, `.nn-code__cell[data-active]`.
