import SwiftUI

/// A section of things the viewer may add to: the one place the rule for "Add", "New" and
/// "Log" lives (design-system/components/CollectionSection/README.md).
///
/// | items | viewer can add | draws |
/// | --- | --- | --- |
/// | some | yes | the header, with `verb` as its section action |
/// | some | no | the header, label only |
/// | none | yes | the EmptyState with the button; no header action |
/// | none | no | the EmptyState, no button (its message says whose it is) |
///
/// The count only decides "empty"; it is not drawn, because "Meal history 31" says nothing
/// the list does not. Pass `showsCount` for a number the person acts on.
///
/// ```swift
/// CollectionSection("Meal history", count: meals.count, verb: "Log meal", addLabel: "Log a meal",
///                   onAdd: isMe ? { editor = .new } : nil,
///                   emptyTitle: "No meals yet", emptyMessage: "Meals you log will show up here.") {
///     Card(layout: .list) { … }
/// }
/// ```
struct CollectionSection<Content: View>: View {
    let title: String
    let count: Int
    var showsCount: Bool
    var verb: String
    var addLabel: String?
    /// `nil` when this viewer cannot add: no button is drawn anywhere.
    var onAdd: (() -> Void)?
    let emptyTitle: String
    var emptyMessage: String?
    @ViewBuilder var content: Content

    init(
        _ title: String,
        count: Int,
        showsCount: Bool = false,
        verb: String = "Add",
        addLabel: String? = nil,
        onAdd: (() -> Void)? = nil,
        emptyTitle: String,
        emptyMessage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.showsCount = showsCount
        self.verb = verb
        self.addLabel = addLabel
        self.onAdd = onAdd
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.content = content()
    }

    private var headerAction: SectionAction? {
        guard count > 0, let onAdd else { return nil }
        return SectionAction(verb, accessibilityLabel: addLabel, perform: onAdd)
    }

    private var emptyAction: EmptyStateAction? {
        guard let onAdd else { return nil }
        return EmptyStateAction(addLabel ?? verb, perform: onAdd)
    }

    var body: some View {
        DSSection(title, trailing: showsCount ? "\(count)" : nil, action: headerAction) {
            if count == 0 {
                EmptyState(emptyTitle, message: emptyMessage, action: emptyAction)
            } else {
                content
            }
        }
    }
}

private struct CollectionSectionGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            CollectionSection(
                "Meal history", count: 2, verb: "Log meal", addLabel: "Log a meal", onAdd: {},
                emptyTitle: "No meals yet"
            ) {
                Card(layout: .list) {
                    ListRow("Slow-Cooked Bolognese", meta: "23 Aug 2026")
                    ListRow("Fresh Basil Pesto Penne", meta: "7 Aug 2026")
                }
            }
            CollectionSection(
                "Created recipes", count: 0, verb: "Add recipe", addLabel: "Add a recipe", onAdd: {},
                emptyTitle: "No recipes yet", emptyMessage: "Recipes you add will show up here."
            ) { EmptyView() }
            CollectionSection(
                "Created recipes", count: 0,
                emptyTitle: "No recipes yet", emptyMessage: "Recipes this person adds will show up here."
            ) { EmptyView() }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { CollectionSectionGallery() }
#Preview("Dark") { CollectionSectionGallery().preferredColorScheme(.dark) }
