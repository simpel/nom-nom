import SwiftUI

/// Elevated header view showing user avatar (or serif monogram initial), name, and membership subtitle directly on the background.
struct ProfileHeaderCard: View {
    let name: String
    let subtitle: String
    var photoPath: String? = nil
    let isCurrentUser: Bool

    var body: some View {
        VStack(spacing: 14) {
            UserAvatar(name: name, photoPath: photoPath, size: 80)

            PageHeader(
                title: name,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                alignment: .center
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

#Preview {
    NomNomPreview { _ in
        ProfileHeaderCard(
            name: "Joel Sandén",
            subtitle: "Member of 2 dinner parties",
            isCurrentUser: true
        )
        .padding()
    }
}
