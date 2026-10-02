A sheet over the screen for detail on demand — here, why one person scored a meal the way they did.

**Built from:** AppButton (close), Text, ScoreValue `lg`, ProgressBar `md`; SheetCard = Card + Text; Reason = Text.

New from the Meal Detail Redesign canvas (not yet in the SwiftUI code); React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
A title, the hero (numeral + verdict + one sentence), and content cards (e.g. reasons: a title and a sentence each).

## Rules
- `scrim` behind; sheet on `sheet` with `radius-4xl` top corners, padding `spacing-2`/`spacing-5`/`spacing-10`, gap `spacing-6`; grabber `spacing-10` × `spacing-1.5` in `grabber`.
- Bar: AppButton `secondary soft iconOnly` close (x) on the left, title `sans-lg` semibold centred.
- Hero: ScoreValue `lg` (`serif-xl` numeral + `serif-sm` verdict) over a ProgressBar `md` — the same pair as ScoreCard — gap `spacing-3`; lead `sans-md` `text-secondary` with the key figure in 600 `primary-text` ("**16 above** Joel’s usual of 84").
- SheetCard is a Card; card title `serif-sm`, provenance `sans-xs` ("AI summary of Joel’s 54 past ratings"); reasons divided by `line`, title `sans-lg` semibold, text `sans-sm` `text-secondary`.

## Use
`NomNom.BottomSheet` — props are `BottomSheetProps` in `components/index.d.ts`. Markup it renders: `.nn-sheet-scrim` > `.nn-sheet` > `__grabber`, `__bar` (`.nn-button`, `h2.nn-text`), `__hero` (`.nn-score`, `.nn-progress-bar`, `p.nn-text.__lead`), `.nn-card.nn-sheet-card` (`.nn-text` × 2, `.nn-reason` > `.nn-text` × 2).
