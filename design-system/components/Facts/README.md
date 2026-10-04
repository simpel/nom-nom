Small read-only facts about the subject, each a label over a value: time, method, servings, rotation. Two layouts, a grid and a strip, and no surface of its own.

**Built from:** SectionHeader (the label) · Text (the value).

New. It takes the facts and the rotation badge out of the old DetailHeader, where a duration and a method read as a line of metadata and Staple as a green capsule. Here every fact has the same weight and the same treatment.

## Axes

| prop | values | default |
| --- | --- | --- |
| `items` | `[{ label, value }]`; an item with no value is dropped | — |
| `layout` | `grid` · `strip` | `grid` |

| layout | shape | use when |
| --- | --- | --- |
| `grid` | 3 equal columns, wraps to a second row, **max 6** | the facts are a block of the screen (recipe detail) |
| `strip` | one row, items split by `line` hairlines, scrolls sideways and bleeds off the right edge like PhotoStrip | the facts sit inline, close to something else, and the first two or three are what matter |

## Rules
- **Label** is a SectionHeader (uppercase, `as: 'span'`): TIME, METHOD, SERVES, ROTATION. **Value** is `sans-md` in `text-primary`.
- **No other colours.** A value is never `primary-text`, a role colour or a reaction colour: Staple is the same ink as 4 servings. A fact that needs colour to be read is a Badge, not a fact.
- **No icons, no capsules, nothing pressable.** A fact is read, not tapped.
- **No surface.** Facts draws no Card. Where a surface is wanted, the screen places Facts inside a Card (the recipe screen does, `Card md`). The component never decides that.
- Label gap `spacing-1`; grid `spacing-5` between rows, `spacing-4` between columns; strip `spacing-4` either side of each hairline.
- One word or a short value per fact: "15–30 min", "Frying", "4", "Staple". Never a sentence.
- It sits after the photos in the screen anatomy (root README, "Screen anatomy"), before the primary content.

## What goes in it

| label | value | source |
| --- | --- | --- |
| Time | 15–30 min | the recipe's effort band |
| Method | Frying | the cooking method |
| Serves | 4 | servings |
| Rotation | Staple · Sometimes · One & done | the rotation goal |

## Use
```js
h(N.Card, null, h(N.Facts, { items: [{ label: 'Time', value: '15–30 min' }, { label: 'Method', value: 'Frying' },
  { label: 'Serves', value: '4' }, { label: 'Rotation', value: 'Staple' }] }))

h(N.Facts, { layout: 'strip', items: [{ label: 'Time', value: '45–60 min' }, { label: 'Serves', value: '6' }] })
```
Markup: `dl.nn-facts[data-layout]` > `.nn-facts__item` > `dt` (`.nn-section-header`), `dd` (`.nn-text`).
