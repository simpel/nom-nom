import SwiftUI

/// PhotoCard previews: the size × format grid, badges, the heart and the no-photo tile.
private struct PhotoCardGallery: View {
    @State private var isFavorite = false

    var body: some View {
        NomNomPreview(inNavigationStack: false) { store in
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    ForEach(PhotoCardSize.allCases, id: \.self) { size in
                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                                ForEach(PhotoCardFormat.allCases, id: \.self) { format in
                                    PhotoCard(.none(cuisine: "italian"), size: size, format: format, badge: .score(0.8))
                                }
                                PhotoCard(.none(), size: size)
                            }
                        }
                    }
                    HStack(alignment: .top, spacing: DS.Spacing.s3) {
                        if let meal = store.meals.first { PhotoCard(.meal(meal), size: .xs) }
                        PhotoCard(.none(cuisine: "mexican"), size: .sm, badge: .score(0.9), isSelected: true)
                        PhotoCard(.none(), size: .sm, badge: .reaction(.meh))
                    }
                    PhotoCard(
                        .none(cuisine: "japanese"), size: .md, badge: .score(0.75),
                        isFavorite: isFavorite, onToggleFavorite: { isFavorite.toggle() }
                    )
                    PhotoCard(.none(cuisine: "thai"), size: .md, isFavorite: true)
                    PhotoCard(.none(), size: .lg, badge: .custom(Badge("Cover", variant: .secondary, appearance: .elevated, size: .sm)))
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PhotoCardGallery() }
#Preview("Dark") { PhotoCardGallery().preferredColorScheme(.dark) }
