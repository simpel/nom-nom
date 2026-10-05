The shape of content that is still on its way: shimmering bones in the layout the content will take, so nothing moves when it lands.

**Built from:** Card (`list`, or a block) · Text (the caption) · bones. A bone is a `sunken` pill that a `panel` sweep crosses every `duration-shimmer`. It writes no type and no surface of its own.

## Axes

| prop | values | default |
| --- | --- | --- |
| `layout` | `list` · `card` · `text` · `row` | `list` |
| `rows` | rows in a `list`: as many as the content usually has | 3 |
| `lines` | lines in `card` and `text` | 3 |
| `leading` | `avatar` · `photo`, matching the ListRow it stands in for | — |
| `trailing` | a Badge- or ScoreValue-sized bone on the right | false |
| `meta` | false drops a row's second line | true |
| `caption` | one sentence under the bones for work that takes seconds | — |
| `label` | the accessible name when there is no caption | "Loading" |

| layout | stands in for | bones |
| --- | --- | --- |
| `list` | a `Card layout="list"` of ListRows | per row: optional leading (`avatar` spacing-8 circle, `photo` spacing-11 `radius-xl`), a title (spacing-4) over a meta line (spacing-3), optional trailing (spacing-10 × spacing-6); rows `spacing-14` tall, divided by `line` |
| `card` | a Card of copy (SectionCard, a ScoreCard's sentence) | a heading (spacing-6, 45%) over `lines` of text (spacing-3), the last at 60% |
| `text` | copy straight on the ground or inside another card | `lines` of text, the last at 60% |
| `row` | one ListRow inside a list that is otherwise there | one row |

## When to use what

| what is waiting | use |
| --- | --- |
| content whose shape you know (a list, a card, copy) | Skeleton in that shape |
| work that takes seconds (an AI answer, a sync) | Skeleton + `caption`: "Working out what to change" |
| an action the person just started | AppButton `loading` (a spinner in the button), never a Skeleton |
| a whole screen | chrome and ScreenHeader at once, Skeletons for the blocks below; never a lone centred spinner |
| it failed | the bones give way to what went wrong and one way to try again |
| it came back empty | the bones give way to an EmptyState |

## Rules
- Mirror the content: the same Card, the same row count and heights. A Skeleton that is taller or shorter than what replaces it makes the screen jump.
- Bones are `sunken` on `panel` (and on `pro-soft` inside a ProCard); the sweep is `panel` at 70%, travelling left to right over `duration-shimmer` with `ease-standard`, forever. It is the only motion in the system that loops.
- The caption is household voice and says what is happening, `sans-sm` `text-tertiary`, centred under the bones. Never a percentage you can't keep, never "Please wait", never "Loading…" as visible copy.
- Reduce Motion stops the sweep and keeps the bones. Forced colours draw each bone as a `GrayText` outline.
- The region is `role="status"`, `aria-busy`, named by the caption (or `label`); the bones are hidden from assistive tech.
- No skeleton for something that loads in a blink: a list already in memory renders at once.

## Use
```js
h(N.Skeleton, { rows: 3, trailing: true, caption: 'Working out what to change' })
h(N.Skeleton, { layout: 'card', lines: 2 })
h(N.Card, { layout: 'list' },
  h(N.ListRow, { title: 'Tuesday', meta: 'Carbonara', trailing: h(N.ScoreValue, { score: 83, size: 'xs' }) }),
  h(N.Skeleton, { layout: 'row', leading: 'photo' }))
```
Markup: `.nn-skeleton-region[data-layout]` holding `.nn-skeleton-row` / `.nn-skeleton-text` and `.nn-skeleton[data-shape]` bones; `.nn-skeleton-region__caption`.
