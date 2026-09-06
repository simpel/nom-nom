# NomNom Design System — Button Specification (`AppButton`)

The button system in NomNom provides a cohesive, accessible, and tactile interface for all user interactions. All action buttons in view bodies, screens, cards, forms, and sheets use the centralized **`AppButton`** component (`NomNom/Core/Components/AppButton.swift`).

---

## 1. Design Principles

1. **Hierarchy Through Intent**: Every button clearly communicates its intent (`primary`, `secondary`, `neutral`, `destructive`). A screen or modal should feature at most **one** primary solid CTA.
2. **Predictable Geometry**: Every button uses a continuous `Capsule()` pill shape, creating harmony with rounded input fields (50pt) and cards.
3. **Consistent Typography**: All variants and styles strictly share `Font.weight(.semibold)`. The weight does not vary between primary and secondary buttons.
4. **Accessible Contrast (WCAG AAA)**: Text colors are rigorously paired with backgrounds. Specifically, the neutral ghost text uses `DS.Color.textSecondary` (`#4D525A` in light mode, `#D0D4D9` in dark mode) ensuring **>8:1 contrast** on all light surfaces.
5. **Zero Emojis & Minimal Iconography**: Buttons never use emojis. SF Symbols are reserved strictly for high-clarity functions (e.g. `camera.fill`, `trash`, `checkmark`, `plus`).

---

## 2. API & Dimension Matrix

```swift
AppButton(
    _ title: String = "",
    icon: AppButtonIcon? = nil,
    systemImage: String? = nil,
    iconPosition: AppButtonIconPosition = .leading,
    variant: AppButtonVariant = .primary,
    style: AppButtonStyle = .normal,
    size: AppButtonSize = .md,
    isFullWidth: Bool = false,
    isPending: Bool = false,
    disabled: Bool = false,
    action: @escaping () -> Void
)
```

### Icon Support (`AppButtonIcon` & `AppButtonIconPosition`)

- **Flexible Types**: Conforms to `ExpressibleByStringLiteral`, allowing string literals (`icon: "plus"`), explicit SF symbols (`icon: .system("camera")`), named asset images (`icon: .asset("badge")`), or custom SwiftUI `Image`s (`icon: .image(...)`).
- **Placement**: `iconPosition: .leading` (default) or `iconPosition: .trailing` (e.g. for "Next", "Continue", or forward chevrons).
- **Icon-Only Buttons**: Omitting `title` creates a circular button with an exact touch target diameter matching `size.height` (34pt for `.sm`, 42pt for `.md`, 50pt for `.xl`).


### A. Variants (`AppButtonVariant`)

| Variant | Purpose | Color Palette (Normal) | When to Use |
| :--- | :--- | :--- | :--- |
| **`.primary`** | Main action / goal completion | Background: `DS.Color.accent` (Pine)<br>Text: `.white` | "Sign in", "Email me a code", "Create Recipe", "Log a meal" |
| **`.secondary`** | Supporting branded action | Background: `DS.Color.accentSoft`<br>Text: `DS.Color.accentText` | "Send", "Resend", "Join Dinner Party" |
| **`.neutral`** | Alternatives, utilities, skips | Background: `systemGray5`<br>Text: `DS.Color.textPrimary` (normal) or `DS.Color.textSecondary` (ghost) | "Use a different address", "Clear Search", "Reset Filters", "Skip step" |
| **`.destructive`** | High-friction / irreversible actions | Background: `.red`<br>Text: `.white` (normal) or `.red` (outlined/ghost) | "Delete account", "Leave party", "Delete meal", "Revoke invite" |

---

### B. Styles (`AppButtonStyle`)

| Style | Background | Border | Use Case |
| :--- | :--- | :--- | :--- |
| **`.normal`** | Solid fill per variant | None | Main calls to action, prominent screen commits |
| **`.outlined`** | `Color.clear` | 1.5pt solid per variant | Card actions, secondary tools, filter toggles |
| **`.ghost`** | `Color.clear` | None | Alternatives, skip links, dismissive actions, inline row links |

---

### C. Sizes (`AppButtonSize`)

| Size | Height | Horizontal Padding | Typography | Typical Placement |
| :---: | :---: | :---: | :--- | :--- |
| **`.xl`** | **50pt** | 20pt | `.headline.weight(.semibold)` | Screen-bottom CTAs, auth forms (matches 50pt text field height) |
| **`.md`** | **42pt** | 16pt | `.callout.weight(.semibold)` | Standard section actions, cards, empty state triggers |
| **`.sm`** | **34pt** | 12pt | `.subheadline.weight(.semibold)` | Compact table rows, member list actions, header toggles |

---

## 3. Platform Exceptions

To respect native SwiftUI architecture constraints, raw SwiftUI `Button` is used **only** in:
1. **`alert` and `confirmationDialog` actions**: Platform requires primitive `Button("Title", role: ...)`.
2. **`swipeActions`, `contextMenu`, and native `Menu`**: Platform menus require primitive `Button`.
3. **Modal sheet toolbars**: Handled via `.sheetCommitToolbar(...)` per AGENTS.md rule 5.

---

## 4. Code Examples

```swift
// 1. Primary Full-Width CTA (Auth / Modal submit)
AppButton(
    "Sign in",
    variant: .primary,
    style: .normal,
    size: .xl,
    isFullWidth: true,
    isPending: isSubmitting,
    disabled: !canSubmit,
    action: { submit() }
)

// 2. Neutral Ghost Button (Alternative action)
AppButton(
    "Use a different address",
    variant: .neutral,
    style: .ghost,
    size: .xl,
    isFullWidth: true,
    action: { startOver() }
)

// 3. Outlined Utility Button (Row action)
AppButton(
    "Resend",
    variant: .secondary,
    style: .outlined,
    size: .sm,
    action: { resendInvite() }
)

// 4. Outlined Button with Trailing Icon
AppButton(
    "Continue",
    icon: "arrow.right",
    iconPosition: .trailing,
    variant: .primary,
    style: .normal,
    size: .xl,
    action: { nextStep() }
)

// 5. Destructive Icon-Only Button
AppButton(
    icon: "trash",
    variant: .destructive,
    style: .ghost,
    size: .sm,
    action: { deleteItem() }
)
.accessibilityLabel("Delete item")
```
