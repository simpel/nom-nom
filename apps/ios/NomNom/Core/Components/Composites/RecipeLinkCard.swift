import SwiftUI

/// A pressable Card `sm` linking a meal to its recipe (components/RecipeLinkCard/README.md):
/// a PhotoCard `xs` thumbnail (`portrait` 60 × 80 by default, from PhotoCard's `format`
/// axis), a "RECIPE" SectionHeader, the name in `serif-sm`, a `sans-sm` tertiary meta
/// line joined with " · ", and Card's chevron. The whole card is one button; padding
/// `s4` (Card `sm`), gap `s3_5`.
struct RecipeLinkCard: View {
    let name: String
    var photo: PhotoCardSource
    /// The thumbnail's PhotoCard format; pass `.landscape` for wide photography.
    var format: PhotoCardFormat
    /// Parts of the meta line (time range, method, dish kind); empty parts are dropped.
    var meta: [String]
    var eyebrow: String
    let action: () -> Void

    init(
        name: String,
        photo: PhotoCardSource,
        format: PhotoCardFormat = .portrait,
        meta: [String] = [],
        eyebrow: String = "Recipe",
        action: @escaping () -> Void
    ) {
        self.name = name
        self.photo = photo
        self.format = format
        self.meta = meta
        self.eyebrow = eyebrow
        self.action = action
    }

    init(recipe: Recipe, format: PhotoCardFormat = .portrait, meta: [String] = [], action: @escaping () -> Void) {
        self.init(name: recipe.name, photo: .recipe(recipe), format: format, meta: meta, action: action)
    }

    private var metaLine: String? {
        let parts = meta.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " \u{00B7} ")
    }

    var body: some View {
        Card(size: .sm, action: action) {
            HStack(spacing: DS.Spacing.s3_5) {
                PhotoCard(photo, size: .xs, format: format)
                // bundle.css `.nn-recipe-link__body { gap: var(--spacing-1) }`.
                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                    SectionHeader(title: eyebrow)
                    Text(name)
                        .textStyle(.serifSm)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let metaLine {
                        Text(metaLine)
                            .textStyle(.sansSm, tone: .tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([eyebrow, name, metaLine].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}

private struct RecipeLinkCardGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) { store in
            VStack(spacing: DS.Spacing.s4) {
                RecipeLinkCard(
                    name: "Spaghetti carbonara",
                    photo: .none(cuisine: "italian"),
                    meta: ["15\u{2013}30 min", "Stovetop", "Pasta"]
                ) {}
                RecipeLinkCard(name: "Grandma's stew", photo: .none(), format: .landscape) {}
                if let recipe = store.recipes.first {
                    RecipeLinkCard(recipe: recipe, meta: ["Oven"]) {}
                }
            }
            .padding(DS.Spacing.gutter)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { RecipeLinkCardGallery() }
#Preview("Dark") { RecipeLinkCardGallery().preferredColorScheme(.dark) }
