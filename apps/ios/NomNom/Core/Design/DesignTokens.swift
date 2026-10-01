import Foundation

/// Nom Nom design system namespace.
///
/// Source of truth: the design-system artifact
/// (https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK), `tokens.json`.
/// Tokens are split by scale, each in its own file:
///
/// - `DS+Color.swift`      semantic colour roles + `DS.Role`
/// - `DS+Palette.swift`    raw Stone / Pine ramps
/// - `DS+Spacing.swift`    Tailwind spacing steps + layout aliases
/// - `DS+Radius.swift`     corner radii
/// - `DS+Shadow.swift`     `.dsShadow(_:)` and `.dsHairline(radius:)`
/// - `DS+Opacity.swift`    opacity steps
/// - `DS+Typography.swift` `DS.TextStyle`, `DS.Tone` and `.textStyle(...)`
///
/// Views consume semantic roles, never the ramps.
enum DS {}
