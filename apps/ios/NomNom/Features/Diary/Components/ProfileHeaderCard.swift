import SwiftUI

/// The top of a person's profile. A screen about someone, so it is a DetailHeader
/// (PageHeader README: "A screen about something … uses DetailHeader"): centred
/// avatar, name and membership line.
struct ProfileHeaderCard: View {
    let name: String
    let subtitle: String
    var photoPath: String? = nil
    let isCurrentUser: Bool

    var body: some View {
        DetailHeader(
            title: name,
            align: .center,
            meta: subtitle.isEmpty ? nil : subtitle,
            avatar: Avatar(name: name, photoPath: photoPath, decorative: true)
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NomNomPreview { _ in
        ProfileHeaderCard(
            name: "Joel Sandén",
            subtitle: "Member of 2 dinner parties",
            isCurrentUser: true
        )
        .padding(DS.Spacing.gutter)
    }
}
