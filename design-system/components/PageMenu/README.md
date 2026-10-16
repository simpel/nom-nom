The "…" menu on every root and detail screen: context actions, the dinner party picker, inbox, profile and settings, Pro and help.

**Built from:** BarButton (the trigger) · SectionHeader · system menu items.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
`groups`: `[{ label?, items: [{ label, onClick, checked?, destructive? }] }]`, in this order: context actions · the dinner party (the viewer's parties as `checked` radio items, then "Manage parties") · Inbox / My profile / Settings · Get Nom Nom Pro / Help & feedback. `unread` puts the dot on the trigger.

## Rules
- There is no "Just me": every account belongs to a party, so the party group always has a checked item.
- A screen's own primary action belongs in its ScreenHeader, not here. A creation action the header does not carry (Recipes' "New recipe") is the first group.
- On iOS it is a native `Menu` (context menus use system buttons); this component fixes the groups and order and draws the popover for the web.
- The panel is `panel`, `radius-2xl`, `shadow-lg`, groups split by a `line` hairline; items are 44 tall, a destructive item reads `destructive-text`.

## Use
```js
h(N.PageMenu, { unread: true, groups: [{ items: [{ label: 'New recipe' }] }, { label: 'Dinner party', items: [{ label: 'The Friday Feast Club', checked: true }, { label: 'Manage parties' }] }, { items: [{ label: 'Inbox' }, { label: 'My profile' }, { label: 'Settings' }] }] })
```
Markup: `.nn-page-menu` > `.nn-bar-button`, `.nn-page-menu__panel[role=menu]` > `__group` > `__item`.
