import SwiftUI

/// What stood out, as TagToggles grouped under SectionHeaders (Flavour, Texture,
/// Cooking, Feel; Why for Can't eat). The options already fit the verdict and the
/// dish (`FoodStore.ratingTagOptions`), in order.
struct RateTagsPicker: View {
    @Binding var tags: Set<String>
    let options: [RatingTagOption]

    private var groups: [(group: RatingTagGroup, tags: [RatingTagOption])] {
        RatingTagGroup.allCases.compactMap { group in
            let tags = options.filter { $0.group == group }
            return tags.isEmpty ? nil : (group, tags)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s5) {
            ForEach(groups, id: \.group) { entry in
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    SectionHeader(title: entry.group.title)
                        .padding(.horizontal, DS.Spacing.sectionInset)
                    WrappingHStack(spacing: DS.Spacing.s2, lineSpacing: DS.Spacing.s2) {
                        ForEach(entry.tags) { tag in
                            TagToggle(title: tag.label, isOn: tags.contains(tag.id)) { toggle(tag.id) }
                        }
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tags)
    }

    private func toggle(_ id: String) {
        if tags.contains(id) { tags.remove(id) } else { tags.insert(id) }
    }
}

extension EnvironmentValues {
    /// The traits of the meal being rated (`FoodStore.ratingTraits(forMeal:)`), set by
    /// RateMealSheet so every step and answer sheet offers the same tags.
    @Entry var ratingTraits: Set<String> = []
}

#Preview {
    @Previewable @State var tags: Set<String> = []

    NomNomPreview { store in
        RateTagsPicker(tags: $tags, options: store.ratingTagOptions(for: .meh, traits: ["meat_fish"]))
            .padding(DS.Spacing.gutter)
            .background(DS.Color.sheet)
    }
}
