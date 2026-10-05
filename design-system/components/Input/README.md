The single-line text field: one style, one height and one radius for every field, taller only when it carries a label, with optional icons, a clear button, a hint and an error message.

**Built from:** Text (label, hint, error), Icon, AppButton (clear: `secondary ghost sm iconOnly`).

Hand-written from `apps/ios/NomNom/Core/Components/Input.swift` as a React rendition (`components/bundle.js` + `bundle.css`); the SwiftUI view is the source of truth for behaviour.

## The consumer provides
`placeholder`, `value` / `defaultValue` + `onChange`, optional `label`, `leadingIcon` / `trailingIcon`, `appearance` (`soft` default; `plain` only inside a Card list row), `clearable`, `hint`, `error` (boolean or the message), `readOnly`, `disabled`. (Swift: `.filled` → `soft`, `.cardRow`/`.plain` → `plain`; `.outlined`, the `sm`/`xl` sizes and the capsule shape are dropped.)

## Shape
- Every field: `spacing-11` (44) tall, `radius-xl`, side padding `spacing-3.5`, text `sans-md`. With a `label`: `spacing-14` (56); the label is `sans-xs` `text-secondary` above the text.
- The border is `border-hairline` (1px) in `line-control`, never a half-pixel and never `line`: a control's boundary has to clear 3:1 (WCAG 1.4.11), and `line` is 1.17:1 on panel.

## One style

There is one field: **`soft`** — a `sunken` ground with a 1px `line` border. No outline-on-white variant: two field styles meant every form had a choice to make and mixed forms looked assembled from two kits.

`plain` is not a style. It strips the ground, border and padding for a field that lives inside a `Card layout="list"` row, where the row already draws all three. Use it only there.

| appearance | ground | border | where |
| --- | --- | --- | --- |
| `soft` (default) | `sunken` | 1px `line` | everywhere |
| `plain` | the row's | none | inside a Card list row |

## States

The ground never changes — **the border carries every state**, so a field doesn't appear to move or repaint as it is used.

| state | border | text | notes |
| --- | --- | --- | --- |
| rest | 1px `line-control` | `text-primary` | placeholder `text-tertiary` |
| hover | 1px `text-tertiary` | `text-primary` | pointer only |
| **focus** | **2px `primary`** | `text-primary` | leading icon `primary`, label `primary-text` |
| **error** | **2px `destructive`** | `text-primary` | icon and label `destructive-text`; the message prints below with an alert glyph |
| read-only | **none** | `text-secondary` | default cursor, no clear button |
| disabled | 1px `line` | `text-tertiary` | label and icons `text-tertiary`, not-allowed cursor |

Read-only loses the border entirely: the border is the affordance, so a value you cannot edit shouldn't draw one. Disabled keeps it and fades the contents — "there is a field here, it is not available right now". Transitions are 0.15s ease-out on the border only.

## Rules
- **Focus and error are 2px and a full-strength token.** They were 1.5px at 80% opacity, which read as a slightly thicker hairline rather than a state. A state a person has to compare two fields to notice is not a state.
- **Never change the ground to show a state.** It makes the same colour mean two things across a form — white as "active" in one field and "not editable" in another — and the field appears to move as it is used.
- One style, so a form never mixes field treatments. A field that needs to stand out is a field in its own card, not a differently drawn field.
- Only one of `hint` and `error` shows: the error replaces the hint, so the field never grows or shifts when it goes wrong.
- **The label is associated by `htmlFor`, not by wrapping.** A `<label>` around the whole field would pull the clear button into the name ("Email Clear text"). Nothing wraps the control.
- **Every other prop goes to the control.** `id`, `name`, `type`, `autoComplete`, `inputMode`, `required`, `pattern`, `onBlur` — the component owns only its own props, so a sign-in field can be `type="email" autoComplete="email"`.
- **States are read off the control**, not mirrored in classes: `:has([aria-invalid="true"])`, `:has(:disabled)`, `:has(:read-only)`. One source of truth, so the CSS cannot disagree with the DOM.
- **The message describes the field, it does not name it.** The `<label>` wraps only the control and its label text; the hint and the error sit outside it, linked with `aria-describedby`, and an error carries `role="alert"` so it is announced when it appears. Putting them inside the label would make the field announce as "Email That address is missing a domain."
- `error` as a string is the normal form — an error with no sentence leaves the person guessing. Reserve bare `error: true` for a field inside a group where one message covers all of them.
- **Read-only is not disabled.** Read-only means "this is the value, you just can't change it here" and stays legible on `panel`; disabled means "not available right now" and recedes. Never use disabled to display a value.
- Hint text is `sans-xs` `text-secondary`, one line. Anything longer belongs above the field, not under it.

## Use
`NomNom.Input` — props are `InputProps` in `components/index.d.ts`. Markup: `div.nn-field-block` > `span.nn-field[data-appearance][data-labeled]` (+ `--labeled`, `--plain`, `.is-error`, `.is-readonly`, `.is-disabled`) with `.nn-icon`, `.nn-field__stack` > `.nn-text.nn-field__label` + `input`, `.nn-button.nn-field__clear`; then `.nn-field__msg`.
