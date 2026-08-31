import SwiftUI

/// Tab 1 — the diary. Newest first, grouped by month, scoped to "Just me" or a selected Dinner Party.
struct LogListView: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth

    @State private var editorTarget: MealEditorTarget?
    @State private var activeSheet: DiaryActiveSheet?
    @State private var search = ""
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    private enum DiaryActiveSheet: Identifiable {
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

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    private var currentMeals: [Meal] {
        store.activeMeals
    }

    private var filtered: [Meal] {
        let key = search.normalizedForMatching
        guard !key.isEmpty else { return currentMeals }
        return currentMeals.filter { meal in
            let name = store.dish(meal.dishID)?.normalizedName ?? ""
            return name.contains(key) || meal.notes.normalizedForMatching.contains(key)
        }
    }

    private var sections: [(title: String, meals: [Meal])] {
        let calendar = Calendar.current

        var order: [Date] = []
        var buckets: [Date: [Meal]] = [:]
        for meal in filtered {
            let key = calendar.date(from: calendar.dateComponents([.year, .month], from: meal.eatenOn)) ?? meal.eatenOn
            if buckets[key] == nil {
                buckets[key] = []
                order.append(key)
            }
            buckets[key]?.append(meal)
        }
        return order.map { (Self.monthFormatter.string(from: $0), buckets[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if currentMeals.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sections, id: \.title) { section in
                            Section(section.title) {
                                ForEach(section.meals) { meal in
                                    NavigationLink {
                                        MealDetailView(mealID: meal.id)
                                    } label: {
                                        MealRow(meal: meal)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        if meal.createdBy == store.userID {
                                            Button(role: .destructive) {
                                                Task { await store.delete(meal: meal) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            Button {
                                                editorTarget = .existing(meal.id)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.indigo)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $search, prompt: "Search meals")
                    .refreshable { await store.load() }
                }
            }
            .navigationTitle(store.currentParty?.name ?? "Food log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        SettingsDropdownMenu(
                            onOpenProfile: { activeSheet = .profile },
                            onOpenPartyDetail: { party in activeSheet = .partyDetail(party) },
                            onOpenHouseholdMembers: { activeSheet = .householdMembers },
                            onOpenCreateParty: { activeSheet = .createParty },
                            onOpenAllParties: { activeSheet = .allParties },
                            onRequestSignOut: { confirmSignOut = true },
                            onRequestDeleteAccount: { confirmDelete = true }
                        )

                        if store.myParties.count > 1 {
                            PartySwitcherMenu()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorTarget = .new
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Log a meal")
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
