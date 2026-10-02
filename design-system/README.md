Nom Nom is a dinner diary for a household: what you cooked, whether everyone ate it, and what to cook next. The iOS app (SwiftUI) is the product; the web (nomnom.casa) is its marketing and admin surface. The interface is a cool, quiet shell — Stone neutrals, one Pine accent, a Newsreader serif for anything editorial — so the food photography supplies all the warmth, and saturated colour means exactly one thing: how the food tasted.

## Content fundamentals

- **Plain, household voice.** Talk like the person who cooked: "Log a meal", "Email me a code", "Use a different address", "No photo yet", "Everyone finished their plate." Second person when you address the cook; the app never says "we".
- **Verdicts are fixed words.** The scale is −1 Can't eat · 1 Bad · 2 Meh · 3 Good · 4 Great · 5 Amazing. Use these labels (short form "Can't eat") and their numerals; never invent synonyms.
- **Casing.** Sentence case for buttons, badges and titles ("Log a meal", "Crowd pleaser", "Pro"). UPPERCASE only for section headers and category eyebrows ("POPULAR RECIPES", "ITALIAN").
- **No emoji. Anywhere.** Not in UI, reactions, verdicts, member badges, food items or status. The reaction scale is carried by numerals, words and colour.
- **Numbers are data.** Scores are 0–100 integers without "%"; counts read "12 meals"; durations "25 min". Every number that stacks in a column uses tabular figures. A badge holds a number or words, never both.

## Colour

- **`tokens.css` is generated from `tokens.json` by `build-tokens.py.txt` (a .py extension is not publishable here; copy it out and run it as `build-tokens.py`).** Never hand-edit it: a value added to the JSON and not regenerated silently resolves to nothing wherever it is used.
- Every semantic colour is a ramp step, not a loose hex: `bg` is `stone-100`, `line-control` is `stone-600`, `primary` is `pine-600`. A role that cannot name its step does not belong in the palette.
- Views consume the **semantic roles**, never the ramps: `bg` for the screen ground, `panel` for cards and rows, `sunken` for inputs and in-sheet buttons, `sheet` for bottom sheets, `line` for row dividers, `line-strong` for decorative rails, `line-control` for the border of anything a person can press or type in, `track` for unfilled bars. Light values come from the Meal Detail Redesign; dark values are the app's, with `panel` lifted to stone-900 so borderless cards still read.
- Text: `text-primary` for titles, names and verdict words, `text-secondary` for summaries and body, `text-tertiary` for meta, section labels, captions and placeholders. All three hold ≥4.9:1 on `bg`, `panel`, `sunken` and `sheet` in both themes.
- **Colour roles.** Every role has the same four tokens — `{role}` (fill), `{role}-soft` (tinted ground), `{role}-text` (text), `on-{role}` (text on the fill) — for `primary`, `secondary`, `destructive`, `pro` and `warning`. Components pick a role with `variant` and paint it with `appearance`.
- **Change has a direction, not a hue.** Up is `primary-text` (a `primary` Badge), down is `warning-text` (a `warning` Badge), unchanged is `text-tertiary`. The signed number always carries the meaning.
- **One accent, low chroma.** `primary` (Pine) is the main action, active tab, focused field and filled meter; `primary-text` is Pine-coloured text; `primary-soft` is the tinted ground that carries it. `secondary` is the Stone ink set for everything neutral. Pine is held at chroma ≤ 0.086 and 128° from the oak table in the photos so it never vanishes on an image.
- **High chroma is data.** The `reaction-*` ramp is the most saturated colour in the app, and the only one used across a whole scale. `destructive`, `pro` and the `chart-series` ramp are saturated too, each for one job: an irreversible action, the Pro label, a series in a chart. Each step has two roles: `reaction-<step>-fill` paints shapes (14–20% tint grounds, 2px (`border-thick`) selected borders, dots, the indicator bar); `reaction-<step>-text` is the ink for its numeral or word, ≥4.9:1 on `panel` and on its own tint in both themes. A solid fill never carries text. Reaction colour appears only in rating controls and one chip per card — it never tints a card, body text or a photo.
- Every reaction mark also shows its numeral or word; colour confirms, never carries, the message. **Unrated is a real state**: `sunken` ground, `text-tertiary`, dashed circle.
- Ordinal scales that aren't taste use weight, not hue: rotation goal is a Badge going `secondary soft` → `primary soft` → `primary solid`; effort is a four-bar monochrome meter in `primary` / `line-strong`.
- **Violet is Pro.** `pro`, `pro-soft`, `pro-text`, `on-pro` mark Nom Nom Pro (badges, gates, paywall) and nothing else. The chart palette excludes violet for the same reason.
- Charts: assign `chart-series1…7` by a stable index per party member, never cycled; the party total line is `primary`; gridlines are `line`.
- Keep UI colour out of the 40–90° hue band (oak and stoneware): it disappears into the photography. Three exceptions earn their place by being warnings or chart series, where being noticed beats being quiet: `warning-text` 44°, `warning-soft` 55°, `chart-series4` 75°.
- `destructive` is iOS system red darkened 15% at the same hue, used only for irreversible actions: white on it reaches 4.73:1 light and 4.55:1 dark, where the stock #ff3b30 gave 3.55:1. `destructive-text` is darker still so red text on a pale ground passes AA.
- **Scores are accent, not reaction colour.** ScoreCard, RatingList, Timeline and the sheet paint numerals in `primary-text`; the reaction ramp stays for rating controls and `reaction` verdict Badges.
- Dark `primary` is the light `pine-400` fill, so its ink is `pine-900`, not white: 5.16:1 against 2.98:1 for white. A solid primary button therefore reads dark-on-teal in dark mode and white-on-teal in light.
- **A line that carries meaning is `line-control`, not `line-strong`.** Outline buttons and the `oneAndDone` pill border hold at least 3:1 on `panel`, `bg`, `sunken` and `sheet` in both themes. `line-strong` stays deliberately faint for rails and other purely decorative rules, which WCAG exempts.
- No known contrast misses remain. Every text pair clears 4.5:1 (3:1 at 24px+) and every control border and focus ring clears 3:1, in both themes.

