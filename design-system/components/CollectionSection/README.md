A section that holds a collection the viewer may add to: the one component that decides where "Add", "New" and "Log" live, so no screen invents its own.

**Built from:** Section (SectionHeader `count` + `action`) · EmptyState · AppButton `primary soft sm`.

Drawn in the iOS app first (profile sections: Dinner parties, Created recipes, Meal history); the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## The rule, by state

| `count` | viewer can add (`canAdd` and `onAdd`) | what draws |
| --- | --- | --- |
| more than 0 | yes | the header: title, count, and one soft capsule on the right (`verb`) |
| more than 0 | no | the header with title and count only |
| 0 | yes | the EmptyState with its button (`addLabel`); no header action |
| 0 | no | the EmptyState with no button; the message says whose it is |

The header action and the EmptyState button are never on screen together.

## Axes

| prop | values | default |
| --- | --- | --- |
| `title` | the section's label | — |
| `count` | decides "empty" (default: the number of children). **Not shown** | children |
| `showCount` | draw the figure after the title. Only for a number the person acts on ("Waiting for your rating 3"), never for "Meal history 31" | `false` |
| `verb` | the header button, one or two words, sentence case: "New party", "Log meal", "Add recipe" | "Add" |
| `addLabel` | the long form, used for VoiceOver and the empty state's button: "Add a recipe" | `verb` |
| `onAdd` | the action; omit it and nobody can add | — |
| `canAdd` | `false` when this viewer cannot act (someone else's profile) | `true` |
| `empty` | `{ title, message, icon? }` for the EmptyState | "Nothing here yet" |

## Rules
- **No count by default.** A section's number brings no value: "Meal history" is enough, and a number that only restates the list length is noise. A count earns its place only when it is something to act on or compare (pending items, "3 of 4 rated"); pass `showCount`.
- One action per section, never an icon. A section that wants "See all" as well keeps "Add" in the header and moves "See all" to the foot of the list.
- The button is a visible 44pt capsule, not text: the header row is `spacing-11` tall, its title and count centred on the button, its right edge on the card's right edge.
- Pass `canAdd: false` rather than disabling: an action a person cannot use is not drawn.
- The verb names what the section holds. The screen's own main commitment ("Log a meal" in the ScreenHeader) stays in the ScreenHeader; a section never repeats it.
- Empty copy follows EmptyState: say what is missing, one sentence of what to do, in the household voice. For a viewer who cannot add, the sentence says whose collection it is ("Recipes this person adds will show up here.").
- A list card may also open with an AddRow on a screen whose whole job is adding (My recipes); that is the exception, not the pattern.

## Use
```js
h(N.CollectionSection, { title: 'Meal history', count: 31, verb: 'Log meal', addLabel: 'Log a meal', onAdd: log }, h(N.Card, { layout: 'list' }, rows))

h(N.CollectionSection, { title: 'Created recipes', count: 0, verb: 'Add recipe', addLabel: 'Add a recipe', onAdd: add,
  empty: { title: 'No recipes yet', message: 'Recipes you add will show up here.' } })

h(N.CollectionSection, { title: 'Created recipes', count: 0, canAdd: false,
  empty: { title: 'No recipes yet', message: 'Recipes this person adds will show up here.' } })
```
Markup: `section.nn-section.nn-collection` > `.nn-section-header[data-action]` (`__lead` > title, optional count; `__action`), then the children or `.nn-empty`.
