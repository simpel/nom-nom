import SwiftUI

/// Shows user profile information: avatar header, combined dinner parties and averages,
/// created recipes, and meal history.
struct PersonDetailView: View {
    let raterRef: RaterRef
    var isSheet: Bool = false

    @Environment(FoodStore.self) private var store
    @State private var showingEditProfile = false
    @State private var photoError: String?

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
            VStack(spacing: DS.Spacing.block) {
                ProfileHeaderCard(
                    name: personName,
                    photoPath: photoPath,
                    isCurrentUser: isCurrentUser,
                    onEdit: { showingEditProfile = true },
                    avatarEdit: ScreenHeaderAvatarEdit(
                        hasPhoto: photoPath?.isEmpty == false,
                        onPick: { savePhoto($0) },
                        onRemove: { savePhoto(nil) }
                    )
                )

                ProfileInsightsSection(raterRef: raterRef)

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
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .refreshable {
            await store.load()
        }
        .screenTitle("", displayMode: .inline)
        .modifier(SheetToolbarConditional(isSheet: isSheet))
        .sheet(isPresented: $showingEditProfile) {
            NavigationStack {
                SettingsView(showsProfileLink: false)
                    .sheetCloseToolbar()
            }
            .dsSheet()
        }
        .alert("Couldn't Save Photo", isPresented: Binding(
            get: { photoError != nil },
            set: { if !$0 { photoError = nil } }
        )) {
            Button("OK") { photoError = nil }
        } message: {
            Text(photoError ?? "")
        }
    }

    /// Your own avatar, from the header's pen: `nil` removes the photo.
    private func savePhoto(_ data: Data?) {
        guard let profile = store.myProfile else { return }
        Task {
            await store.updateProfile(firstName: profile.firstName, lastName: profile.lastName,
                                      newPhotoData: data, removePhoto: data == nil)
            if let message = store.errorMessage {
                photoError = message
                store.errorMessage = nil
            }
        }
    }
}

private struct SheetToolbarConditional: ViewModifier {
    let isSheet: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSheet {
            content.sheetCloseToolbar()
        } else {
            content.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PageMenu()
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
