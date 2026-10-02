import Foundation

/// Nom Nom design system namespace.
///
/// Source of truth: the design-system artifact
/// (https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK), vendored at
/// `design-system/` in the repo root. `scripts/ds-tokens-swift.py` turns its
/// `tokens.json` into `Generated/DSTokens.generated.swift`; the files below
/// only alias those generated values under semantic names:
///
/// - `DS+Color.swift`      semantic colour roles + `DS.Role`
/// - `DS+Palette.swift`    raw Stone / Pine ramps
/// - `DS+Spacing.swift`    Tailwind spacing steps + layout aliases
/// - `DS+Radius.swift`     corner radii
/// - `DS+Shadow.swift`     `.dsShadow(_:)` and `.dsHairline(radius:)`
/// - `DS+Opacity.swift`    opacity steps
/// - `DS+Typography.swift` `DS.TextStyle`, `DS.Tone` and `.textStyle(...)`
/// - `DS+Motion.swift`     `DS.BorderWidth`, `DS.Motion`, `DS.Tracking`
///
/// Views consume semantic roles, never the ramps.
enum DS {}
