The one row: a leading slot, a title with optional meta, and a trailing slot — every list in the app is this row inside `Card layout="list"`.

**Built from:** Text · Icon. Its slots take Avatar, PhotoCard, Badge, ScoreValue, AppButton, Toggle.

Replaces MealRow, the profile / recipe / meal-history rows, the leaderboard row, member rows, party rows, the notification row, settings navigation rows and info rows.

## Axes

| prop | values | default |
| --- | --- | --- |
| `leading` | node — Avatar, PhotoCard `xs`, rank numeral, Icon | — |
| `title` · `meta` | copy; a string is set for you | — |
| `value` | right-aligned tabular value (key–value rows) | — |
| `trailing` | node — Badge, ScoreValue `xs`, AppButton `sm`, Toggle | — |
| `chevron` | `true` · `false` | `true` when pressable |
| `unread` | primary dot in the gutter, semibold title | `false` |
| `inactive` | the lead, title and meta at `opacity-disabled` (50%); a trailing control stays at full strength and tappable | `false` |
| `tone` | `destructive` | — |
| `size` | `sm` (`spacing-11`) · `md` (`spacing-14`) | `md` |
| `titleLines` | how many lines the title may take: `1` clips (default), `null` lets it wrap | `1` |
| `valueSemibold` | the `value` in semibold, for amounts that are the point of the row | `false` |
| `metaLines` | how many lines the meta may take: `1` clips (default), `null` lets it wrap | `1` |
| `metaAccent` | a run at the end of the meta in `warning-text`, joined with " · " ("Waiting on 2") | — |

The value is `sans-sm`, tabular.

`titleLines: null` + `valueSemibold` is the recipe's ingredient row: the name wraps to as many lines as it needs and the amount is semibold. `metaLines: null` is for a row whose meta is the content, a full sentence ("Astrid and Joel scored it 20 above their usual"), as in the Pro score reasons.

## The four shapes

| shape | build |
| --- | --- |
| Navigation | `title`, optional `meta`, pressable → chevron |
| Key–value | `title` + `value`, not pressable, no chevron |
| Toggle | `title` + `meta`, `trailing` = Toggle, not pressable; the Toggle carries the action |
| Subject | `leading` = Avatar or PhotoCard `xs`, `title` = the name, `meta` = date or count, `trailing` = ScoreValue `xs` or a Badge |
| Invite (pending) | `leading` = Avatar `sm` from the address, `title` = the email, `meta` = "Invited {when}", `trailing` = Accept (`primary solid sm`) + Decline (`secondary soft sm`), both labelled |
| Invited, not joined | the Subject shape with `inactive`, last in every member list: `trailing` = Remind (`primary solid sm`, resends the invite). Revoke is not a second button: it lives in the row's context menu, so the row has one button |

## A pressable row never wraps its controls

Give a pressable row a `trailing` control and the row **splits**: it stays a `<div>`, the title region becomes the `<button>` or `<a>` (`.nn-row__main`), and the trailing slot is its sibling. A button inside a button is invalid, unpredictable to activate, and collapses to one element for VoiceOver.

| row | renders |
| --- | --- |
| not pressable | `div.nn-row` |
| pressable, no trailing | `button.nn-row` or `a.nn-row` |
| pressable, with trailing | `div.nn-row[data-split]` > `button.nn-row__main` + `.nn-row__trail` |

Press, hover and the focus ring move to `.nn-row__main` in a split row, so only the part that acts looks pressable. Pass `label` when the title alone is not a clear name for the action.

## Rules
- A row never draws its own surface: it sits in `Card layout="list"`, which supplies the panel, the padding and the hairline between rows.
- One trailing element, or two labelled buttons (an accept/decline or resend/revoke pair): the positive action `primary solid`, the other `secondary soft`. Never an unlabelled ✕ in a row: say what it does ("Decline", "Revoke", "Remove"). More than two is a card, not a row.
- `inactive` dims what describes the row, never what acts: someone invited and not yet joined sits at the end of the member list with a dimmed lead and a live "Remind". There is no separate "Invited" section inside a member list.
- Meta is one clipped line unless the sentence is the content (`metaLines: null`). `metaAccent` carries one emphasised run at the end of the meta; it is the only way to colour part of a meta line.
- The title is sans. A person at the top of a sheet is a bare row, not a ListRow in a Card: Avatar `lg`, a `serif-sm` name (`serif-md` on the member sheet), a `sans-sm` `text-tertiary` meta line and a `primary-text` chevron at `spacing-14` minimum height (the app's PersonHeaderRow).
- A suggested party is a Subject row whose meta ends with the reason it was suggested, and a Follow button in `trailing`.
- A row does not repeat what its section header already says: an invite row under an "Invited" header needs no Pending badge, and a row in a "Favourites" list needs no heart.
- `value` and `trailing` are alternatives: a number goes in `value` (tabular), a control goes in `trailing`.
- `unread` is the only row state with colour, and it is a dot — never a tinted ground.
- A destructive row is `tone="destructive"` with no icon; the word carries it.
- Rank numerals go in `leading` as `Text serif-xs numeric`, never as a Badge.

## Use
```js
h(N.Card, { layout: 'list' },
  h(N.ListRow, { leading: h(N.Avatar, { name: 'Elin', size: 'sm' }), title: 'Elin', meta: 'Tue 29 Sep',
    trailing: h(N.ScoreValue, { score: 83, size: 'xs' }) }),
  h(N.ListRow, { title: 'Weekly digest', meta: 'Every Sunday', chevron: false, trailing: h(N.Toggle, { defaultChecked: true, label: 'Weekly digest' }) }),
  h(N.ListRow, { title: 'Member since', value: 'Mar 2026' }))

// Invited, not joined: last row of the member list
h(N.ListRow, { inactive: true, leading: h(N.Avatar, { name: email, size: 'sm' }), title: email, meta: 'Invited 2 days ago', chevron: false,
  trailing: h(N.AppButton, { size: 'sm', onClick: remind }, 'Remind') })

// Ingredient
h(N.ListRow, { title: 'Crushed San Marzano tomatoes, drained', value: '400 g', titleLines: null, valueSemibold: true, chevron: false })
```
Markup: `div|a|button.nn-row[data-size][data-tone][data-unread][data-pressable][data-split]` with `.nn-row__main` (split rows only), `.nn-row__lead`, `.nn-row__body`, `.nn-row__value`, `.nn-row__trail`, `.nn-row__chevron`.
