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
- A photo fills the circle, cropped from centre; without one, `primary-soft` ground and `primary-text` text. `border-hairline` (1px) `line` ring at 30% on both (never 0.5px).
- Text is at most two characters. With an empty `name` the avatar is a bare `primary-soft` circle, not "?" (onboarding before the name is typed).
- The circle is fixed and does not scale with Dynamic Type.

## Loading
An avatar whose photo is being made (the meal editor's recipe avatar while its AI photo is generated) draws the `sunken` Skeleton ground and sweep in the circle, as PhotoCard does, so the cuisine fallback does not flash first. VoiceOver reads "Photo loading". No caption.

## Edit mode (`xl` only, via ScreenHeader `avatarEdit`)
Onboarding's profile step, your own profile and the dinner party header make the avatar editable. The whole 80pt avatar is the button (press `opacity-70`), with a camera badge on its top-right: a `spacing-8` circle in AppButton `elevated` paint (`panel`, `text-primary`) lifted with `shadow-md`, its centre on the circle's edge at 45°, a `camera` glyph at `sans-xs` semibold, visual only (the avatar is the target, so the 44pt floor holds). Tapping opens the camera (front camera) with a library button floating top-trailing over its controls; that button closes the camera and opens Photos; with no camera it opens Photos directly. Remove photo lives in the avatar's long-press menu and as an accessibility action. A party's new photo becomes its cover. While choosing, the avatar shows the picked photo as a local preview.

## Use
`NomNom.Avatar` — props are `AvatarProps` in `components/index.d.ts`. Markup: `span.nn-avatar[data-size]` (+ `data-chars`) with text or an `img`.
