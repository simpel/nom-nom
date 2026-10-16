The form blocks: FieldGroup (labelled plain fields in one card), ToggleCard (one setting and the sentence that explains it) and AccountActions (sign out, delete account).

**Built from:** Section · Card `list` · Input `plain` · ListRow · Toggle.

Drawn in the iOS app first; the SwiftUI view is the source of truth for behaviour. React in `components/bundle.js`, styles in `bundle.css`.

## FieldGroup
`fields: [InputProps…]` rendered as `plain` Inputs, one per row of a `Card layout="list"`, under an optional Section `title` and a `hint` under the card. Name fields, a party's name and About. A field in a card is always `plain`; the row draws the ground.

## ToggleCard
`heading` (the Section label), `title`, `meta`, `footnote`, `checked` + `onChange`. A Card holding one ListRow with a Toggle and a `sans-sm` sentence saying what the setting does ("Anyone with the link can follow this party"). Use for visibility; for several settings use a Card list of Toggle rows.

## AccountActions
`onSignOut`, `onDelete`. A Card list of two destructive rows, no icons ("Sign out", "Delete account"). It is the last block of a screen (screen anatomy, step 7); both actions confirm with a native alert.

## Use
`NomNom.FieldGroup`, `NomNom.ToggleCard`, `NomNom.AccountActions`.
