import SwiftUI

/// One row of RatingList's general shape: a label, an optional note and a trailing value.
struct RatingListRow: Identifiable {
    let id: AnyHashable
    var label: String
    var note: String?
    /// The figure on the right. A zero still renders the row at full strength; pass
    /// `isZero` so only the figure drops to `text-tertiary`.
    var value: String?
    var isZero: Bool = false
}

/// The one "section header + meter + list of rows" block, in two shapes:
///
/// - **Who rated** (`entries:`): "5 of 6" as the header's `primary` trailing figure,
///   a Bar `xs` of rated / total, then one RatingRow per person (their change vs
///   their usual and ScoreValue `xs`). The viewer's row is last.
/// - **Any other distribution** (`rows:meter:`): your meter above the card, your rows
///   inside it (SegmentedBar's legend).
///
/// The meter is inset `spacing-2` and sits `spacing-3` above the Card `.list`
/// (bundle.css `.nn-rating-list__meter`).
struct RatingList<Meter: View>: View {
    private enum Shape {
        case raters([RatingListEntry])
        case rows([RatingListRow])
    }

    private let shape: Shape
    private let title: String
    private let trailing: String?
    private let meter: Meter

    var body: some View {
        DSSection(title, trailing: trailing, trailingTone: .primary) {
            meter
                .padding(.horizontal, DS.Spacing.sectionInset)
                .padding(.bottom, DS.Spacing.s3)

            Card(layout: .list) {
                switch shape {
                case .raters(let entries):
                    ForEach(entries) { RatingRow(entry: $0) }
                case .rows(let rows):
                    ForEach(rows) { RatingListValueRow(row: $0) }
                }
            }
        }
    }
}

extension RatingList where Meter == RatingListMeter {
    /// Who rated a meal. `total` is everyone who could rate (defaults to the entries).
    init(entries: [RatingListEntry], title: String = "Who rated", total: Int? = nil) {
        let rated = entries.filter { $0.score != nil }.count
        let total = max(total ?? entries.count, rated)
        self.shape = .raters(entries.filter { !$0.isViewer } + entries.filter(\.isViewer))
        self.title = title
        self.trailing = "\(rated) of \(total)"
        self.meter = RatingListMeter(rated: rated, total: total)
    }
}

extension RatingList {
    /// Any other distribution: `meter` (e.g. a segmented Bar) above the card, `rows` inside it.
    init(_ title: String, trailing: String? = nil, rows: [RatingListRow], @ViewBuilder meter: () -> Meter) {
        self.shape = .rows(rows)
        self.title = title
        self.trailing = trailing
        self.meter = meter()
    }
}

/// The who-rated meter: a Bar `xs` of rated / total.
struct RatingListMeter: View {
    let rated: Int
    let total: Int

    var body: some View {
        Bar(value: Double(rated), max: Double(max(total, 1)), size: .xs, label: "\(rated) of \(total) rated")
    }
}

/// A general-shape row: ListRow rhythm, label `sans-md`, note `sans-sm` tertiary,
/// value `sans-sm` tabular (tertiary when zero).
private struct RatingListValueRow: View {
    let row: RatingListRow

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s3) {
            Text(row.label).textStyle(.sansMd, lines: 1)
            Spacer(minLength: 0)
            if let note = row.note {
                Text(note).textStyle(.sansSm, tone: .tertiary, lines: 1)
            }
            if let value = row.value {
                Text(value).textStyle(.sansSm, tone: row.isZero ? .tertiary : .primary, numeric: true, lines: 1)
            }
        }
        .ratingListRowMetrics()
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// ListRow metrics (bundle.css `.nn-row`): `spacing-3` vertical padding and a
    /// `spacing-14` minimum height.
    func ratingListRowMetrics() -> some View {
        self
            .padding(.vertical, DS.Spacing.s3)
            .frame(maxWidth: .infinity, minHeight: DS.Spacing.rowMin, alignment: .leading)
            .contentShape(Rectangle())
    }
}

private struct RatingListGallery: View {
    private let entries: [RatingListEntry] = [
        RatingListEntry(id: "viewer", name: "Joel", isViewer: true, action: .rate {}),
        RatingListEntry(id: "anna", name: "Anna", role: "chef", score: 0.92, delta: 16),
        RatingListEntry(id: "leo", name: "Leo", score: 0.64, delta: -4),
        RatingListEntry(id: "sam", name: "Sam", score: 0.78, delta: 0),
        RatingListEntry(id: "mia", name: "Mia", score: 0.85, isNew: true),
        RatingListEntry(id: "ola", name: "Ola", action: .ask {}),
        RatingListEntry(id: "eva", name: "Eva", action: .asked),
        RatingListEntry(id: "kim", name: "Kim"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                RatingList(entries: entries)
                RatingList("Who thought what", trailing: "4 ratings", rows: [
                    RatingListRow(id: 5, label: "Loved it", note: "Anna, Mia", value: "2"),
                    RatingListRow(id: 4, label: "Great", value: "2"),
                    RatingListRow(id: 3, label: "Okay", value: "0", isZero: true),
                ]) {
                    Bar(value: 50, size: .xs)
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { RatingListGallery() }
#Preview("Dark") { RatingListGallery().preferredColorScheme(.dark) }
