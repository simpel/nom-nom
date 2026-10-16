Drag to reorder, for any set of things in either direction: the rows of a list Card, the tiles of a horizontal strip, and rows that move between lists (a recipe's ingredient groups).

**Built from:** nothing of its own. It is a behaviour put on the items the consumer already draws (ListRow, SwipeRow, PhotoCard tiles); it adds no surface, colour or glyph.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## What the consumer provides
- The items, each with a stable `id`, drawn as usual. A list row shows the reorder handle as its ListRow `leading` Icon (`line.3.horizontal`); a tile needs no handle.
- `axis`: `vertical` (a list) or `horizontal` (a strip). It only names the accessibility actions.
- `onMove(moved, target)`: put `moved` where `target` is. Within one set that is the target's place (dragging down past a row lands after it); from another list, just before it.
- `group`: items in sets with the same group can move between them. Each set's own drop target (its footer or empty space) takes an item from another set at its end, so an empty list still takes a drop.

## Rules
- **A drag never steals a scroll or a swipe.** On touch it starts with a long press (the platform's drag lift); a plain pan along either axis scrolls, and a sideways swipe still opens a SwipeRow. With a pointer it starts anywhere on the item; the handle shows the grab cursor.
- **The set shows where the item will land while it is held.** The others make room live (`duration-layout`, none under reduced motion); the held item's own slot stays at `opacity-disabled`; the lifted copy is the platform's drag preview (`shadow-lg` on the web).
- **No reorder mode.** No "Edit" or "Done" button switches it on; the handle is always there.
- **Every move has a non-drag path.** VoiceOver gets actions on each item: "Move up" / "Move down" (`vertical`) or "Move left" / "Move right" (`horizontal`), and the consumer adds "Move to {list}" for each other list in the group. On the web, Alt + arrow keys move the focused item.
- A list row's handle is a ListRow `leading` Icon: `line.3.horizontal` on iOS, `grip` on the web. It is the only glyph Reorder brings.
- In an edit sheet the order is part of the form: it is saved with the sheet's commit, never on drop.

## Use
`NomNom.Reorder`: `items` (ids), `axis`, `group`, `onMove`, children = the items in that order. `NomNom.ReorderTarget`: `group`, `onEnter(moved)`, children = the set's footer or empty state.
Swift: `.reorderable(id, dragging:, axis:, previous:, next:, onMove:)` on each item and `.reorderDropTarget(dragging:onEnter:)` on a list's surface; the views sharing one `dragging` binding are one group.
Markup: `.nn-reorder[data-axis]` > `.nn-reorder__item[data-dragging]`; `.nn-reorder-target[data-over]`.
