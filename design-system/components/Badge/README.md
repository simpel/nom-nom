The one badge: a small capsule that labels or rates something — one word, one number or one short phrase, never a number and a word together.

**Built from:** Icon.

Defined by the design system; replaces Chip, SubtleCapsuleLabel, ProBadge, RotationPill, RecipeVerdictBadge, ScoreBadge, DeltaChip and the VerdictStrip capsules. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `variant` | `primary` · `secondary` · `destructive` · `pro` · `warning` · `reaction` | `primary` |
| `reaction` | `inedible` · `bad` · `meh` · `good` · `great` · `amazing` (with `variant="reaction"`) | — |
| `appearance` | `soft` · `solid` · `elevated` | `soft` |
| `size` | `sm` · `md` | `md` |
| `icon` + `iconPosition` | glyph name · `start` / `end` | — · `start` |

| size | height | side padding | label | icon |
| --- | --- | --- | --- | --- |
| `sm` | `spacing-5` (20) | `spacing-2` | `sans-xs` semibold | `text-xs` |
| `md` | `spacing-6` (24) | `spacing-2.5` | `sans-xs` semibold | `text-xs` |

- `soft` = `{role}-soft` + `{role}-text` — the default for everything.
- `solid` = `{role}` + `on-{role}` — the strongest step of an ordinal (rotation goal "Staple"). Falls back to soft for `reaction`: a reaction fill never carries text.
- `elevated` = `panel` + `shadow-xs` + `{role}-text` — over photos and heroes; for `reaction` the ground is the step's fill at 15% over `panel`, so verdicts stay colour-coded on a photo.
- Outline and ghost are button appearances only. Always `radius-full`, tabular figures, sentence case.

## What is and is not a badge

A badge is a **label the thing carries**: it could change, and you would want to spot it at a glance across a list. A fact about the thing is text.

| | |
| --- | --- |
| badge | a verdict (Great), Pro, Archived, New, a signed change (+4) |
| not a badge | a duration, a method, a servings count, the rotation goal — these are Facts; a cuisine is a ScreenHeader eyebrow; a date is the ScreenHeader date |

Two tests, and it has to pass both: would you scan a list for it, and could it be different tomorrow? "30–60 min" fails the first; "Baking" fails both.

The signed change (`deltaBadge`) stays a badge on purpose, even though it is a number: its colour is the message — `primary` up, `warning` down, `secondary` flat — and that only works in a capsule. A number whose colour means nothing belongs in text.

Audited uses, all current: PhotoCard's verdict, RatingList's "New" and delta. The old header's `facts` and rotation badge are now the Facts component; SegmentedBar's legend keys used to be reaction badges and are now a swatch and a label, because a key names a slice of a chart rather than labelling the row it sits in.

## Recipes (what the old badges become)

| need | Badge |
| --- | --- |
| Metadata chip (diet, time, method) | `secondary` or `primary` · `soft` · `sm`, optional icon |
| Fact over a photo or hero (date, duration) | `secondary` · `elevated` · icon start |
| Nom Nom Pro | `pro` · `soft` · sparkles icon · "Pro" |
| Rotation goal | not a badge: a Facts item ("Rotation · Staple"), plain `text-primary` |
| Verdict | `reaction` + `reactionForScore(score)` · label = the word only (≥85 Amazing, ≥70 Great, ≥50 Good, ≥30 Meh, ≥15 Bad, else Can't eat); on a photo `elevated sm` (RecipeCard) |
| Score | the numeral sits in type (ScoreCard, RatingList, Timeline), not in a badge |
| Dish summary | ≥60% Great/Amazing and no negatives: effort 0–15 → "Quick win" (`primary`, bolt) · staple → "Household favorite" (`reaction` amazing, star) · over 60 → "Showstopper" (`primary`, sparkles) · else "Crowd pleaser" (`reaction` great, thumbs-up). Otherwise staple → "Household staple", 0–15 → "Fast & easy", over 60 → "Weekend project" (`primary`) · only negatives → "Needs revision" (`secondary`, wrench) · any ratings → "Solid dish" (`primary`) |
| Change since last time | the signed number alone: up `primary`, down `warning`, flat `secondary`, with a true minus (−2, +16, ±0) |
| Rank | `secondary` `sm` star icon + ordinal ("3rd") |

## Rules
- One idea per badge: a number or words, never both ("83 · Great" is two badges, or a numeral in type beside a word badge).
- The number or word is the message; colour only confirms it. Every reaction badge shows its verdict word.
- Violet (`pro`) means Pro and nothing else. `warning` is for negative change, not for errors.
- Badges are not buttons: never tappable. A selectable pill is a `sm` AppButton.

## Use
```js
h(NomNom.Badge, { variant: 'reaction', reaction: 'great', size: 'sm' }, 'Great')
h(NomNom.Badge, { variant: 'pro', icon: 'sparkles' }, 'Pro')
h(NomNom.Badge, { variant: 'warning' }, '−2')
```
Markup: `span.nn-badge[data-variant][data-appearance][data-size]` (+ `data-reaction`, `data-icon-position="end"`) containing `.nn-icon` and the label.
