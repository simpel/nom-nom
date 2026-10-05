The one switch: an on/off setting, always in a ListRow's trailing slot.

**Built from:** AppButton. It is an AppButton `secondary ghost` restyled as a track, with the knob as its label — so press, focus ring and disabled behave exactly as they do on every other control, and there is no second pressable element in the system.

## Axes

| prop | values | default |
| --- | --- | --- |
| `checked` / `defaultChecked` | controlled / uncontrolled | `false` |
| `onChange(checked)` | — | — |
| `disabled` | — | `false` |
| `label` | accessible name | the row title |

- Track `spacing-12` × `spacing-7`, `radius-full`: `track` off, `primary` on. Knob `spacing-6`, `stone-0`, `shadow-xs`.
- A switch is the one control drawn under 44px — it is a switch, not a capsule, and resizing it would make it stop reading as one. It carries a 44px-tall hit area instead, and the ListRow it sits in is `spacing-14` tall, so the target is there either way.
- Pressing scales the knob instead of fading the whole control, which is the one place a Toggle departs from AppButton's press.
- One size. There is no small toggle.

## Rules
- A Toggle never stands alone: it is the trailing slot of a ListRow whose title names the setting and whose meta explains it. The whole row is not pressable — the Toggle is.
- No label beside the switch, no "On" / "Off" text: the position is the state.
- A setting that needs confirming or that navigates is a pressable ListRow, not a Toggle.
- Use `aria-checked`, never a `selected` appearance.

## Use
```js
h(N.ListRow, { title: 'Dinner reminder', meta: 'Weekdays at 16:30', chevron: false,
  trailing: h(N.Toggle, { checked: on, onChange: setOn, label: 'Dinner reminder' }) })
```
Markup: `button.nn-button.nn-toggle[role=switch][aria-checked]` containing `.nn-toggle__knob`.
