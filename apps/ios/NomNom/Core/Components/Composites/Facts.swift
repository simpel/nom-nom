import SwiftUI

/// One fact: a label over a value ("Serves" · "4").
struct Fact: Hashable {
    let label: String
    let value: String
}

/// Facts `layout`: `grid` is 3 equal columns that wrap (max 6); `strip` is one row with
/// `line` hairlines between items that scrolls sideways.
enum FactsLayout: Equatable { case grid, strip }

/// Small read-only facts about the subject: time, method, servings, rotation
/// (components/Facts/README.md). Each is a SectionHeader label over a `sans-md` value in
/// `text-primary`: no other colours, no icons, nothing that looks pressable (`onSelect` makes a fact a silent button).
///
/// Facts draws no surface; a screen that wants one wraps it in a Card. Items with an empty
/// value are dropped.
///
/// ```swift
/// Card { Facts([Fact(label: "Time", value: "15–30 min"), Fact(label: "Serves", value: "4")]) }
/// Facts(facts, layout: .strip)
/// ```
struct Facts: View {
    let items: [Fact]
    var layout: FactsLayout
    /// Makes every fact a silent button (no pressed look). DS-GAPS.md A, "Facts onSelect".
    var onSelect: ((Fact) -> Void)?

    init(_ items: [Fact], layout: FactsLayout = .grid, onSelect: ((Fact) -> Void)? = nil) {
        self.onSelect = onSelect
        let shown = items.filter { !$0.value.isEmpty }
        self.items = layout == .grid ? Array(shown.prefix(6)) : shown
        self.layout = layout
    }

    var body: some View {
        switch layout {
        case .grid:
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s4, alignment: .topLeading), count: 3),
                alignment: .leading,
                spacing: DS.Spacing.s5
            ) {
                ForEach(items, id: \.self) { FactCell(fact: $0, onSelect: onSelect) }
            }
        case .strip:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DS.Spacing.s4) {
                    ForEach(Array(items.enumerated()), id: \.element) { index, fact in
                        if index > 0 {
                            Rectangle()
                                .fill(DS.Color.line)
                                .frame(width: DS.BorderWidth.hairline)
                        }
                        FactCell(fact: fact, onSelect: onSelect)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Label over value; the one cell both layouts share.
private struct FactCell: View {
    let fact: Fact
    var onSelect: ((Fact) -> Void)?

    var body: some View {
        if let onSelect {
            Button { onSelect(fact) } label: { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            SectionHeader(title: fact.label)
            Text(fact.value).textStyle(.sansMd)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct FactsGallery: View {
    private let recipe = [
        Fact(label: "Time", value: "15\u{2013}30 min"),
        Fact(label: "Method", value: "Frying"),
        Fact(label: "Serves", value: "4"),
        Fact(label: "Rotation", value: "Staple"),
    ]

    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                Card { Facts(recipe) }
                Facts(recipe, layout: .strip)
            }
            .padding(DS.Spacing.gutter)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { FactsGallery() }
#Preview("Dark") { FactsGallery().preferredColorScheme(.dark) }