## Scales

Every size in the system is a **Tailwind** step, and every step is a token with Tailwind's own name, so `tokens.css` drops straight into a Tailwind v4 `@theme` and a web build can use the utilities as-is (`text-sm`, `p-5`, `rounded-3xl`, `shadow-xs`, `opacity-50`, `tracking-widest`). Off-scale values are not allowed.

| scale | tokens | Tailwind |
| --- | --- | --- |
| Font size | `text-xs` 12 · `text-sm` 14 · `text-base` 16 · `text-lg` 18 · `text-xl` 20 · `text-2xl` 24 · `text-3xl` 30 · `text-4xl` 36 · `text-5xl` 48 · `text-6xl` 60 | `text-*` |
| Weight | `font-weight-normal` 400 · `font-weight-semibold` 600 | `font-normal`, `font-semibold` |
| Border width | `border-hairline` 1 · `border-thick` 2 | the only two widths the system draws |
| Motion | `duration-press` 120ms · `duration-state` 150ms · `duration-layout` 250ms · `ease-standard` · `scale-press` .985 · `scale-press-row` .995 · `scale-knob` .92 | every transition uses one of these |
| Letter spacing | `tracking-tight` −0.025em (large serif) · `tracking-widest` 0.1em (overlines) | `tracking-*` |
| Line height (separate from size) | `leading-none` 1 · `leading-tight` 1.25 · `leading-snug` 1.375 · `leading-normal` 1.5 · `leading-relaxed` 1.625 | `leading-*` |
| Spacing | `spacing-N` = N × 0.25rem: 0.5 · 1 · 1.5 · 2 · 2.5 · 3 · 3.5 · 4 · 5 · 6 · 7 · 8 · 9 · 10 · 11 · 12 · 14 · 16 · 20 · 24 · 28 · 36 · 48 · 64 · 72 | `p-*`, `gap-*`, `w-*`, `h-*` |
| Radius | `radius-sm` 4 · `radius-lg` 8 · `radius-xl` 12 · `radius-2xl` 16 · `radius-3xl` 24 · `radius-4xl` 32 · `radius-full` | `rounded-*` |
| Shadow | `shadow-2xs` · `shadow-xs` · `shadow-sm` · `shadow-md` · `shadow-lg` · `shadow-xl` · `shadow-2xl` | `shadow-*` |
| Opacity | `opacity-0` … `opacity-100` (0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95, 100) | `opacity-*`, `/10` colour modifiers |
| Container | `container-sm` 24rem · `container-3xl` 48rem · `container-5xl` 64rem | `max-w-*` |

In CSS a half step is escaped: `var(--spacing-2\.5)`.

## Typography

