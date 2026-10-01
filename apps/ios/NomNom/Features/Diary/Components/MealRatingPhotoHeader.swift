import SwiftUI

/// The top of the rating screens (MealRatingSheet, MealVerdictStepView): a read-only
/// PhotoStrip with the meal's photos followed by its recipe's, over a centred
/// DetailHeader with the dish name and the date. With no photos at all the strip shows
/// the cuisine photo (or the no-photo tile).
struct MealRatingPhotoHeader: View {
    let mealPhotos: [PhotoCardSource]
    let recipePhotos: [PhotoCardSource]
    var cuisine: String?
    let title: String
    let date: Date
    var onSelectMealPhoto: (Int) -> Void
    var onSelectRecipePhoto: (Int) -> Void

    private var photos: [PhotoCardSource] {
        let all = mealPhotos + recipePhotos
        return all.isEmpty ? [.none(cuisine: cuisine)] : all
    }

    private var hasPhotos: Bool { !mealPhotos.isEmpty || !recipePhotos.isEmpty }

    var body: some View {
        VStack(spacing: DS.Spacing.s5) {
            PhotoStrip(photos: photos, onSelect: select)
                .frame(maxWidth: .infinity, alignment: .leading)

            DetailHeader(
                title: title,
                align: .center,
                meta: date.formatted(.dateTime.weekday(.wide).day().month(.wide))
            )
        }
    }

    private func select(_ index: Int) {
        guard hasPhotos else { return }
        if index < mealPhotos.count {
            onSelectMealPhoto(index)
        } else {
            onSelectRecipePhoto(index - mealPhotos.count)
        }
    }
}

extension Recipe {
    /// The recipe photos the rating screens show and open in the viewer: the recipe's
    /// own pages, else its cover photos (all in the recipe bucket).
    var ratingHeaderPhotoPaths: [String] {
        recipePhotoPaths.isEmpty ? photoPaths : recipePhotoPaths
    }

    var ratingHeaderPhotos: [PhotoCardSource] {
        ratingHeaderPhotoPaths.map { .remote(path: $0, bucket: SupabaseConfig.recipeBucket, cuisine: cuisine) }
    }
}

#Preview {
    NomNomPreview {
        ScrollView {
            MealRatingPhotoHeader(
                mealPhotos: [.none(cuisine: "italian")],
                recipePhotos: [.none(cuisine: "mexican")],
                title: "Spaghetti carbonara",
                date: .now,
                onSelectMealPhoto: { _ in },
                onSelectRecipePhoto: { _ in }
            )
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}
