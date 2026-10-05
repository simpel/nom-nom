The multi-line text field: Input's one style, radius, padding, text size and states, growing from 3 lines (the app grows 3–6).

**Built from:** Text (label, hint, error, counter), Icon.

Hand-written from `apps/ios/NomNom/Core/Components/TextArea.swift` as a React rendition (`components/bundle.js` + `bundle.css`); the SwiftUI view is the source of truth for behaviour.

## The consumer provides
`placeholder`, `value` / `defaultValue` + `onChange`, `rows` (default 3), optional `label`, `appearance` (`soft`; `plain` only inside a Card list row), `maxLength`, `hint`, `error` (boolean or the message), `readOnly`, `disabled`.

## States
Identical to Input — rest 1px `line`, hover 1px `line-control`, focus 2px `primary`, error 2px `destructive`, read-only borderless, disabled in `text-tertiary` — so a form of mixed fields moves as one. There is one style, `soft`, and the ground never changes — the border carries every state. See Input's state table.

`maxLength` adds a live `{n} / {max}` counter on the right under the field, tabular and `text-tertiary`. **Going over the limit is an error state, not a hard stop**: the field takes the 2px `destructive` border and the counter turns `destructive-text`, but the person keeps typing and keeps their words. Truncating what someone wrote about their dinner is worse than letting them edit it down.

## Rules
- Same as Input: `radius-xl`, side padding `spacing-3.5`, text `sans-md` (text-base, leading-normal), placeholder `text-tertiary`. Top padding `spacing-2.5`, so the first line sits where an Input's text does; never shorter than an Input.
- Label `sans-xs` `text-secondary` above the text, as on Input.
- Focus and error: 1.5px `primary` / `destructive` at `opacity-80`. Disabled: `opacity-50`, `text-tertiary`, not editable.

## In a form: the note row
A form never shows a TextArea inline. A multi-line note (meal notes, rating notes, a party's About, a recipe step) is a **note row** that opens a full-height editor sheet holding a `plain` TextArea, the way Apple Maps edits "Add a Note".
- **Filled:** the note is set as the cook's note, `serif-xs` italic in `text-primary`. This is the same style as SectionCard's `quote`, so a note looks the same while you write it and after you've saved it.
- **Empty:** the placeholder is `sans-md` in `text-tertiary`.
- At most 3 lines, `spacing-14` minimum height, no ground, no border, **no chevron**: the italic note is the affordance. It sits in its host SectionCard the way a ListRow does.

## Use
`NomNom.TextArea` — props are `TextAreaProps` in `components/index.d.ts`. Markup: `label.nn-field.nn-textarea` (+ Input's modifiers) > `textarea` (or `.nn-field__stack` > `__label` + `textarea`).