- **Two faces, two weights.** Newsreader Regular and the system sans (SF Pro on Apple platforms) at `font-weight-normal` and `font-weight-semibold`. Nothing is bold, medium or light.
- **Every step in the scale is regular (400), at every size.** Weight is a separate axis a component opts into — `semibold` on buttons, badges and titles — never something a size step carries. A size step that came with its own weight meant two `sans-lg` texts side by side could differ without either call site asking for it.
- **Italic is an axis too, never a default.** Newsreader Italic exists for the cook's note, which sets `italic` itself; no step is italic on its own.
- **Each face has its own five-step scale, xs to xl.** A step is one `text-*` size plus one `leading-*` step — size and line height are separate tokens, combined only in the style:

| step | serif (Newsreader) | sans (system) |
| --- | --- | --- |
| **xl** | `serif-xl` · text-5xl · leading-none — the score numeral | `sans-xl` · text-xl · leading-normal — large sans figures (TasteScoreSelector) |
| **lg** | `serif-lg` · text-4xl · leading-tight — page and hero titles | `sans-lg` · text-lg · leading-normal — lg buttons, sheet and reason titles, lg badges (each sets semibold itself) |
| **md** | `serif-md` · text-3xl · leading-tight — sheet verdicts | `sans-md` · text-base · leading-normal — body, row labels, inputs, md buttons |
| **sm** | `serif-sm` · text-2xl · leading-snug — card titles, recipe names, the verdict beside a numeral | `sans-sm` · text-sm · leading-normal — meta, dates, counts, row notes, sm buttons |
| **xs** | `serif-xs` · text-xl · leading-snug — row and chip scores, card titles; the cook's note adds `italic` | `sans-xs` · text-xs · leading-normal — card labels, chips and badges (which set semibold); uppercase + `tracking-widest` for section headers |

- The serif scale sits where the sans scale ends (`sans-xl` = `serif-xs` = text-xl): serif carries voice and numbers, sans carries UI. Nothing is set in serif below text-xl.
- `serif-md` and up use Newsreader's 72pt optical cut (`--font-serif-display`), drawn tighter for display sizes; `serif-xs` and `serif-sm` the 16pt text cut (`--font-serif`).
- Serif leading tightens as it grows (snug → tight → none); sans stays at `leading-normal` so UI rows keep one rhythm.
- Hierarchy comes from size and face, not weight: a serif title over a regular sans summary; semibold only where something is pressable or needs to be scanned first.
- Scores and anything that lines up in a column use tabular figures.
- The app still bundles Inter and sets its own sizes in `AppTypography`; moving it to this scale means the mapping below.

#### Dynamic Type

**A fixed-size font on iOS ignores Dynamic Type.** Every step maps to a system text style and is declared relative to it, so it grows with the person's setting:

| step | iOS text style | SwiftUI |
| --- | --- | --- |
| `sans-xs` | `.caption` | `.font(.caption)` |
| `sans-sm` | `.footnote` | `.font(.footnote)` |
| `sans-md` | `.body` | `.font(.body)` |
| `sans-lg` | `.body`, 18pt | `.font(.system(size: 18, relativeTo: .body))` |
| `sans-xl` | `.title3` | `.font(.title3)` |
| `serif-xs` | `.title3` | `.font(.custom("Newsreader", size: 20, relativeTo: .title3))` |
| `serif-sm` | `.title2` | `.font(.custom("Newsreader", size: 24, relativeTo: .title2))` |
| `serif-md` | `.title` | `.font(.custom("Newsreader Display", size: 30, relativeTo: .title))` |
| `serif-lg` | `.largeTitle` | `.font(.custom("Newsreader Display", size: 36, relativeTo: .largeTitle))` |
| `serif-xl` | `.largeTitle` | `.font(.custom("Newsreader Display", size: 48, relativeTo: .largeTitle))` |

The px values in the scale above are the sizes at the default setting. Fixed component heights (`spacing-11` buttons, `spacing-14` rows) must become minimums rather than fixed frames, or they clip at accessibility sizes.

## Layout, radius, elevation

