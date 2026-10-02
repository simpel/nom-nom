The title block of a screen with no subject: sign-in, onboarding, the paywall.

**Built from:** SectionHeader (the eyebrow) · Text (the h1 and the sentence) · AppButton (the actions). It draws nothing of its own.

Replaces PageHeader and PageHeading, which the system previously listed as not synced.

## Why this is a component and not loose markup

It is a composition — so are Section, SectionCard, EmptyState and DetailHeader. What makes it worth a name is the set of decisions it fixes, each of which was being made differently on every screen:

- **One `h1` per screen**, and it is this. Nothing else on a subject-less screen is an `h1`.
- **The type steps**: `serif-lg` title (`serif-md` at `size="sm"`), `sans-md secondary` sentence. Not a free choice.
- **The measure**: the sentence is capped at `container-sm`, so it never runs the full width of a tablet.
- **The actions**: first `primary solid`, the rest `ghost`, `lg` at `md` and `md` at `sm`, full width when centred — the sign-in, onboarding and paywall buttons all sized differently before.
- **The spacing**: `spacing-2` between the parts, `spacing-4` before the actions.
- **The boundary against DetailHeader**, which is the header for a screen that *is* about something.

If any of those should differ per screen, they belong here as an axis, not as a local override.

## Axes

| prop | values | default |
| --- | --- | --- |
| `title` | `serif-lg` (`serif-md` at `size="sm"`) | — |
| `subtitle` | one sentence, `sans-md secondary`, capped at `container-sm` | — |
| `eyebrow` | uppercase SectionHeader above the title | — |
| `actions` | `[{ label, onClick \| href, icon?, variant? }]` — first solid, rest ghost | — |
| `align` | `start` · `center` (actions stack full width) | `start` |
| `size` | `sm` · `md` | `md` |
| `children` | anything under the block (a form, a package list) | — |

## Rules
- A screen **about something** — a meal, a recipe, a party — uses DetailHeader, which carries the subject's photo, avatar and badges. PageHeader is for screens that have no subject.
- Subtitle is one sentence in the household voice. Two sentences means the second belongs further down the screen.
- `center` is for the full-screen moments only (sign-in, onboarding, paywall); in-app screens are `start`.
- Never over a photo and never with a scrim: the title sits on `bg`.
- The eyebrow is `tracking-widest` uppercase — the only uppercase on the screen.
- Two actions at most. A third is a link in the content below, not a button here.

## Use
```js
h(N.PageHeader, { title: 'What did you eat tonight?', subtitle: 'Log it now and rate it when everyone has finished.' })

h(N.PageHeader, { align: 'center', eyebrow: 'Nom Nom Pro', title: 'Cook with the whole picture',
  subtitle: 'Trends, party scores and unlimited photos.',
  actions: [{ label: 'Try Pro free', variant: 'pro', onClick: start }, { label: 'Not now', onClick: dismiss }] })
```
Markup: `header.nn-pagehead[data-align][data-size]` with `.nn-section-header`, `.nn-text`, `.nn-pagehead__actions`.
