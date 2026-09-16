import SwiftUI

/// Reusable circular avatar representing a User or Profile.
/// Displays the user's uploaded avatar photo if available, or falls back to an elegant serif monogram initial.
struct UserAvatar: View {
    var profile: Profile? = nil
    var name: String? = nil
    var photoPath: String? = nil
    var size: CGFloat = 40

    @State private var imageData: Data?
    @State private var isLoading = false

    init(profile: Profile, size: CGFloat = 40) {
        self.profile = profile
        self.name = profile.shownName
        self.photoPath = profile.photoPath
        self.size = size
    }

    init(name: String, photoPath: String? = nil, size: CGFloat = 40) {
        self.profile = nil
        self.name = name
        self.photoPath = photoPath
        self.size = size
    }

    private var effectiveName: String {
        profile?.shownName ?? name ?? ""
    }

    private var effectivePhotoPath: String? {
        profile?.photoPath ?? photoPath
    }

    private var initials: String {
        let trimmed = effectiveName.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2, let first = parts.first?.first, let last = parts.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = trimmed.first {
            return String(first).uppercased()
        }
        return "?"
    }

    var body: some View {
        ZStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                fallbackCircle
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
        )
        .task(id: effectivePhotoPath) {
            await loadPhoto()
        }
    }

    private var fallbackCircle: some View {
        ZStack {
            Circle()
                .fill(DS.Color.accentSoft)
                .frame(width: size, height: size)

            Text(initials)
                .font(Font.newsreader(fontSize, weight: .bold))
                .foregroundStyle(DS.Color.accentText)
        }
    }

    private var fontSize: Font.TextStyle {
        if size >= 70 { return initials.count > 1 ? .title2 : .title }
        if size >= 48 { return .title3 }
        if size >= 36 { return .body }
        return .caption
    }

    private func loadPhoto() async {
        guard let path = effectivePhotoPath, !path.isEmpty else {
            imageData = nil
            return
        }
        if let cached = PhotoCache.shared.cached(path) {
            imageData = cached
            return
        }
        isLoading = true
        let data = await PhotoCache.shared.data(for: path, bucket: SupabaseConfig.profileBucket)
        if effectivePhotoPath == path {
            imageData = data
        }
        isLoading = false
    }
}

#Preview {
    HStack(spacing: 16) {
        UserAvatar(name: "Joel Sandén", size: 32)
        UserAvatar(name: "Alice Smith", size: 44)
        UserAvatar(name: "Joel Sandén", size: 80)
    }
    .padding()
}
