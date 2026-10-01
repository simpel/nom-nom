import SwiftUI

/// Reusable circular avatar representing a Dinner Party.
/// Displays the party's photo if available, or falls back to an elegant serif monogram circle.
struct PartyAvatar: View {
    var party: Party? = nil
    var name: String? = nil
    var photoPath: String? = nil
    var size: CGFloat = 40

    @State private var imageData: Data?
    @State private var isLoading = false

    init(party: Party, size: CGFloat = 40) {
        self.party = party
        self.name = party.name
        self.photoPath = party.photoPath
        self.size = size
    }

    init(name: String, photoPath: String? = nil, size: CGFloat = 40) {
        self.party = nil
        self.name = name
        self.photoPath = photoPath
        self.size = size
    }

    private var effectiveName: String {
        party?.name ?? name ?? ""
    }

    private var effectivePhotoPath: String? {
        party?.photoPath ?? photoPath
    }

    private var initial: String {
        String(effectiveName.prefix(1)).uppercased()
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

            Text(initial)
                .font(Font.newsreader(fontSize, weight: .bold))
                .foregroundStyle(DS.Color.accentText)
        }
    }

    private var fontSize: Font.TextStyle {
        if size >= 70 { return .title }
        if size >= 48 { return .title2 }
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
        let data = await PhotoCache.shared.data(for: path, bucket: SupabaseConfig.partyBucket)
        if effectivePhotoPath == path {
            imageData = data
        }
        isLoading = false
    }
}

#Preview {
    HStack(spacing: 16) {
        PartyAvatar(name: "Taco Night", size: 32)
        PartyAvatar(name: "Friday Feasts", size: 44)
        PartyAvatar(name: "Sunday Roast", size: 64)
    }
    .padding()
}
