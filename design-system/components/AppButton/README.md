The one button: a capsule with a colour role (`variant`), a visual weight (`appearance`) and a size — the same three axes as Badge.

**Built from:** Icon.

Defined by the design system; maps onto `apps/ios/NomNom/Core/Components/AppButton.swift` (see Migration). React in `components/bundle.js`, styles in `bundle.css`.

## Axes

| prop | values | default |
| --- | --- | --- |
| `variant` | `primary` · `secondary` · `destructive` · `pro` | `primary` |
| `appearance` | `solid` · `soft` · `outline` · `ghost` · `elevated` | `solid` |
| `size` | `xs` · `sm` · `md` · `lg` | `md` |
| `icon` + `iconPosition` | glyph name · `start` / `end` | — · `start` |
| `iconOnly` | circle, width = height; `label` becomes the accessible name | false |
| `fullWidth` | stretches to the container | false |
| `loading` / `disabled` | spinner in the icon slot + `aria-busy` / `opacity-50` | false |

| size | height | side padding | label | icon | gap |
| --- | --- | --- | --- | --- | --- |
| `xs` | `spacing-11` (44) | `spacing-2.5` | `sans-xs` semibold | `text-xs` | `spacing-1` |
| `sm` | `spacing-11` (44) | `spacing-3` | `sans-sm` semibold | `text-sm` | `spacing-1.5` |
| `md` | `spacing-11` (44) | `spacing-4` | `sans-md` semibold | `text-base` | `spacing-2` |
| `lg` | `spacing-12` (48) | `spacing-5` | `sans-lg` semibold | `text-lg` | `spacing-2` |

**No button is smaller than 44 × 44.** `min-width` and `min-height` are `spacing-11` on every button, so the floor is the drawn box, not an invisible hit area. `xs` and `sm` therefore share `md`'s height and differ from it only in type size and side padding — a narrower, quieter capsule, the same height. Icon-only, all four sizes are the same 44 × 44 circle.

That makes `xs` and `sm` labelled-button sizes. For an icon-only control there is now one size, so pass none.

Each variant supplies four role tokens — `{role}`, `{role}-soft`, `{role}-text`, `on-{role}` — and the appearance paints with them: `solid` = `{role}` ground + `on-{role}`; `soft` = `{role}-soft` + `{role}-text`; `outline` = clear + `{role}-text` + 1.5px `{role}` border (`line-strong` for secondary); `ghost` = `{role}-text` only; `elevated` = `panel` + `shadow-xs` + `text-primary`.

## When to use
- `primary solid` — the one main commitment on a screen ("Log a meal", "Email me a code", "Rate this meal"). One per view.
- `primary soft` — supporting branded actions ("Resend", "Join dinner party", "You rated 90").
- `secondary` — alternatives and utilities ("Use a different address", "Reset filters", "Skip step"); `secondary soft iconOnly` is the in-sheet close.
- `destructive` — irreversible actions only ("Delete meal", "Leave party", "Sign out"); prefer `outline` or `ghost` and confirm.
- `pro` — Nom Nom Pro CTAs only ("Unlock with Pro").
- `elevated iconOnly` — floating controls over content (the back button over photos); the PhotoStrip's Add photo is now its trailing tile, not a button.
- `variant="reaction"` (+ `reaction` step) — only inside rating controls (TasteScoreSelector's selected step), never as an action.

## Rules
- Label always semibold, sentence case; shape always `radius-full`.
- Pressed `opacity-70` (120ms ease-out), no scale: a button never changes size on press. Focus 2px `focus-ring`, 2px offset. States are never appearances.
- Icons only where they remove ambiguity (camera, trash, plus, back, close, forward arrow). Never emoji.
- **In a ScreenHeader:** `md`, label only (never an icon), hugging its label; one or two on one row, never full width, never wrapped.
- Native alerts, confirmation dialogs, swipe actions, context menus and sheet toolbars use system buttons.
- Contrast: `on-primary` on dark-theme `primary` is 2.98:1 and `on-destructive` on `destructive` ~3.5:1 — known misses kept from the source; `destructive-text` (outline/ghost/soft) passes.

## Migration from the Swift AppButton
`.primary` → `primary solid` · `.secondary` → `primary soft` · `.neutral` → `secondary` · `.destructive` → `destructive` · `.pro` → `pro` · style `.normal` / `.outlined` / `.ghost` → `solid` / `outline` / `ghost` · size `.xl` → `lg` · `iconPosition` `.leading` / `.trailing` → `start` / `end` · IconButton → `iconOnly` (`elevated` floating, `secondary soft` in sheets).

## Use
```js
h(NomNom.AppButton, { variant: 'primary', appearance: 'solid', size: 'lg', fullWidth: true }, 'Rate this meal')
h(NomNom.AppButton, { variant: 'secondary', appearance: 'elevated', iconOnly: true, icon: 'chevron-left', label: 'Back' })
```
Markup: `button.nn-button[data-variant][data-appearance][data-size]` (+ `data-icon-position="end"`, `data-icon-only`, `data-full-width`, `aria-busy`, `disabled`) containing `.nn-icon` / `.nn-spinner` and the label.