- Detail screens: `spacing-4` side gutters, `spacing-7` between blocks (photos, header, score, sections), `spacing-5` inside content cards, `spacing-2` inset for section headers, list rows at least `spacing-14` (`sm` rows `spacing-11`).
- Controls: **no button is drawn under `spacing-11` (44)**. `xs`, `sm` and `md` are all 44 tall and differ in type and padding; `lg` is `spacing-12` (48). The only control below the floor is Toggle, which is a switch rather than a capsule and carries a 44px hit area inside its ListRow. Web: `container-5xl` page, `container-3xl` prose.
- Corners are continuous. `radius-full` for every button, chip, pill, badge and avatar; `radius-3xl` for cards and hero photos; `radius-2xl` for timeline tiles; `radius-xl` for inputs, thumbnails and photo chips; `radius-4xl` for sheet tops; `radius-lg` for compact score boxes and picker cells.
- **No borders, no shadows on cards**: a white `panel` card on the grey `bg` is the separation. Only things that float get a shadow: `shadow-xs` for `elevated` buttons and badges over content, `shadow-sm` for raised tiles, `shadow-lg` for popovers and dragged cards.
- In dark, a black shadow can't show on a near-black ground, so every dark shadow leads with a 1px white ring and a faint top highlight; `panel` is stone-900 so cards separate from `bg` by value.
- Tints: a fill mixed over its ground at an opacity step — `opacity-10` tinted cards, `opacity-15` reaction badges, `opacity-20` selected cells, `opacity-30` hairlines.

## Imagery

- Category photography is 14 square shots of one stoneware plate on one oak table (see the Photography group). Keep the square master and crop from centre: 1:1 and 4:5 are safe, 16:9 is not.
- Round photos with `radius-3xl` (hero) or `radius-2xl` (in lists) only. Never tint a photo with `primary` or a reaction colour.
- Text over a photo gets a bottom scrim: `stone-1000` at 72% fading to clear at 32% from the top (5.8:1 over the plate).
- No photo: `sunken` tile, `text-tertiary` fork-and-knife glyph, caption "No photo yet" — never a grey box or a substitute photo. At thumbnail size the category shots look alike, so every tile ships its text label.

## Motion and states

- Press: `opacity-70` and scale 0.985 over 120ms ease-out. Focus and error borders animate over 150ms ease-out. Selection springs (≈0.25s) with a light haptic.
- Disabled: `opacity-50` on buttons and fields. Pending: a spinner replaces the button icon.
- Focused field: 1.5px `primary` at `opacity-80`; error: 1.5px `destructive` at `opacity-80`.
- Web keyboard focus: 2px solid `focus-ring`, 2px offset (≥6:1 on `bg`).
- Honour Reduce Motion (opacity only) and Differentiate Without Color (numerals always visible).

## Iconography

- iOS uses **SF Symbols**, sparingly: only where an icon removes ambiguity (camera, trash, plus, checkmark, back chevron, close). No decorative symbols across cards or rows; typography, numbers and colour do the work. The web uses Lucide.
- SF Symbols can't be copied into this system, so the component previews draw generic single-ink stand-ins (`NomNom.Icon` / `.nn-icon.nn-i-*` in `bundle.css`: sparkles, bolt, star, thumbs-up, flame, wrench, repeat, calendar, archive, arrows, chevrons, x, x-circle, search, heart, dashed circle, plus, camera, trash, utensils, mail, clock, leaf). The Swift sources name the real symbol for each.

## Logo

- There is no wordmark or vector mark in the sources. The app icon (Logos group) is a photograph — a white stoneware plate on oak — and the name is set in type: "Nom Nom" in Newsreader (the web header uses weight 600, −0.02em). Never redraw the icon as a vector.

### Accessibility rules the system holds itself to

- **A control's state lives on the control.** `aria-invalid`, `:disabled`, `:read-only`, `aria-pressed`, `aria-current` — the CSS reads them with `:has()`. No `is-*` mirror class to fall out of sync.
- **Nothing that holds flow content is a button.** A pressable Card is a `<div>` with a stretched hit button; a pressable ListRow with a trailing control splits. Both keep one tab stop and a real accessible name.
- **A control with no handler is not a control.** The favourite heart renders as a status icon when nothing can be done with it, never as a focusable button that does nothing.
- **A dialog is modal or it is not a dialog.** BottomSheet moves focus in, wraps Tab inside itself, closes on Escape and returns focus to whatever opened it.
- **A link is never `href="#"`.** Without a destination a card, tile or timeline item renders as plain markup rather than a focusable link that jumps to the top of the page.
- **A pending button keeps focus.** `loading` sets `aria-disabled` and drops the handler rather than `disabled`, which would throw focus to `<body>` mid-action.

