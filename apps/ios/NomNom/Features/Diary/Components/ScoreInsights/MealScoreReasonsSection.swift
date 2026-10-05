import SwiftUI

/// "What pulled it down" on the Pro score sheet: the table's negative reasons (tags they
/// picked, then history patterns), and "What held it up" when anything did. Hidden when
/// there are no reasons at all.
struct MealScoreReasonsSection: View {
    let reasons: [TableReason]

    var body: some View {
        let down = reasons.filter(\.isNegative)
        let up = reasons.filter { !$0.isNegative }
        if !down.isEmpty {
            group("What pulled it down", down)
        }
        if !up.isEmpty {
            group("What held it up", up)
        }
    }

    private func group(_ title: String, _ items: [TableReason]) -> some View {
        DSSection(title, trailing: items.count == 1 ? "1 reason" : "\(items.count) reasons") {
            Card(layout: .list) {
                ForEach(items) { ListRow(reason: $0).metaLines(nil) }
            }
        }
    }
}
