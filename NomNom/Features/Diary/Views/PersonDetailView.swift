import SwiftUI

/// Shows user profile information: avatar header, combined dinner parties and averages,
/// created recipes, and meal history.
struct PersonDetailView: View {
    let raterRef: RaterRef
    var isSheet: Bool = false

    @Environment(FoodStore.self) private var store
    @State private var showingEditProfile = false

    private var personName: String {
        switch raterRef {
        case .account(let id):
            if let profile = store.profiles[id] {
                let shown = profile.shownName.trimmingCharacters(in: .whitespaces)
                if !shown.isEmpty && shown != "Someone" {
                    return shown
                }
            }
            if id == store.userID, let my = store.myProfile {
                let shown = my.shownName.trimmingCharacters(in: .whitespaces)
                if !shown.isEmpty && shown != "Someone" {
                    return shown
                }
            }
            return id == store.userID ? "Profile" : "Someone"
        case .eater(let id):
            return store.eater(id)?.name ?? "Someone"
        }
    }

    private var isCurrentUser: Bool {
        if case .account(let id) = raterRef {
            return id == store.userID
        }
        return false
    }

    private var parties: [Party] {
        switch raterRef {
        case .account(let id):
            let partyIDs = Set(store.partyMembers.filter { $0.userID == id }.map(\.partyID))
            return store.parties.filter { partyIDs.contains($0.id) }
        case .eater:
            return store.myParties
        }
    }

    private var subtitle: String {
        let count = parties.count
        let partyWord = count == 1 ? "party" : "parties"
        switch raterRef {
        case .account(let id):
            if id == store.userID {
                return count == 0 ? "Personal Profile" : "Member of \(count) \(partyWord)"
            }
            return count == 0 ? "Dinner party guest" : "Member of \(count) \(partyWord)"
        case .eater:
            return "Household member"
        }
    }

    private var createdRecipes: [Recipe] {
        guard case .account(let id) = raterRef else { return [] }
        return store.recipes.filter { $0.ownerID == id }.sorted { $0.createdAt > $1.createdAt }
    }

    private var meals: [Meal] {
        var mealSet: [UUID: Meal] = [:]
        let ratings = store.ratings(for: raterRef)
        for rating in ratings {
            if let meal = store.meal(rating.mealID) {
                mealSet[meal.id] = meal
            }
        }
        if case .account(let id) = raterRef {
            for meal in store.meals where meal.createdBy == id {
                mealSet[meal.id] = meal
            }
        }
        return mealSet.values.sorted { $0.eatenOn > $1.eatenOn }
    }

    private var photoPath: String? {
        guard case .account(let id) = raterRef else { return nil }
        if id == store.userID {
            return store.myProfile?.photoPath
        }
        return store.profiles[id]?.photoPath
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                ProfileHeaderCard(
                    name: personName,
                    subtitle: subtitle,
                    photoPath: photoPath,
                    isCurrentUser: isCurrentUser
                )

                ProfilePartiesSection(
                    parties: parties,
                    raterRef: raterRef
                )

                if case .account = raterRef {
                    ProfileCreatedRecipesSection(recipes: createdRecipes)
                }

                ProfileMealHistorySection(
                    meals: meals,
                    raterRef: raterRef
                )
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .screenTitle("", displayMode: .inline)
        .modifier(SheetToolbarConditional(isSheet: isSheet, isCurrentUser: isCurrentUser, onEdit: {
            showingEditProfile = true
        }))
        .sheet(isPresented: $showingEditProfile) {
            ProfileSheetView()
        }
    }
}

private struct SheetToolbarConditional: ViewModifier {
    let isSheet: Bool
    let isCurrentUser: Bool
    let onEdit: () -> Void

    func body(content: Content) -> some View {
        if isSheet {
            content
                .sheetCloseToolbar()
                .toolbar {
                    if isCurrentUser {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Edit", action: onEdit)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
        } else {
            content
                .toolbar {
                    if isCurrentUser {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Edit", action: onEdit)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
        }
    }
}

#Preview {
    NomNomPreview { store in
        PersonDetailView(raterRef: .account(store.userID))
    }
}
