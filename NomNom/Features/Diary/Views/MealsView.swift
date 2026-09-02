import SwiftUI

/// Tab 1 — Meals. Shows a top action to log a meal, pending ratings, and your meal history.
struct MealsView: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth

    @State private var editorTarget: MealEditorTarget?
    @State private var activeSheet: MealsActiveSheet?
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    private enum MealsActiveSheet: Identifiable {
        case profile
        case createParty
        case partyDetail(Party)
        case householdMembers
        case allParties

        var id: String {
            switch self {
            case .profile: return "profile"
            case .createParty: return "createParty"
            case .partyDetail(let p): return "partyDetail_\(p.id)"
            case .householdMembers: return "householdMembers"
            case .allParties: return "allParties"
            }
        }
    }

    private var currentMeals: [Meal] {
        store.activeMeals
    }

    private var historySections: [(title: String, meals: [Meal])] {
        currentMeals.groupedByRelativeDate()
    }

    var body: some View {
        NavigationStack {
            Group {
                if currentMeals.isEmpty && store.awaitingMyRating.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            MealsToRateSection()

                            ForEach(historySections, id: \.title) { section in
                                SectionCard(section.title) {
                                    VStack(spacing: 10) {
                                        ForEach(section.meals) { meal in
                                            NavigationLink {
                                                MealDetailView(mealID: meal.id)
                                            } label: {
                                                MealRow(meal: meal)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                if meal.createdBy == store.userID {
                                                    Button {
                                                        editorTarget = .existing(meal.id)
                                                    } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }
                                                    Button(role: .destructive) {
                                                        Task { await store.delete(meal: meal) }
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }

                                            if meal.id != section.meals.last?.id {
                                                Divider()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(DS.Color.bg)
                    .refreshable { await store.load() }
                }
            }
            .screenTitle(store.currentParty?.name ?? "Meals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        SettingsDropdownMenu(
                            onOpenProfile: { activeSheet = .profile },
                            onOpenAllParties: { activeSheet = .allParties },
                            onRequestSignOut: { confirmSignOut = true },
                            onRequestDeleteAccount: { confirmDelete = true }
                        )
                        Button {
                            editorTarget = .new
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel("Log a meal")
                    }
                }
            }
            .sheet(item: $editorTarget) { target in
                MealEditorView(mealID: target.mealID)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .profile:
                    ProfileSheetView()
                case .createParty:
                    CreatePartySheet()
                case .partyDetail(let party):
                    NavigationStack {
                        PartyDetailView(partyID: party.id)
                    }
                case .householdMembers:
                    HouseholdMembersSheet()
                case .allParties:
                    NavigationStack {
                        PartyListView()
                    }
                }
            }
            .alert("Sign out?", isPresented: $confirmSignOut) {
                Button("Sign out", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your food log stays on the server and comes back when you sign in again.")
            }
            .alert("Delete your account?", isPresented: $confirmDelete) {
                Button("Delete everything", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your account, every meal and photo you've logged, and the people you track. It cannot be undone.")
            }
            .alert("Couldn't delete your account",
                   isPresented: Binding(get: { auth.errorMessage != nil },
                                        set: { if !$0 { auth.errorMessage = nil } })) {
                Button("OK") { auth.errorMessage = nil }
            } message: {
                Text(auth.errorMessage ?? "")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing logged yet", systemImage: "fork.knife")
        } description: {
            if let party = store.currentParty {
                Text("No meals have been served to \(party.name) yet. Log tonight's dinner and serve it to this party!")
            } else {
                Text("Snap a photo of tonight's dinner, give it a name and mark how it went down.")
            }
        } actions: {
            Button("Log a meal") { editorTarget = .new }
                .buttonStyle(.borderedProminent)
        }
    }
}

typealias LogListView = MealsView

#Preview("With Meals") {
    NomNomPreview(inNavigationStack: false) {
        MealsView()
    }
}

#Preview("Empty State") {
    NomNomPreview(store: .empty, inNavigationStack: false) {
        MealsView()
    }
}