- **Every control boundary clears 3:1** (WCAG 1.4.11): field borders, the dashed placeholder tile and the sheet grabber all use `line-control`. `line` and `line-strong` are decorative rules only — a divider between rows, a timeline rail — and are deliberately faint.
- The sheet grabber is decorative, so it is not held to 3:1.
- **`track` is the exception, on purpose.** A bar is read by where its fill ends, so the ratio that matters is fill against track: 5.2:1 light, 3.6:1 dark. Raising the track against the page would lower that, so the track stays quiet.
- **A hint or an error describes a field, it never names it.** Both sit outside the `<label>` and are linked with `aria-describedby`; an error also carries `role="alert"`.
- **A control is never nested inside another.** A pressable ListRow with a trailing control splits: the title region is the button, the trailing slot is its sibling.
- **Hover is for pointers only** (`hover: hover and pointer: fine`). A hover state faked on touch leaves a stuck highlight.
- **Reduced motion is one global rule**, not a per-component exception, and it also removes press transforms.
- **Forced colours are handled**: under `forced-colors: active` every surface, field and bar gets a real border, because tints and hairlines are discarded by the OS.

## Components

Thirty-one live React components in `components/bundle.js` (`window.NomNom`, React 18 from `components/lib/`), styled by `components/bundle.css`. Load `tokens.css`, `bundle.css`, the two libraries and `bundle.js`; put `class="nn"` on the root; props are in `components/index.d.ts`.

**One naming convention for every component:**

| axis | prop | values |
| --- | --- | --- |
| colour role | `variant` | `primary` · `secondary` · `destructive` · `pro` (Badge adds `warning`, `reaction`) |
| visual weight | `appearance` | `solid` · `soft` · `outline` · `ghost` · `elevated` (AppButton and Badge; Input and TextArea take `soft` (the one style) or `plain` inside a Card list row) |
| size | `size` | `xs` · `sm` · `md` · `lg` (AppButton; `xs` is the icon-only button that floats on a photo) |
| icon | `icon` + `iconPosition` | glyph name · `start` / `end` |
| structure | `layout` | per composite component: ScoreCard `hero` · `compact`, SectionCard `stacked` · `inset`, Card `block` · `list` |
| copy | `textStyle` + `tone` | a Typography token · `primary` / `secondary` / `tertiary` / `accent` (Text only) |

Badge takes a subset — `soft` · `solid` · `elevated`, `sm` · `md` — and Avatar and Bar run `xs` … `xl`. Cards (Card, and through it ScoreCard and SectionCard) take `variant="primary"` to feature themselves: `primary` at `opacity-10` over `panel`, one per screen. Interaction states (hover, pressed, focus, disabled, loading, selected) are never appearances — they come from the platform (`:disabled`, `aria-busy`, `aria-pressed`/`aria-checked`). In markup the axes are `data-*` attributes on one block class (`.nn-button[data-variant="primary"][data-appearance="soft"][data-size="lg"]`), which Tailwind can target as `data-[appearance=soft]:…`. Names carry a prefix only where they collide with SwiftUI (`AppButton`).

### Composition — build up, never re-style

Every component is made of the ones below it; none writes its own font, surface, label, score or photo rules. If a piece exists as a component, use it.

| layer | components | owns |
| --- | --- | --- |
| Foundations | Text, Icon | every piece of copy (type scale + tone); every glyph |
| Primitives | AppButton, Badge, Avatar, SectionHeader, ScoreValue, Bar, PhotoCard, Card, Input, TextArea, Toggle | actions; labels; people; **one small label, the same wherever it sits**; numeral + verdict; **every bar — one fill or several blocks**; photo tiles + verdict badge; the panel surface + press + chevron; fields; one on/off switch |
| Layout | Section, SectionCard, PageHeader | a SectionHeader over content; a Card whose label sits inside it; the title block of a screen with no subject |
| Composites | ScoreCard, RatingList, Timeline, RecipeCard, RecipeLinkCard, PhotoStrip, DetailHeader, TasteScoreSelector, BottomSheet, ListRow, EmptyState, SegmentedBar, ValueStepper | screen blocks, each listing what it is built from in its README |

