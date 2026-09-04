import SwiftUI

/// Meal detail view presenting:
/// - Harmonized centered arc photo deck, dinner party sentence title, and date
/// - Dedicated Average Rating card finely divided between numerical score and qualitative verdict
/// - Participants card with individual member ratings
/// - Details card with chef, cooking time / effort, and tags (date excluded)
/// - Past occasions the dinner party had with this specific recipe
struct MealDetailView: View {
    let mealID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var showRecipeSheet = false
    @State private var selectedPartyForSheet: Party?
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
            if showCloseButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Close")
                }
            }

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
        .sheet(isPresented: $showRecipeSheet) {
            if let meal {
                NavigationStack {
                    RecipeDetailView(recipeID: meal.recipeID, showCloseButton: true)
                }
            }
        }
        .sheet(item: $selectedPartyForSheet) { party in
            NavigationStack {
                PartyDetailView(partyID: party.id, showCloseButton: true)
            }
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
        let history = partyHistory(for: meal)
        let partyName = currentPartyName(for: meal)

        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                // 1. Photos + Heading sentence + Date (Harmonized Arc Hero Header)
                ArcHeroHeaderView(
                    photoPaths: meal.photoPaths,
                    cuisine: dish?.cuisine,
                    title: mealHeading(for: meal),
                    date: meal.eatenOn,
                    alignment: .center
                ) { index in
                    selectedPhotoIndex = index
                }
                .padding(.bottom, DS.Spacing.xs)

                // 2. Average rating (Finely divided between numerical score and verdict)
                MealDetailAverageRatingCard(meal: meal)
                    .padding(.horizontal, DS.Spacing.screenHorizontal)

                // 3. Participants and individual ratings
                MealDetailPartyRatingsCard(meal: meal)
                    .padding(.horizontal, DS.Spacing.screenHorizontal)

                // 4. Details table: Recipe (tappable row), Chef, Cooking Time, Tags, Notes
                MealDetailCookInfoCard(
                    meal: meal,
                    onOpenRecipe: { showRecipeSheet = true },
                    onOpenParty: { party in selectedPartyForSheet = party }
                )
                .padding(.horizontal, DS.Spacing.screenHorizontal)

                // 5. Past meals the dinner party had with this specific recipe
                if !history.isEmpty {
                    MealDetailHistoryCard(history: history, partyName: partyName)
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                }
            }
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
    }

    private func currentPartyName(for meal: Meal) -> String {
        let parties = store.parties(forMeal: meal.id)
        if !parties.isEmpty {
            return parties.map(\.name).joined(separator: " & ")
        } else if let current = store.currentParty {
            return current.name
        }
        return "You"
    }

    private func mealHeading(for meal: Meal) -> String {
        let partyName = currentPartyName(for: meal)
        let recipeName = store.recipeName(forMeal: meal)
        return "\(partyName) had \(recipeName)"
    }

    private func partyHistory(for meal: Meal) -> [Meal] {
        let partyIDs = Set(store.parties(forMeal: meal.id).map(\.id))
        return store.servings(of: meal.recipeID).filter { past in
            guard past.id != meal.id else { return false }
            let pastParties = store.parties(forMeal: past.id)
            if !partyIDs.isEmpty {
                return !Set(pastParties.map(\.id)).isDisjoint(with: partyIDs)
            } else {
                return pastParties.isEmpty
            }
        }
        .sorted { $0.eatenOn > $1.eatenOn }
    }
}

#Preview {
    NomNomPreview { store in
        if let firstMeal = store.meals.first {
            MealDetailView(mealID: firstMeal.id)
        }
    }
}
