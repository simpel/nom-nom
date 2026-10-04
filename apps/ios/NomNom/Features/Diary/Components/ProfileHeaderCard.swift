import SwiftUI

/// The top of a person's profile: a ScreenHeader centred by the person's avatar, their
/// name and, on your own profile, "Edit profile" (secondary soft).
struct ProfileHeaderCard: View {
    let name: String
    var photoPath: String? = nil
    let isCurrentUser: Bool
    var onEdit: (() -> Void)? = nil

    var body: some View {
        ScreenHeader(
            name,
            avatar: Avatar(name: name, photoPath: photoPath, decorative: true),
            actions: (isCurrentUser && onEdit != nil) ? [
                ScreenHeaderAction(title: "Edit profile", variant: .secondary, appearance: .soft) { onEdit?() },
            ] : []
        )
    }
}

#Preview {
    NomNomPreview { _ in
        ProfileHeaderCard(name: "Joel Sandén", isCurrentUser: true, onEdit: {})
            .padding(DS.Spacing.gutter)
    }
}
