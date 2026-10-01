import SwiftUI

/// Avatar diameters and initials type steps.
enum AvatarSize: Equatable, CaseIterable {
    case xs, sm, md, lg, xl

    var diameter: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s6
        case .sm: return DS.Spacing.s8
        case .md: return DS.Spacing.s10
        case .lg: return DS.Spacing.s14
        case .xl: return DS.Spacing.s20
        }
    }

    func textStyle(characters: Int) -> DS.TextStyle {
        switch self {
        case .xs, .sm: return .sansXs
        case .md: return .serifXs
        case .lg: return .serifSm
        case .xl: return characters > 1 ? .serifMd : .serifLg
        }
    }
}

/// A circle showing a photo, or initials (first + last word) in `primary-text`
/// on `primary-soft` when there is none. It doesn't know what it depicts.
struct Avatar: View {
    let name: String
    var photoPath: String?
    var text: String?
    var bucket: String
    var size: AvatarSize

    @State private var imageData: Data?

    /// - Parameters:
    ///   - name: Accessible name; its first and last word give the initials.
    ///   - text: Shown instead of the initials (at most two characters).
    ///   - bucket: Storage bucket `photoPath` lives in.
    init(
        name: String,
        photoPath: String? = nil,
        text: String? = nil,
        bucket: String = SupabaseConfig.profileBucket,
        size: AvatarSize = .md
    ) {
        self.name = name
        self.photoPath = photoPath
        self.text = text
        self.bucket = bucket
        self.size = size
    }

    init(profile: Profile, size: AvatarSize = .md) {
        self.init(name: profile.shownName, photoPath: profile.photoPath, bucket: SupabaseConfig.profileBucket, size: size)
    }

    init(party: Party, size: AvatarSize = .md) {
        self.init(name: party.name, photoPath: party.photoPath, bucket: SupabaseConfig.partyBucket, size: size)
    }

    private var initials: String {
        if let text, !text.isEmpty { return String(text.prefix(2)) }
        let words = name.split(whereSeparator: \.isWhitespace)
        guard let first = words.first?.first else { return "?" }
        if words.count > 1, let last = words.last?.first {
            return "\(first)\(last)".uppercased()
        }
        return String(first).uppercased()
    }

    var body: some View {
        ZStack {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                DS.Color.primarySoft
                Text(initials)
                    .textStyle(
                        size.textStyle(characters: initials.count),
                        tone: .accent,
                        weight: size.textStyle(characters: initials.count).isSerif ? nil : .semibold
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(DS.Color.line.opacity(DS.Opacity.hairline), lineWidth: 0.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityAddTraits(.isImage)
        .task(id: photoPath) { await loadPhoto() }
    }

    private func loadPhoto() async {
        guard let path = photoPath, !path.isEmpty else {
            imageData = nil
            return
        }
        if let cached = PhotoCache.shared.cached(path) {
            imageData = cached
            return
        }
        let data = await PhotoCache.shared.data(for: path, bucket: bucket)
        if photoPath == path {
            imageData = data
        }
    }
}

private struct AvatarGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            HStack(spacing: DS.Spacing.s3) {
                ForEach(AvatarSize.allCases, id: \.self) { Avatar(name: "Joel Sandén", size: $0) }
            }
            HStack(spacing: DS.Spacing.s3) {
                ForEach(AvatarSize.allCases, id: \.self) { Avatar(name: "Anna", size: $0) }
            }
            Avatar(name: "Taco Night", text: "TN", bucket: SupabaseConfig.partyBucket, size: .lg)
        }
        .padding(DS.Spacing.s4)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { AvatarGallery() }
#Preview("Dark") { AvatarGallery().preferredColorScheme(.dark) }
