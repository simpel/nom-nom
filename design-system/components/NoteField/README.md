A form row for a multi-line note (meal notes, rating notes, party About, recipe steps) that opens the note editor sheet, the Apple Maps "Add a Note" way. NoteEditor is that sheet.

**Built from:** Text · BottomSheet · Card · TextArea `plain` · AppButton.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## NoteField
`value` shown as the cook's note (`serif-xs` italic, `text-primary`, 3 lines), else a `sans-md` `text-tertiary` `placeholder`; `bulleted` shows every bullet, unclamped. `spacing-14` minimum, no ground, no border, no chevron; it sits in its host SectionCard like a ListRow.

## NoteEditor
A BottomSheet (`kind` commit): inline title, close (asks "Discard changes?" once edited) and checkmark (commits), one `panel` Card with a `plain` TextArea, and, when there was text, a full-width `destructive soft lg` "Delete note" that confirms with a native alert. `bulleted` (or `formatBar`) swaps "Delete note" for the format bar above the keyboard: a `panel` capsule with `shadow-xs` holding icon-only `secondary ghost` buttons, a `destructive ghost` trash on the left (only when a note exists) and a bulleted-list button. Lists are plain text ("• " lines): Return continues, Return on an empty bullet ends it.

## Rules
- Multi-line text in a form is always a NoteField, never an inline TextArea.
- The editor has no ScreenHeader: the inline title is its header (Apple Maps).

## Use
`NomNom.NoteField`, `NomNom.NoteEditor`. Markup: `button.nn-note`; `.nn-format-bar`.
