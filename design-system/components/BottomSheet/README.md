A sheet over the screen for detail on demand — here, why one person scored a meal the way they did.

**Built from:** AppButton (close), Text, ScoreValue `lg`, ProgressBar `md`; SheetCard = Card + Text; Reason = Text.

New from the Meal Detail Redesign canvas (not yet in the SwiftUI code); React in `components/bundle.js`, styles in `bundle.css`.

## The consumer provides
A title, the hero (numeral + verdict + one sentence), and content cards (e.g. reasons: a title and a sentence each).

## Rules
- `scrim` behind; sheet on `sheet` with `radius-4xl` top corners, padding `spacing-2`/`spacing-5`/`spacing-10`, gap `spacing-6`; grabber `spacing-10` × `spacing-1.5` in `grabber`.
- Bar: AppButton `secondary soft iconOnly` close (x) on the left, title `sans-lg` semibold centred.
- Hero ink: the score sheets paint the numeral in the score's `reaction-<step>-text` and the Bar as one `reaction-<step>-fill` segment (ScoreValue `ink="reaction"`), so the verdict reads at a glance; a Pro sheet's hero is `pro`. Everywhere else a score is `primary-text`.
- Hero: ScoreValue `lg` (`serif-xl` numeral + `serif-sm` verdict) over a ProgressBar `md` — the same pair as ScoreCard — gap `spacing-3`; lead `sans-md` `text-secondary` with the key figure in 600 `primary-text` ("**16 above** Joel’s usual of 84").
- SheetCard is a Card; card title `serif-sm`, provenance `sans-xs` ("AI summary of Joel’s 54 past ratings"); reasons divided by `line`, title `sans-lg` semibold, text `sans-sm` `text-secondary`.

## Sheet types and how they dismiss (from the app)

The bar is not drawn with AppButton on iOS: every top-bar control (close, back, Next, checkmark, heart, "…", filter) is a system toolbar button on the platform's white glass circle with a `text-primary` glyph. The close sits alone on the leading side; a primary action (`+`, checkmark, Next) on the trailing side. The `secondary soft iconOnly` close above is the web rendition.

| sheet | leading | trailing | swipe to dismiss |
| --- | --- | --- | --- |
| Commit / form / editor (edits, ratings, filters) | close (asks first when changed) | checkmark, or a spinner while saving; an unchanged edit just closes | free while unchanged; asks once changed; blocked while saving |
| Multi-step, first step | close (asks first when changed) | "Next", disabled until the step is valid | as above |
| Multi-step, middle step | back | "Next" | as above |
| Multi-step, last step | back | checkmark or spinner | as above |
| Note editor (one multi-line note) | close (asks first when changed) | checkmark | as above |
| Read-only (explanations, insights) | close | none | free |
| Picker (choosing dismisses) | close | optional primary action | free |
| Overview (a modal list) | close | optional primary action (`+`) | free |
| Media viewer (full-screen photos) | close | none | free |

- **Discard changes.** An edit sheet dismisses like Mail. Untouched, swipe and close work freely. Once changed, a swipe springs back, and both swipe and close ask a native confirmation dialog "Discard changes?" with "Discard changes" (destructive) and "Keep editing" (cancel). While saving nothing dismisses and the checkmark is a spinner.
- **Multi-step sheets** push one question per screen. A later optional step pins a full-width `secondary ghost` "Skip" to the bottom; a single-choice step advances a `duration-layout` beat after a pick. Each step reads the one state the sheet holds, so Back never loses an answer.
- **Media viewer.** A full-screen photo pager on a `stone-1000` ground, the bar at `opacity-90`, titled "Photo 2 of 5". It is the one viewer for every photo in the app.
- Grabber: `radius-sm`, `spacing-2` from the top, decorative.

## Use
`NomNom.BottomSheet` — props are `BottomSheetProps` in `components/index.d.ts`. Markup it renders: `.nn-sheet-scrim` > `.nn-sheet` > `__grabber`, `__bar` (`.nn-button`, `h2.nn-text`), `__hero` (`.nn-score`, `.nn-progress-bar`, `p.nn-text.__lead`), `.nn-card.nn-sheet-card` (`.nn-text` × 2, `.nn-reason` > `.nn-text` × 2).
