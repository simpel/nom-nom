Nothing here yet: one fact, one sentence, at most one way out — in four sizes, from a whole screen down to a single row.

**Built from:** Card · Text · AppButton · Icon. It writes no type, no surface and no button rules of its own; `title` and `message` go through Text, `action` and `secondaryAction` are AppButtons the component builds.

Replaces every `ContentUnavailableView`, the "No … yet" cards and the arc empty states.

## Axes

| prop | values | default |
| --- | --- | --- |
| `layout` | `screen` · `card` · `plain` · `row` | `card` |
| `title` | the fact, in the household voice | — |
| `message` | one sentence saying what to do; not used by `row` | — |
| `icon` | a single glyph, `text-tertiary` | — |
| `action` | `{ label, onClick \| href, icon?, variant? }` | — |
| `secondaryAction` | a second, quieter way out | — |

| layout | where | title | action |
| --- | --- | --- | --- |
| `screen` | the whole view has nothing | `serif-md`, centred | `primary solid md`; secondary `ghost` |
| `card` | a block on a screen that has other content | `serif-sm`, centred, in a Card | `primary soft sm` |
| `plain` | inside a Card or sheet that already draws the surface | `serif-sm`, left | `primary soft sm`, left |
| `row` | one line inside `Card layout="list"` | `sans-sm tertiary`, left, no message | `sm`, pushed right |

Title and message use the same type steps as the card titles and body copy beside them, so an empty block reads at the same weight as a full one.

## Every empty state in the app

| case | title | message | action |
| --- | --- | --- | --- |
| First run — nothing logged | "No meals yet" | what logging gets you | "Log a meal" |
| A list the person will fill | "Just you so far" | who to add | "Invite someone" |
| Search found nothing | "No recipes match ‘laxpudding’" | suggest a shorter search | "Clear search" (`secondary`) |
| Filters found nothing | "Nothing with these filters" | which filter is narrowest | "Clear filters" (`secondary`) |
| Not enough data yet | "Not enough meals yet" | how many more are needed | none |
| Behind Pro | "Trends are part of Pro" | what Pro adds | "See Pro" (`variant: 'pro'`) |
| Nothing left to do | "All caught up" | — | none |
| A missing photo | "No photo yet" | — | "Add photo" (`row`) |
| Nobody has rated | "Nobody has rated this" | when ratings appear | none |

## Rules
- **No artwork.** The system defines no illustration, and a photo deck is not a substitute. Art would have to be defined here first.
- Say what is missing, never that something failed. An error, an offline state and a loading state are not empty states and do not use this component.
- One action, plus a second only when there is a real way back (clearing a search or a filter). Never three.
- A first-run empty state always offers the action that fills it. A "not enough data yet" state offers nothing — waiting is the answer.
- The icon is optional and decorative. Never an emoji.
- A list that is empty is replaced by an EmptyState; never an empty `Card layout="list"`, and never a row that says "None".
- `screen` is the only layout that centres vertically; it never sits inside a Card.

## Use
```js
h(N.EmptyState, { layout: 'screen', icon: 'utensils', title: 'No meals yet',
  message: 'Log tonight\u2019s dinner and it will show up here.',
  action: { label: 'Log a meal', onClick: log } })

h(N.EmptyState, { title: 'No recipes match \u2018laxpudding\u2019', message: 'Try a shorter search.',
  action: { label: 'Clear search', variant: 'secondary', onClick: clear } })

h(N.Card, { layout: 'list' },
  h(N.EmptyState, { layout: 'row', icon: 'camera', title: 'No photo yet',
    action: { label: 'Add photo', onClick: add } }))
```
Markup: `.nn-empty[data-layout]` (a `.nn-card` when `layout="card"`), with `.nn-empty__icon` and `.nn-empty__actions`.
