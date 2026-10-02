import SwiftUI

/// Main Tab — Dinner Parties.
/// Pending invites, the viewer's parties, followed parties and public parties to
/// follow, `spacing-7` apart (README "Layout": `spacing-7` between blocks).
struct DinnerPartiesView: View {
    var isSheet: Bool = false

    @Environment(FoodStore.self) private var store

    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    if !isSheet {
                        PageHeader("Parties", actions: [
                            EmptyStateAction("New party", icon: "plus") { showingCreateSheet = true }
                        ])
                    }

                    PendingPartyInvitesSection()

                    if store.myParties.isEmpty {
                        // README case "A list the person will fill": the action that fills it.
                        EmptyState(
                            "No dinner parties yet",
                            message: "Start one to log meals and rate them together.",
                            action: EmptyStateAction("New party") { showingCreateSheet = true }
                        )
                    } else {
                        VStack(spacing: DS.Spacing.s4) {
                            ForEach(store.myParties) { DinnerPartyCard(party: $0) }
                        }
                    }

                    FollowedPartiesSection()

                    DiscoverPartiesSection()
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.bg)
            .refreshable {
                await store.load()
            }
            .modifier(DinnerPartiesToolbar(isSheet: isSheet) { showingCreateSheet = true })
            .sheet(isPresented: $showingCreateSheet) {
                CreatePartySheet()
            }
        }
    }
}

/// As a sheet: "Dinner Parties" with the overview toolbar (close + create). As a tab
/// root: the shared main-tab toolbar (inbox bell + settings).
private struct DinnerPartiesToolbar: ViewModifier {
    let isSheet: Bool
    let onCreate: () -> Void

    func body(content: Content) -> some View {
        if isSheet {
            content
                .screenTitle("Dinner Parties", displayMode: .inline)
                .sheetOverviewToolbar(primarySystemImage: "plus", onPrimaryAction: onCreate)
        } else {
            content.mainTabToolbar()
        }
    }
}

#Preview {
    NomNomPreview { _ in
        DinnerPartiesView()
    }
}
