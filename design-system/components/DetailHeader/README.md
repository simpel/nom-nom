The top of a detail screen — a meal, a recipe or a dinner party: optional avatar and eyebrow, meta line, serif title, summary, fact badges and up to two actions.

**Built from:** Avatar, SectionHeader, Text (meta and facts), Badge (statuses), AppButton (actions).

Evolved from the Meal Detail Redesign's MealHeader (renamed, since it now heads every detail screen); the recipe and party examples follow `RecipeDetailView.swift` and `PartyDetailHeader.swift`. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `align` | `start` · `center` | `start` |

## The consumer provides
`title`; optional `eyebrow` (category), `meta`, `summary`, `avatar` (Avatar props, `xl` unless given), `facts` (plain strings), `badges` (Badge props, `secondary` by default) and `actions` (AppButton props, rendered `lg` and sharing the row).

## Recipes

| screen | align | parts | actions |
| --- | --- | --- | --- |
| Meal | `start` | meta (date · party) above the title (the table's verdict as a sentence), summary | `primary solid` "Rate this meal"; after rating `primary soft` "You rated 90" |
| Recipe | `start` | eyebrow (cuisine), title (the dish), meta ("Last cooked 28 Aug 2026 · 6 times", or "Never cooked"), facts (time, method), badges (the rotation goal, when it is a status) | `primary solid` "Use in a meal" with plus |
| Dinner party | `center` | avatar (cover photo or initial), title (party name), meta ("6 members · 12 followers · Private"), summary (about) | members: "Log a meal" + `secondary soft` "Invite"; others: "Follow" |

## Facts are not badges

A fact about the subject — 30–60 min, Baking, 4 servings — is **a line of metadata**, `sans-sm` `text-tertiary`, parts joined with " · ". The same facts in RecipeLinkCard already read that way; as chips they were the same information in two treatments, and a row of five grey capsules reads as five things to act on when none of them is.

`badges` is the separate slot for the few things that genuinely are a status: **Staple**, **Pro**, **Archived**. A status is something that could change about the subject and that you would want to spot at a glance. A duration is not.

Rule of thumb: if it would sit comfortably in a sentence after the title, it is a fact. If it is a label the subject carries, it is a badge.

## Rules
- Label: a SectionHeader (uppercase, `as: 'span'`); meta `sans-sm` `text-tertiary` — above the title, or below it when there is an eyebrow or avatar; title `serif-lg`; summary `sans-md` `text-secondary`.
- Inset `spacing-2`, gap `spacing-2`; actions `spacing-2.5` below, full width, two actions split it evenly.
- One `solid` action per header. Facts are Badges (`sm` icon allowed), never buttons.
- Photos sit above the header in a PhotoStrip; the header never carries a photo except the party avatar.

## Use
`NomNom.DetailHeader` — props are `DetailHeaderProps` in `components/index.d.ts`. Markup: `header.nn-detail-header[data-align]` > `.nn-avatar`, `.nn-section-header`, `.nn-text` (meta `sans-sm` tertiary), `h1.nn-text` (`serif-lg`), `p.nn-text` (summary), `.nn-text.__facts`, `__badges` > `.nn-badge`, `__actions` > `.nn-button`.
