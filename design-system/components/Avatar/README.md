A circle that shows a photo, or text when there is none — initials from `name` in Newsreader on `primary-soft` — in five sizes, xs to xl.

**Built from:** —

Merges `apps/ios/NomNom/Core/Components/UserAvatar.swift` and `PartyAvatar.swift` (both removed here); it doesn't know what it depicts. React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `size` | `xs` · `sm` · `md` · `lg` · `xl` | `md` |

| size | diameter | text |
| --- | --- | --- |
| `xs` | `spacing-6` (24) | `sans-xs` semibold |
| `sm` | `spacing-8` (32) | `sans-xs` semibold |
| `md` | `spacing-10` (40) | `serif-xs` |
| `lg` | `spacing-14` (56) | `serif-sm` |
| `xl` | `spacing-20` (80) | `serif-lg` (one character) · `serif-md` (two) |

## The consumer provides
`name` (required: the accessible name; its first and last word give the initials, one letter for a one-word name), optional `photo`, optional `text` (shown instead of the initials), `size`.

## Rules
- A photo fills the circle, cropped from centre; without one, `primary-soft` ground and `primary-text` text. 0.5px `line` ring at 30% on both.
- Text is at most two characters.

## Use
`NomNom.Avatar` — props are `AvatarProps` in `components/index.d.ts`. Markup: `span.nn-avatar[data-size]` (+ `data-chars`) with text or an `img`.
