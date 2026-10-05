import SwiftUI

/// Someone who hasn't rated a meal yet: a BottomSheet titled with their name, the
/// PersonHeaderRow and the Ask / Remind button (RaterRemindButton). No empty score:
/// the meal's score card already says nobody has. A household member (no account)
/// gets one line saying whoever logs the meal adds their verdict.
struct RaterPendingSheet: View {
    let meal: Meal
    let rater: RaterRef

    @Environment(FoodStore.self) private var store
    @State private var showProfile = false
    @State private var justSent = false

    private var profile: Profile? {
        if case .account(let id) = rater { return store.profiles[id] }
        return nil
    }

    var body: some View {
        let name = store.firstName(for: rater)

        NavigationStack {
            SheetBody {
                RaterPersonRow(meal: meal, rater: rater) { showProfile = true }
                if profile == nil {
                    Text("Household members\u{2019} verdicts are added by whoever logs the meal.")
                        .textStyle(.sansSm, tone: .tertiary)
                }
                if let profile {
                    RaterRemindButton(meal: meal, profile: profile, name: name, justSent: $justSent)
                }
            }
            .screenTitle(name, displayMode: .inline)
            .sheetCloseToolbar()
            .navigationDestination(isPresented: $showProfile) {
                PersonDetailView(raterRef: rater)
            }
        }
        .dsSheet(detents: [.medium, .large])
    }
}
