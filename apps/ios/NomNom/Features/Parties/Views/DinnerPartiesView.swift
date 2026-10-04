import SwiftUI

/// Main Tab — Dinner Parties ("Nom Nom iOS" canvas): the ScreenHeader with "New party",
/// pending invitations, "Your parties" and a "Find parties" row leading to followed
/// and public parties, `spacing-7` apart.
struct DinnerPartiesView: View {
    var isSheet: Bool = false

    @Environment(FoodStore.self) private var store

    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    if !isSheet {
                        ScreenHeader(
                            "Your dinner parties",
                            summary: "The people you cook for and eat with.",
                            role: .tabRoot,
                            actions: [ScreenHeaderAction(title: "New party") { showingCreateSheet = true }]
                        )
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
                        DSSection("Your parties", trailing: "\(store.myParties.count)") {
                            VStack(spacing: DS.Spacing.s4) {
                                ForEach(store.myParties) { DinnerPartyCard(party: $0) }
                            }
                        }
                    }

                    Card(layout: .list) {
                        NavigationLink {
                            FindPartiesView()
                        } label: {
                            ListRow("Find parties", meta: "Public parties to follow", leading: .icon("magnifyingglass"), chevron: true)
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
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
/// root: the shared main-tab toolbar (the page menu).
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
