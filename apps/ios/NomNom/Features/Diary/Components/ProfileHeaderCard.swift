import SwiftUI

/// The top of a person's profile: a ScreenHeader centred by the person's avatar, their
/// name and, on your own profile, "Edit profile" (secondary soft) and a camera badge on the avatar.
struct ProfileHeaderCard: View {
    let name: String
    var photoPath: String? = nil
    let isCurrentUser: Bool
    var onEdit: (() -> Void)? = nil
    /// Avatar edit mode; used only on your own profile.
    var avatarEdit: ScreenHeaderAvatarEdit? = nil

    var body: some View {
        ScreenHeader(
            name,
            avatar: Avatar(name: name, photoPath: photoPath, decorative: true),
            avatarEdit: isCurrentUser ? avatarEdit : nil,
            actions: (isCurrentUser && onEdit != nil) ? [
                ScreenHeaderAction(title: "Edit profile", variant: .secondary, appearance: .soft) { onEdit?() },
            ] : []
        )
    }
}

#Preview {
    NomNomPreview { _ in
        ProfileHeaderCard(name: "Joel Sandén", isCurrentUser: true, onEdit: {},
                          avatarEdit: ScreenHeaderAvatarEdit(hasPhoto: false) { _ in })
            .padding(DS.Spacing.gutter)
    }
}
