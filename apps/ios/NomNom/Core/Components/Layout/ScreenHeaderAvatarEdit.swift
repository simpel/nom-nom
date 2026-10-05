// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// ScreenHeader's avatar edit mode: the `xl` avatar becomes one 80pt button with a camera
/// badge on its top-right edge. A tap opens the front camera (a library button floats
/// over it); a long press offers Remove photo when there is one.
/// Model-agnostic: the caller stores the picked photo and decides what removing means.
struct ScreenHeaderAvatarEdit {
    var hasPhoto: Bool
    let onPick: (Data) -> Void
    var onRemove: (() -> Void)?
}

/// The editable avatar ScreenHeader draws when it gets a `ScreenHeaderAvatarEdit`.
struct ScreenHeaderEditableAvatar: View {
    let avatar: Avatar
    let edit: ScreenHeaderAvatarEdit

    @State private var showingOptions = false

    /// Moves the badge from the frame's corner so its centre sits on the circle's
    /// edge at 45°: the corner is `r(1 - 1/√2)` outside the circle, the badge's
    /// centre `badge / 2` inside the corner.
    private var badgeOffset: CGFloat {
        let radius = avatar.size.diameter / 2
        let cornerGap = radius * (1 - 1 / CGFloat(2).squareRoot())
        return ScreenHeaderAvatarEditBadge.diameter / 2 - cornerGap
    }

    var body: some View {
        Button { showingOptions = true } label: {
            avatar
                .overlay(alignment: .topTrailing) {
                    ScreenHeaderAvatarEditBadge()
                        .offset(x: badgeOffset, y: -badgeOffset)
                }
        }
        .buttonStyle(AppPressableButtonStyle())
        // Native camera has no room for removing, so it lives on a long press.
        .contextMenu {
            if edit.hasPhoto, let onRemove = edit.onRemove {
                Button("Remove photo", systemImage: "trash", role: .destructive) { onRemove() }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(edit.hasPhoto ? "Change photo" : "Add photo")
        .accessibilityHint("Opens the camera")
        .accessibilityAddTraits(.isButton)
        .accessibilityActions {
            if edit.hasPhoto, let onRemove = edit.onRemove {
                Button("Remove photo") { onRemove() }
            }
        }
        .avatarPhotoPicker(isPresented: $showingOptions, onPick: edit.onPick)
    }
}

/// The camera badge: `panel` and `text-primary` (AppButton `elevated`'s paint) on a `spacing-8`
/// circle, lifted with `shadow-md` so it reads over a photo. Visual only; the whole
/// avatar is the target.
private struct ScreenHeaderAvatarEditBadge: View {
    static let diameter = DS.Spacing.s8

    var body: some View {
        Image(systemName: "camera")
            .textStyle(.sansXs, weight: .semibold)
            .foregroundStyle(DS.Color.textPrimary)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(DS.Color.panel, in: Circle())
            .dsShadow(.md)
            .accessibilityHidden(true)
    }
}
