The one small label, the same wherever it sits: a `sans-xs` title in `text-tertiary`, uppercase by default, optionally with an icon before it and a figure on the right. Both the title and the figure are Text — the component sets no type of its own, only the casing, the tracking and the layout. It is both the heading above a list and the eyebrow inside a card.

**It is a Text, an optional glyph and an optional Text — nothing else.** It draws no ground, no border and no card. It also reserves no space around itself: both the surface and the spacing belong to whatever places it — a Section, a Card, a SectionCard, a ScreenHeader.

**Built from:** Text (the title and the figure), Icon.

## One label, everywhere

There used to be two: `SectionHeader` above content and `Eyebrow` inside a card. They differed only in the element and two spacing values, which meant every call site had to decide which to reach for and got it wrong about as often as right.

Now there is one. It draws no surface and **reserves no space around itself** — the parent places it:

| the label sits | write | who supplies the spacing |
| --- | --- | --- |
| above a list, a card, a strip | `<Section title="Ingredients" trailing="6 items">…</Section>` | Section: `spacing-2` side inset, `spacing-2` below |
| inside a card | `<SectionCard title="Household verdict">…</SectionCard>` | the Card's own padding |
| anywhere else | `<SectionHeader as="span" title="Italian" />` | whatever you place it in |

`as` is the one thing a call site still chooses: `h2` above content, `span` inside a card or header, so the document outline stays right.

## Axes

Three axes: **case**, **trailing** and **emphasis**.

| axis | prop | values | default |
| --- | --- | --- | --- |
| case | `uppercase` | `true` (uppercase + `tracking-widest`) · `false` (as written) | `true` |
| trailing | `trailing` + `trailingVariant` | — · a figure, `text-tertiary` · a figure, `primary-text` for a live count | — · `secondary` |
| emphasis | `variant` | — · `primary` (title `primary-text` semibold) | — |

Plus `title`, an optional `icon` before it, and `as` (the title element — `h2` above content, `span` inside a card or header).

| trailing | reads as |
| --- | --- |
| none | "INGREDIENTS" |
| `secondary` | "INDIAN · by Anna", "INGREDIENTS · 6 items" |
| `primary` | "WHO RATED · 5 of 6" |

## The section action: `count` and `action`

A section that the viewer can add to (or open) carries **one verb on the right of its header**; the count follows the title on the left. This is the one pattern for "Add a recipe", "New dinner party", "Log a meal" and "See all" on every section, so no screen invents its own.

| prop | values |
| --- | --- |
| `count` | the figure after the title, `text-tertiary`, tabular. **Leave it out by default**: "MEAL HISTORY 31" adds nothing the list does not show. Use it only for a number the person acts on ("WAITING FOR YOUR RATING 3") |
| `action` | `{ label, onClick, 'aria-label'? }`: an AppButton `primary soft sm`, one or two words in sentence case ("Add recipe", "New party", "Log meal", "See all"). `aria-label` names the noun for VoiceOver |

| section state | where the verb lives |
| --- | --- |
| has items, viewer can act | the header `action` |
| empty, viewer can act | the EmptyState's `action`, with the same verb; the header action is **not** drawn |
| empty, viewer cannot act | the EmptyState with no action |
| has items, viewer cannot act | no action; the header is the label and count only |

- **One action per header, never an icon.** A section that offers both "See all" and "Add" keeps "Add"; "See all" moves to the foot of the list.
- It is a real, visible 44pt capsule (`primary-soft` ground), not bare text: the header row grows to `spacing-11` to hold it, nothing overhangs, and its right edge lines up with the card's right edge. A ghost text button was tried and dropped: it read as a caption and its target was invisible.
- A list card may also open with an AddRow (a plus and the verb, 56pt, full width) on screens whose whole job is adding, such as My recipes; the header action is still the rule everywhere else.
- The verb names what the section holds in one word; the screen's own primary commitment ("Log a meal" in the ScreenHeader) stays there. A section action never duplicates a ScreenHeader action on the same screen.
- Viewer permission decides it: pass `action` only when the person can act (their own profile, a party they belong to). Do not draw it disabled.
- This relaxes "never a button" in the trailing slot below: `trailing` is still a figure; `action` is the slot for a verb.

## Rules
- **One label per surface.** A card gets one, at the top. Two small uppercase labels in the same card compete and neither reads as the heading.
- **At most one thing to the right of it.** The trailing slot takes a figure — a count, a byline, a score — not a second label and never a button. If a card needs a category, an author and a score, the category is the label and the rest belong with the content they describe, not crowded onto the label's line.
- Uppercase for categories and section names; normal case for possessive or personal labels ("Joel's note"). Same size and colour either way.
- The title truncates before the trailing figure does: the number is the part that must stay readable.
- `variant: 'primary'` recolours the label only; it does not tint anything. Use it when the surface around it is already a `primary` card, and on one label there.
- The component never paints a background. If a label needs a surface, the surface is a Card the consumer places — SectionCard exists for exactly that pairing.

## Where each appears
- Above content, via Section: RatingList ("Who rated · 5 of 6"), Timeline ("This recipe over time · 3 times"), SegmentedBar, any list.
- Inside a surface, as `span`: ScreenHeader's eyebrow ("ITALIAN"), Facts labels ("SERVES"), RecipeCard (category, "by Anna" trailing), RecipeLinkCard ("RECIPE"), ScoreCard title (with icon; `primary` when featured), SectionCard ("Joel's note", `uppercase: false`).

## Use
`NomNom.SectionHeader` — props are `SectionHeaderProps` in `components/index.d.ts`. Markup: `.nn-section-header` (+ `data-case="normal"`, `data-variant`; `.nn-section__head` when a Section places it) > `.nn-text.__title` (`.nn-icon` + text), `.nn-text.__trailing`.