| composite | built from |
| --- | --- |
| ScoreCard | Card · SectionHeader · ScoreValue · Badge (delta) · Text · Bar |
| RatingList | Section · Bar `xs` · Card `list` · ListRow · Text · Badge (delta, New) · ScoreValue `xs` |
| Timeline | Section · PhotoCard `sm` · Text |
| RecipeCard | PhotoCard `md` · SectionHeader · Text |
| RecipeLinkCard | Card `sm` (pressable) · PhotoCard `xs` · SectionHeader · Text |
| PhotoStrip | PhotoCard `lg` · AppButton · Text |
| DetailHeader | Avatar · SectionHeader · Text (meta, facts) · Badge (statuses) · AppButton |
| TasteScoreSelector | AppButton `lg` × 6 · Text |
| SectionCard | Card · SectionHeader · Text |
| BottomSheet | AppButton · Text · ScoreValue · Bar · Card (SheetCard) |
| Input / TextArea | Text (label) · AppButton (clear) · Icon |
| ListRow | Text · Icon; slots take Avatar · PhotoCard `xs` · Badge · ScoreValue `xs` · AppButton `sm` · Toggle |
| EmptyState | Card · Text · AppButton · Icon |
| SegmentedBar | Bar · Section · SectionHeader · Badge `reaction sm` · Text · RatingList (legend="rows") |
| ValueStepper | AppButton `iconOnly` × 2 · Text |
| Toggle | AppButton `secondary ghost`, restyled as a track; the knob is its label |
| PageHeader | SectionHeader (eyebrow) · Text (h1, sentence) · AppButton (actions) |

- **Horizontal scrollers** are one thing everywhere: `.nn-scroller`. Tiles snap, overscroll is contained, and the bar is a thin `line-control` thumb that fades in on hover or focus — hidden on touch, where the platform draws its own. A row that bleeds off the right edge still needs a scrollbar on a pointer device; it is the only sign there is more to see.
- **A fact is not a status.** Metadata about a thing — a duration, a method, a count — is a line of `sans-sm` `text-tertiary` text joined with " · ", never a row of chips. Badge is for the few labels a thing carries that could change and that you would want to spot at a glance: Staple, Pro, Archived, a verdict. A chart's legend key is neither — it is a swatch in the series colour and a label.
- **Lists** are one shape everywhere: `Card layout="list"` holding ListRow. The row's leading and trailing slots are what differ — an Avatar and a ScoreValue in a leaderboard, a Toggle in settings, Resend and a revoke ✕ on an invite. A list that has nothing to show is replaced by EmptyState, never by an empty Card.
- **Detail screens** (from the Meal Detail Redesign) compose top to bottom on `bg` with `spacing-7` between blocks: back button (AppButton `elevated iconOnly`) · PhotoStrip (Add photo on the first screen) · DetailHeader · ScoreCard · RecipeLinkCard · RatingList · note (SectionCard `inset`) · Timeline. DetailHeader heads meal, recipe and dinner-party screens.
- Helpers on `window.NomNom`: `Icon`, `SheetCard`, `Reason`, `REACTIONS`, `reactionForScore(score)`, `verdictForScore(score)`.

## Not synced

- Components not included: BurnerMeter, TactileOptionPicker, TactileTasteSelector, CookingTimeSelector, RotationGoalSelector, HeroPhotoDeck / HeroPhotoCard / ArcHeroHeader / MiniPhotoArcDeck / CategoryPhotoArc, EmptyPhotoDeckHero, SwipeActionRow / SwipeableListCard, ProGate, LabeledWrappingRow, CreateDropdownMenu, AssetPhotosPickerSection, photo and camera helpers (`apps/ios/NomNom/Core/Components/`). The included components are React renditions, not the SwiftUI code; Chip, SubtleCapsuleLabel, ProBadge, RotationPill, RecipeVerdictBadge, ScoreBadge, VerdictStrip, DeltaChip and IconButton were folded into Badge and AppButton; ProgressBar into Bar; DividedScoreCard into ScoreCard (`layout="compact"`); UserAvatar and PartyAvatar into Avatar; MealHeader became DetailHeader; NoteCard into SectionCard. ReactionPicker is not used and was removed. MealRow, the profile / recipe / meal-history rows, the leaderboard row, member rows, party rows, the notification row and settings navigation and info rows were folded into ListRow; the four invite-row copies into ListRow's Invite shape; every `ContentUnavailableView` and "No … yet" card into EmptyState; the four hand-built segmented bars into SegmentedBar; the recipe servings control into ValueStepper; PageHeader and PageHeading into PageHeader.

### Still to design

Tracked in `apps/ios/NomNom/Core/Design/DS-GAPS.md`: TrendChart (+ tooltip), MediaViewerSheet, PhotoStrip edit mode, LabeledPhotoCard, RecipeShelf, PartyCard, form blocks and the multi-step sheet toolbar convention. Until each lands here, the app keeps one interim component per pattern in `Core/Components/Interim/` with tokens applied.
- The iOS app's own spacing (`DS.Spacing`) and radii (`AppRadius`) are replaced by the Tailwind steps above; the web's shadcn defaults (`--background`, `--primary`, `--chart-1…5`, `--sidebar-*`, `oklch` greys) are left out; the web's own Stone/Pine layer overrides them.
- Web verdict tints (`--verdict-loved/ok/notfan-*`) are an older three-step scale; the six-step `reaction-*` ramp replaces them.
- SF Symbols are not copyable; previews use stand-in glyphs.
- The redesign's photo placeholders (tan blocks) are shown with the real category photography.


