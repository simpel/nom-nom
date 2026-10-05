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
    /// A picked photo not uploaded yet; shown instead of `photoPath`.
    var photoData: Data?
    var text: String?
    var bucket: String
    /// A bundled photo shown when `photoPath` has none (a cuisine's category photograph).
    var assetName: String?
    var size: AvatarSize
    var decorative: Bool

    @State private var imageData: Data?

    /// - Parameters:
    ///   - name: Accessible name; its first and last word give the initials.
    ///   - text: Shown instead of the initials (at most two characters).
    ///   - bucket: Storage bucket `photoPath` lives in.
    ///   - decorative: The name is visible beside the avatar, so hide the avatar from
    ///     VoiceOver and the name is not read twice.
    init(
        name: String,
        photoPath: String? = nil,
        photoData: Data? = nil,
        text: String? = nil,
        bucket: String = SupabaseConfig.profileBucket,
        assetName: String? = nil,
        size: AvatarSize = .md,
        decorative: Bool = false
    ) {
        self.name = name
        self.photoPath = photoPath
        self.photoData = photoData
        self.text = text
        self.bucket = bucket
        self.assetName = assetName
        self.size = size
        self.decorative = decorative
    }

    init(profile: Profile, size: AvatarSize = .md, decorative: Bool = false) {
        self.init(name: profile.shownName, photoPath: profile.photoPath, bucket: SupabaseConfig.profileBucket,
                  size: size, decorative: decorative)
    }

    init(party: Party, size: AvatarSize = .md, decorative: Bool = false) {
        self.init(name: party.name, photoPath: party.photoPath, bucket: SupabaseConfig.partyBucket,
                  size: size, decorative: decorative)
    }

    /// A category's photo: its generated cover, else the cuisine's photograph, else initials
    /// (the same order as `PhotoCardSource.category`).
    init(category: CategoryItem, size: AvatarSize = .md, decorative: Bool = false) {
        self.init(name: category.displayName, photoPath: category.photoPath, bucket: SupabaseConfig.categoryBucket,
                  assetName: category.assetImageName, size: size, decorative: decorative)
    }

    /// Empty when there is no name yet (onboarding before the name is typed): a bare circle.
    private var initials: String {
        if let text, !text.isEmpty { return String(text.prefix(2)) }
        let words = name.split(whereSeparator: \.isWhitespace)
        guard let first = words.first?.first else { return "" }
        if words.count > 1, let last = words.last?.first {
            return "\(first)\(last)".uppercased()
        }
        return String(first).uppercased()
    }

    var body: some View {
        ZStack {
            if let image = (photoData ?? imageData).flatMap(UIImage.init(data:)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                DS.Color.primarySoft
                Text(initials)
                    .textStyle(
                        size.textStyle(characters: initials.count),
                        tone: .accent,
                        weight: size.textStyle(characters: initials.count).isSerif ? nil : .semibold,
                        lines: 1
                    )
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .clipShape(Circle())
        // README: "0.5px `line` ring at 30%". 0.5px has no token; `.dsHairline` draws
        // `border-hairline` (1pt) `line` at `opacity-30` (DS-GAPS.md, "Hairline width").
        .dsHairline(radius: DS.Radius.full)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityAddTraits(.isImage)
        .accessibilityHidden(decorative)
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
