Minus · numeral · plus: the one way to change a small number by hand.

**Built from:** AppButton `secondary soft iconOnly` × 2 · Text.

## Axes

| prop | values | default |
| --- | --- | --- |
| `value` / `defaultValue` · `onChange(n)` | controlled / uncontrolled | `min` |
| `min` · `max` · `step` | — | `1` · `99` · `1` |
| `unit` | appended to the numeral | — |
| `formatValue(n)` | full control of the readout | — |
| `size` | `sm` · `md` | `md` |
| `label` | names the group | — |

Buttons are `spacing-11` at `md` — the 44px touch target. The readout is `sans-lg`, tabular, `spacing-10` wide so the buttons never shift as digits change.

## Rules
- **The numeral alone is the default.** In a labelled row — "Servings" on the left, the stepper on the right — `unit` would say the same word twice. Pass it only when nothing beside the stepper names the number.
- Small, bounded counts a person adjusts by one or two: servings, people, portions. A wide range is an Input; a choice from a set is an AppButton row.
- At the limits the matching button goes `disabled`; it never disappears.
- Changing the value recomputes in place. There is no Apply.

## Use
```js
// In a row that already says "Servings"
h(N.ValueStepper, { value: servings, onChange: setServings, min: 1, max: 12, label: 'Servings' })

// Standing alone
h(N.ValueStepper, { defaultValue: 4, max: 12, unit: 'servings', label: 'Servings' })
```
Markup: `.nn-stepper[data-size]` > two `.nn-button` with `.nn-stepper__value` between.