---

## Consuming this system (generated — do not edit)

Every path named below is under `project/` in this design system: read `project/api/tokens.md`, not `api/tokens.md`.

`components/bundle.js` defines `window.NomNom` (33 components); `components/bundle.css` is its stylesheet; `tokens.css` is every token as a CSS variable plus `@font-face` for the fonts. `components/bundle.css` reads its variables from `tokens.css`. The bundle needs `components/lib/react.production.min.js` (`window.React`), `components/lib/react-dom.production.min.js` (`window.ReactDOM`), loaded before it. Build any UI by mounting these components; never hand-build a control or draw an icon the system provides.

- **Standalone page:** inline `tokens.css` and `components/bundle.css` in a `<style>`, then the library files and `components/bundle.js` as classic scripts (a file containing `</style`, `</script` or `<!--` breaks an inline element: write the sequence `<\/style`, `<\/script` or `\x3C!--` in your copy, or load that file by URL).
- **Design canvas:** bring `components/bundle.css`, `components/bundle.js` and `components/index.d.ts` (for the editor’s props panel) onto the canvas in full, as the canvas type’s design-system components reference says (a server-side copy first where it offers one); load the stylesheet before the script; skip the library files (the artboard supplies React); mount with `<x-import component-from-global-scope="NomNom.<Comp>" …>`.
- **Slides deck, or any surface that cannot run the bundle:** tokens and fonts — the values are on `api/tokens.md`; the deck takes `tokens.json` by file path for its colour pickers, and fonts as “Fonts” below says.

Fonts: `tokens.css` loads each font from its file, by path.

- **Design canvas:** copy `tokens.css`, `fonts/Newsreader-Regular.ttf`, `fonts/Newsreader-Italic.ttf` and `fonts/Newsreader-DisplayRegular.ttf` to the same paths under the canvas’s `project/ds/<folder>/` (`<folder>` is the folder you install this system under; `fonts/Newsreader-Regular.ttf` lands on `project/ds/<folder>/fonts/Newsreader-Regular.ttf`), in the same call that installs this system. Link that copy of `tokens.css` in the artboard’s `<head>` as `ds/<folder>/tokens.css`, or as Design’s instructions say for an artboard in a folder. If the install’s reply leaves a font out, bring that font in as for any other page.
- **Slides deck:** for each family you use in the deck (`faces` holds at most the number of typefaces Slides’ `deck-files.md` gives), install its file with the system and name the path it lands on as that family’s `src` in `project/deck.json` `faces`, under the key in the Slides column. A deck takes a font as a file only under the rule in Slides’ `fonts.md` (no space or leading underscore in its path, for two): any other font, or one kept by id, is uploaded as `fonts.md` says.
- **Any other page:** one file per family is enough (below: the upright face nearest regular weight; bold and italic synthesize). Fetch it as the fetch column says (Artifact tool `read`, that id or path as `path`), upload it as an asset (`publish`, `file_path`, `asset:true`) and declare it with an `@font-face { font-family: "<family>"; src: url(<uploaded>) }` rule.

| family | file | fetch | CSS | Slides `faces` key |
| --- | --- | --- | --- | --- |
| Newsreader | `fonts/Newsreader-Regular.ttf` (weight 400) | `read` the file with `project/` in front | `var(--font-serif)` | `newsreader` |
| Newsreader Display | `fonts/Newsreader-DisplayRegular.ttf` (weight 400) | `read` the file with `project/` in front | `var(--font-serif-display)` | `newsreader-display` |

**Read, per thing:** a component’s props, parts and examples: `api/components/<Comp>.md`; token values: `api/tokens.md`; stored assets and their paths: `api/assets/<Group>.md`. After this README, fetch the cards and fonts you need in ONE message as parallel calls — none depends on another.

**Two rules.** Before you use a thing — a component, a token group, an icon, an asset — read its card from the index below; a value you did not read from a card is a guess. `tokens.json`, `manifest.json`, `components/index.d.ts` and `design-system.json` are sources for tools: hand them over. `components/<Comp>/README.md` and `assets/<Group>/README.md` are the long-form second read a card links to; `SKILL.md` and `artifact-type/` beside them are authoring guidance, not needed to consume the system.

