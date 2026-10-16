An inline message the person can close, in the `warning` role: the one place a recoverable problem is told to the person without stopping them.

**Built from:** Text · AppButton `secondary ghost` icon-only.

Drawn in the iOS app first (the recipe details step after a scan that could not read the ingredients or steps); the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
The sentence (children) and `onDismiss`. Omit `onDismiss` and the notice hides itself.

## Rules
- Ground `warning-soft`, copy `warning-text` `sans-sm`, `radius-3xl`. Padding `spacing-5` leading, `spacing-3` above and below the copy; the Dismiss button sits at the trailing edge, `spacing-1` in.
- Dismiss is an icon-only AppButton `secondary ghost` (the one 44pt size), named "Dismiss". No icon before the copy, no title: one sentence that says what happened and what the person can do.
- `warning` marks a problem the person can recover from as well as a negative change. It is not for errors that block (an alert), nor for information (plain text), nor for success.
- A notice sits in the content flow where the problem is, never over it, and never more than one per screen. It carries no action of its own: if the person can fix it, the sentence says where.
- It is not a Badge (one word), not a Card (no tinted role) and not an EmptyState (a blank screen). `role="status"`, so assistive tech reads it once without taking focus.

## Use
`NomNom.DismissibleNotice` — props are `DismissibleNoticeProps` in `components/index.d.ts`. Markup: `.nn-notice` > `.nn-notice__text` + `button.nn-button` (icon-only).

```js
h(NomNom.DismissibleNotice, null, 'We could not read the steps. Add them below.')
```
