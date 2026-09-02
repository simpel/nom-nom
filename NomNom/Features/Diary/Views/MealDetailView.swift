import SwiftUI

/// Simplified meal detail view presenting:
/// - Centered photo arc deck
/// - Heading: "[Dinnerparty] had [recipe]"
/// - Centered date
/// - Hero gradient card with dinner party users & ratings (with quick re-rating & ask-to-rate)
/// - Hero gradient card with details table (label on left, value on right)
struct MealDetailView: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store
    @State private var showEditor = false
    @State private var selectedPhotoIndex: Int?

    private var meal: Meal? { store.meal(mealID) }

    var body: some View {
        Group {
            if let meal {
                content(for: meal)
            } else {
                ContentUnavailableView(
                    "Meal is gone",
                    systemImage: "questionmark.folder",
                    description: Text("It looks like this meal was deleted.")
                )
            }
        }
        .navigationTitle(meal.map { store.dishName(forMeal: $0) } ?? "Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let meal, meal.createdBy == store.userID {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditor = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            MealEditorView(mealID: mealID)
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { wrapper in
            if let meal {
                MealGalleryViewerSheet(paths: meal.photoPaths, initialIndex: wrapper.index)
            }
        }
    }

    @ViewBuilder
    private func content(for meal: Meal) -> some View {
        let dish = store.dish(meal.dishID)
        let history = store.servings(of: meal.dishID).filter { $0.id != meal.id }

        ScrollView {
            VStack(spacing: 20) {
                // 1. Photos, centered (arc presentation, if photos exist)
                if !meal.photoPaths.isEmpty {
                    RecipePhotoArcDeck(photoPaths: meal.photoPaths) { index in
                        selectedPhotoIndex = index
                    }
                }

                // 2. Heading: "[Dinnerparty] had [recipie]" - centered & tappable
                // 3. Date, centered
                NavigationLink {
                    RecipeDetailView(recipeID: meal.recipeID)
                } label: {
                    PageHeader(
                        title: mealHeading(for: meal),
                        subtitle: meal.eatenOn.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
                    )
                }
                .buttonStyle(.plain)

                // 4. Hero card: List of dinner party users & their rates incl yourself
                MealDetailPartyRatingsCard(meal: meal)
                    .padding(.horizontal, 16)

                // 5. Hero card: Details table (label on left, value on right)
                MealDetailCookInfoCard(meal: meal)
                    .padding(.horizontal, 16)

                // Optional Recipe instructions if present
                if let dish, dish.hasInstructions {
                    RecipeInstructionsCard(recipe: dish)
                        .padding(.horizontal, 16)
                }

                // Cooked history if any
                if !history.isEmpty {
                    MealDetailHistoryCard(history: history)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func mealHeading(for meal: Meal) -> String {
        let parties = store.parties(forMeal: meal.id)
        let partyName: String
        if !parties.isEmpty {
            partyName = parties.map(\.name).joined(separator: " & ")
        } else if let current = store.currentParty {
            partyName = current.name
        } else {
            partyName = "You"
        }
        let recipeName = store.recipeName(forMeal: meal)
        return "\(partyName) had \(recipeName)"
    }
}

#Preview {
    NomNomPreview { store in
        if let firstMeal = store.meals.first {
            MealDetailView(mealID: firstMeal.id)
        }
    }
}
