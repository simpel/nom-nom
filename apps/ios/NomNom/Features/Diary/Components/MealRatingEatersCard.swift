import SwiftUI

/// The household's eaters, one ListRow each with their taste selector, for a meal rating.
struct MealRatingEatersCard: View {
    let eaters: [Eater]
    @Binding var reactions: [UUID: Reaction]

    var body: some View {
        DSSection("Household eaters") {
            Card(layout: .list) {
                ForEach(eaters) { eater in
                    ListRow(
                        eater.name,
                        leading: .avatar(Avatar(name: eater.name, size: .sm, decorative: true)),
                        trailing: .view {
                            TactileTasteSelector(selection: Binding(
                                get: { reactions[eater.id] },
                                set: { reactions[eater.id] = $0 }
                            ))
                        }
                    )
                }
            }
        }
    }
}
