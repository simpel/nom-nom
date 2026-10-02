A dinner party at a glance: who is in it, how it is scoring, what it has cooked lately.

**Built from:** Card · Avatar `lg` · Text · ScoreValue · PhotoCard `xs` · AppButton · `.nn-scroller`.

Replaces PartyCard and CurrentPartyHeroView.

## Two modes

| `mode` | shows | action |
| --- | --- | --- |
| `mine` (default) | the party's ScoreValue beside its name | the whole head is the link into it |
| `discover` | no score — you have not eaten there | "Ask to join", a sibling of the link |

## Axes

| prop | values |
| --- | --- |
| `name` · `titleAs` | the party and its heading level (`h3` by default) |
| `avatar` | Avatar props; falls back to initials of `name`, and is decorative because the name is right there |
| `memberCount` · `meta` | joined with " · " into the line under the name |
| `summary` | two lines at most, `sans-sm secondary` |
| `recentMeals` | PhotoCard props; a scrolling row of `xs` squares |
| `onClick` / `href` | opens the party |
| `onJoin` | `discover` only |

## Rules
- **The card is never the control.** With `onClick` or `href` the head and summary become one button or link and the join button is its sibling — the ListRow split rule. A join button inside a pressable card is a button inside a button.
- `discover` shows no score: a party you have not eaten with has no score that means anything to you.
- Recent meals are photos only, no verdicts. The score above already says how it went.
- Summary is two lines, clamped. A longer description belongs on the party's own screen.

## Use
```js
h(N.PartyCard, { name: 'Thursday supper club', score: 82, memberCount: 6, meta: 'Cooked 3 times this month',
  recentMeals: meals, href: '/parties/thursday' })

h(N.PartyCard, { mode: 'discover', name: 'Pasta people', memberCount: 12,
  summary: 'Weeknight pasta, mostly.', onJoin: ask, href: '/parties/pasta' })
```
Markup: `.nn-card.nn-party-card[data-mode]` > `a|button.nn-party-card__main` > `__head` + summary, then `__meals.nn-scroller`, then the join AppButton.
