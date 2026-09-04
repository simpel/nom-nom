import SwiftUI

/// Elevated header view showing user avatar monogram, name, and membership subtitle directly on the background.
struct ProfileHeaderCard: View {
    let name: String
    let subtitle: String
    let isCurrentUser: Bool

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2, let first = parts.first?.first, let last = parts.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = trimmed.first {
            return String(first).uppercased()
        }
        return "?"
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DS.Color.accentSoft)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 1)
                    )

                Text(initials)
                    .font(Font.newsreader(initials.count > 1 ? .title2 : .title, weight: .bold))
                    .foregroundStyle(DS.Color.accentText)
            }

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