## Index (generated — do not edit)

**Tokens**

- `api/tokens.md` — Every token: text, fill, chart, palette, type, spacing, radius, shadow, opacity, container, font-weight, tracking, leading. (22.4k)

**Icons and assets**

- `api/assets/Logos.md` — 1 file, by asset id. (1.1k)
- `api/assets/Photography.md` — 14 files, by asset id. (2.2k)

**Components** (`api/components/<Comp>.md`, 33)

- **Foundations**: `Text` — The one way to set copy: a Text takes a type-scale step (textStyle) and a tone, so no component writes its own font rules
- **Layout**: `Card` — The one surface: a white panel card at radius-3xl with no border or shadow — every card in the system (SectionCard, ScoreCard, RatingList, RecipeLinkCard, Shee… · `SectionHeader` — The one small label, the same wherever it sits: a sans-xs title in text-tertiary, uppercase by default, optionally with an icon before it and a figure on the r… · `Section` — A screen section: a SectionHeader (uppercase title, optional trailing count) above any content — the rail of a Timeline, the card of a RatingList, a SectionCar… · `SectionCard` — A Card whose label sits inside it: a SectionHeader, an optional quote, then the content · `PageHeader` — The title block of a screen with no subject: sign-in, onboarding, the paywall
- **Actions**: `AppButton` — The one button: a capsule with a colour role (variant), a visual weight (appearance) and a size — the same three axes as Badge
- **Labels**: `Badge` — The one badge: a small capsule that labels or rates something — one word, one number or one short phrase, never a number and a word together
- **Forms**: `Input` — The single-line text field: one style, one height and one radius for every field, taller only when it carries a label, with optional icons, a clear button, a h… · `TextArea` — The multi-line text field: Input's one style, radius, padding, text size and states, growing from 3 lines (the app grows 3–6)
- **Ratings**: `TasteScoreSelector` — The six-step taste scale used when you rate a meal yourself: a row of lg AppButtons labelled −1…5, with the chosen verdict word underneath · `ScoreValue` — A score as type: the numeral in primary-text (tabular) and its verdict word, baseline-aligned — used by ScoreCard, BottomSheet and RatingList so a score always… · `ScoreCard` — One score readout in two layouts: hero, the meal screen's big numeral with what changed and a progress bar, and compact, a smaller card for household, health a… · `RatingList` — The one “section header + meter + list of rows” block
- **People**: `Avatar` — A circle that shows a photo, or text when there is none — initials from name in Newsreader on primary-soft — in five sizes, xs to xl
- **Data**: `Bar` — The one bar: a horizontal meter that holds one fill or several blocks, in five thicknesses · `SegmentedBar` — A distribution as one bar: how a dish's ratings split across the taste scale, how a recipe's macros split, how a week's meals split by tier
- **Content**: `PhotoCard` — The one photo tile, shared by RecipeCard, PhotoStrip and Timeline: a rounded, centre-cropped photo (or the no-photo tile) with the verdict as a Badge in its bo… · `RecipeCard` — A grid tile for a recipe: one fixed square photo with the verdict word as a badge in its corner, an uppercase category eyebrow and a two-line title · `PhotoStrip` — The photos at the top of a detail screen: equal PhotoCards — square, tall or wide — that scroll sideways and bleed off the right edge, with an Add photo button… · `DetailHeader` — The top of a detail screen — a meal, a recipe or a dinner party: optional avatar and eyebrow, meta line, serif title, summary, fact badges and up to two action… · `RecipeLinkCard` — A tappable card linking a meal to its recipe: a portrait thumbnail, "RECIPE" label, serif name, meta line and a chevron · `Timeline` — Every time this recipe was cooked, as a horizontal rail of dots over PhotoCards, each with its verdict badge and date
- **Overlays**: `BottomSheet` — A sheet over the screen for detail on demand — here, why one person scored a meal the way they did
- **Lists**: `ListRow` — The one row: a leading slot, a title with optional meta, and a trailing slot — every list in the app is this row inside Card layout="list"
- **Controls**: `Toggle` — The one switch: an on/off setting, always in a ListRow's trailing slot · `ValueStepper` — Minus · numeral · plus: the one way to change a small number by hand
- **Feedback**: `EmptyState` — Nothing here yet: one fact, one sentence, at most one way out — in four sizes, from a whole screen down to a single row
- `LabeledPhotoCard` — LabeledPhotoCard · `RecipeShelf` — RecipeShelf · `PartyCard` — PartyCard · `PendingInviteRow` — Removed
