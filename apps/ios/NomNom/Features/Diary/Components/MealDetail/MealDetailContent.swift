import SwiftUI

/// What Meal Detail's blocks ask the screen to present.
struct MealDetailActions {
    var onAddPhoto: (() -> Void)?
    let onSelectPhoto: (Int) -> Void
    let onRate: () -> Void
    let onOpenScore: () -> Void
    let onOpenRecipe: () -> Void
    let onOpenParty: (Party) -> Void
    let onOpenMeal: (UUID) -> Void
}

/// Meal Detail's scrolling body on `bg`, gutter `s4`, `s7` between blocks:
/// PhotoStrip · DetailHeader · ScoreCard · RecipeLinkCard · RatingList · the cook's
/// note · cook and party · Timeline.
struct MealDetailContent: View {
    let meal: Meal
    var topInset: CGFloat = 0
    let actions: MealDetailActions

    @Environment(FoodStore.self) private var store

    var body: some View {
        let history = store.partyHistory(for: meal)
        let change = store.scoreChange(forMeal: meal)

        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                PhotoStrip(
                    photos: photos,
                    onAddPhoto: actions.onAddPhoto,
                    onSelect: { index in
                        if hasPhotos { actions.onSelectPhoto(index) }
                    }
                )

                MealDetailHeader(meal: meal, onRate: actions.onRate)

                ScoreCard(
                    score: store.averageScore(forMeal: meal.id),
                    delta: change?.delta,
                    deltaText: change.map { _ in "from last time this group had it" },
                    deltaReference: change.map(Self.reference),
                    action: actions.onOpenScore
                )

                if let recipe = store.recipe(meal.recipeID) {
                    RecipeLinkCard(recipe: recipe, meta: recipeMeta(recipe), action: actions.onOpenRecipe)
                }

                MealDetailRatingsSection(meal: meal, onRate: actions.onRate)

                if let note = note {
                    SectionCard(note.title, uppercase: false, quote: note.text)
                }

                MealDetailPeopleCard(meal: meal, onOpenParty: actions.onOpenParty)

                if !history.isEmpty {
                    MealDetailTimeline(meal: meal, history: history, onOpenMeal: actions.onOpenMeal)
                }
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, topInset)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
    }

    private var hasPhotos: Bool {
        !Self.photos(for: meal, recipe: store.recipe(meal.recipeID)).isEmpty
    }

    /// Stored photos; with none and no way to add one, the cuisine's category photo.
    private var photos: [PhotoCardSource] {
        let recipe = store.recipe(meal.recipeID)
        let stored = Self.photos(for: meal, recipe: recipe)
        if stored.isEmpty, actions.onAddPhoto == nil { return [.none(cuisine: recipe?.cuisine)] }
        return stored
    }

    /// The cook's note, titled "Joel’s note" (or "Your note").
    private var note: (title: String, text: String)? {
        let text = meal.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if meal.createdBy == store.userID { return ("Your note", text) }
        return ("\(store.firstName(for: .account(meal.createdBy)))\u{2019}s note", text)
    }

    private func recipeMeta(_ recipe: Recipe) -> [String] {
        let times = store.servings(of: recipe.id).count
        let cooked = times == 1 ? "Cooked once" : "Cooked \(times) times"
        let cuisine = Cuisine.formatDisplayNames(from: recipe.cuisine).joined(separator: ", ")
        return [cuisine, times > 0 ? cooked : ""]
    }

    /// "(90 on 20 Mar)": the earlier score and when it was.
    static func reference(_ change: FoodStore.MealScoreChange) -> String {
        let points = Int((change.previousScore * 100).rounded())
        let date = change.previousMeal.eatenOn.formatted(.dateTime.day().month(.abbreviated))
        return "(\(points) on \(date))"
    }

    /// The meal's photos, then the recipe's (recipe pages first, de-duplicated).
    static func photos(for meal: Meal, recipe: Recipe?) -> [PhotoCardSource] {
        meal.photoPaths.map { PhotoCardSource.remote(path: $0) }
            + recipePhotoPaths(recipe).map { PhotoCardSource.remote(path: $0, bucket: SupabaseConfig.recipeBucket) }
    }

    static func recipePhotoPaths(_ recipe: Recipe?) -> [String] {
        guard let recipe else { return [] }
        var seen = Set<String>()
        return (recipe.recipePhotoPaths + recipe.photoPaths).filter { seen.insert($0).inserted }
    }
}
