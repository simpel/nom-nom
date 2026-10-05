The top of every screen and sheet: an optional avatar and eyebrow, the serif title, an optional date and sentence, and up to two actions. One component, one rule for alignment, nothing else above the content.

**Built from:** Avatar · SectionHeader (the eyebrow) · Text (title, date, sentence) · AppButton (actions). It draws nothing of its own.

Replaces PageHeader and DetailHeader. The two had drifted: meta above the title on one screen and below it on the next, centring with no rule, facts and badges in one and not the other, full-width buttons with icons in one and hugging buttons in the other. There is now one header and every screen opens the same way.

## Slots, in this order

Every slot is optional except `title`.

| slot | set as | rule |
| --- | --- | --- |
| `avatar` | Avatar `xl` | A person or a party. Its presence centres the header. |
| `eyebrow` | SectionHeader, uppercase, `tracking-widest`, `text-tertiary` | **One** item. See Eyebrow below. |
| `title` | Text `serif-lg` | The screen's only `h1`. Names the subject, in context: a tab root scoped to the current party says whose ("Meals at The Friday Feast Club"), never just the tab's name, which the tab bar already shows. |
| `date` | Text `sans-sm` `text-tertiary` | A date and nothing else. Pass a `Date`; the header formats it "Sunday 4 October", adding the year only when it isn't this year. |
| `summary` | Text `sans-md` `text-secondary`, capped at `container-sm` | One sentence in the household voice. |
| `actions` | AppButton `md`, label only | At most two, at most one `solid`. See Actions below. |

There is no `meta`, `facts`, `badges`, `align`, `size` or children slot, and the header never carries a photo. Facts about the subject are the Facts component, further down the screen. Counts and history (members, followers, last cooked) are not shown in the header.

## Alignment

The `role` says what kind of screen the header opens, and the role decides alignment. There is no `align` prop to reach for.

| role | screens | alignment |
| --- | --- | --- |
| `standard` (default) | detail screens and sheets | start, unless there is an avatar |
| `tabRoot` | Meals, Recipes, Parties | centred, always with a one-sentence `summary` |
| `moment` | a full-screen flow outside the tab bar: sign-in, email sign-in, the onboarding steps, the Pro paywall | centred |

**An avatar also centres the header**, whatever the role: party and person screens.

## Eyebrow

The eyebrow says what the subject is or where it lives. It is strict.

| allowed (exactly one) | example |
| --- | --- |
| the subject's **category** | ITALIAN |
| the **context** it lives in: its parent | THE FRIDAY FEAST CLUB |

| never | why |
| --- | --- |
| two items joined with " · " | one line, one idea |
| a date | it has its own slot |
| a flow or product name (NOM NOM PRO, STEP 2 OF 3) | the title does that job |
| a status, a count, a person | not the subject's kind or home |
| a verb, a sentence, an icon, the title again | it is a label |

It is one line and never truncates. If it doesn't fit, it is the wrong text.

## Actions

- At most two. At most one `solid` (the one main commitment on the screen); the other is `secondary soft`, or a lone `secondary soft` when there is no commitment ("Edit profile").
- `md`, label only. **No icons** in header buttons, ever.
- Buttons hug their label and never grow. They sit on **one row**, `spacing-2` apart, aligned with the header: left when it starts, centred when it centres. They never wrap or stack. Two labels that don't fit on one row at phone width get shorter labels.
- A `loading` state is fine ("Following" while it saves).

## Spacing

| between | token |
| --- | --- |
| avatar → the text below it | `spacing-4` |
| eyebrow → title, title → date, date → summary | `spacing-2` |
| → actions | `spacing-4` |
| header → the next block | `spacing-7` (the screen's block gap) |

No side inset of its own: the header sits on the screen's `spacing-4` gutter.

## Where it sits

Second in the screen anatomy (root README, "Screen anatomy"): after the chrome (back and more, or a sheet's close and confirm), before the photos. Never over a photo, never with a scrim, always on `bg` or `sheet`.

## Every header in the app

| screen | avatar | eyebrow | title | date | summary | actions |
| --- | --- | --- | --- | --- | --- | --- |
| Meals / Recipes / Parties (`tabRoot`, centred) | — | — | Meals at The Friday Feast Club · Recipes for The Friday Feast Club · Your dinner parties ("Your meals" / "Your recipes" with no party) | — | what the tab holds, one sentence | Log a meal / New recipe / New party |
| Meal | — | THE FRIDAY FEAST CLUB | the dish | the meal's date | — | Rate this meal (`solid`); after rating "You rated 90" (`soft`) |
| Recipe | — | AMERICAN | the dish | — | — | Start cooking (`solid`) · Use in a meal (`secondary soft`) |
| Dinner party | the party | — | the party name | — | its about line | Add meal; others Follow / Following |
| Person | the person | — | their name | — | — | Edit profile (`secondary soft`, own profile) |
| Rate meal (sheet) | — | — | the dish | the meal's date | — | — (photos follow below) |
| New party, Inbox, scanner (sheets) | — | — | the sheet's subject | — | one sentence | — |
| Sign-in, onboarding, paywall (`role: moment`) | — | — | Nom Nom / the step | — | one sentence | — (the flow's own buttons sit below) |

## Use
```js
h(N.ScreenHeader, { role: 'tabRoot', title: 'Meals at The Friday Feast Club', summary: 'What you\u2019ve cooked and what\u2019s left to rate.',
  actions: [{ label: 'Log a meal', onClick: log }] })

h(N.ScreenHeader, { eyebrow: 'The Friday Feast Club', title: 'Double Smash Burgers', date: new Date(2026, 9, 4),
  actions: [{ label: 'Rate this meal', onClick: rate }] })

h(N.ScreenHeader, { avatar: { name: 'The Friday Feast Club', photo: cover }, title: 'The Friday Feast Club',
  summary: 'A weekly gathering of home cooks, every Friday night.', actions: [{ label: 'Add meal', onClick: add }] })

h(N.ScreenHeader, { role: 'moment', title: 'Cook with the whole picture', summary: 'Trends, party scores and unlimited photos.' })
```
Markup: `header.nn-screen-header[data-align]` > `.nn-avatar`, `.nn-section-header`, `h1.nn-text`, `p.nn-screen-header__date`, `p.nn-screen-header__summary`, `.nn-screen-header__actions` > `.nn-button`.
