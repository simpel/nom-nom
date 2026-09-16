import SwiftUI

/// Card displaying household members and individual taste selector rows for a meal rating.
struct MealRatingEatersCard: View {
    let eaters: [Eater]
    @Binding var reactions: [UUID: Reaction]

    var body: some View {
        SectionCard(title: "Household Eaters", caption: "Family reactions") {
            VStack(spacing: 10) {
                ForEach(eaters) { eater in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 26, height: 26)
                            Text(eater.name.prefix(1).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text(eater.name)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        TactileTasteSelector(selection: Binding(
                            get: { reactions[eater.id] },
                            set: { reactions[eater.id] = $0 }
                        ))
                    }
                    if eater.id != eaters.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
