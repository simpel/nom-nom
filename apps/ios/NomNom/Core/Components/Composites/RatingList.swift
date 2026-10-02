import SwiftUI

/// Who rated a meal: a section head with the count ("5 of 6", `primary`), a Bar
/// `xs` of rated / total, then one RatingRow per person in a Card `.list`. The viewer's
/// row is always last.
///
/// README rows have no avatar; `showsAvatars` adds an Avatar `xs` leading for screens
/// that still need faces (today's MealDetailMemberRatingRow shows one).
struct RatingList: View {
    let entries: [RatingListEntry]
    var title: String = "Who rated"
    /// Everyone who could rate; defaults to the number of entries.
    var total: Int?
    var showsAvatars: Bool = false

    private var ordered: [RatingListEntry] {
        entries.filter { !$0.isViewer } + entries.filter(\.isViewer)
    }

    private var ratedCount: Int { entries.filter { $0.score != nil }.count }
    private var totalCount: Int { max(total ?? entries.count, ratedCount) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title, trailing: "\(ratedCount) of \(totalCount)", trailingTone: .primary)
            Bar(
                value: Double(ratedCount),
                max: Double(max(totalCount, 1)),
                size: .xs,
                label: "\(ratedCount) of \(totalCount) rated"
            )
            .padding(.horizontal, DS.Spacing.sectionInset)

            Card(layout: .list) {
                ForEach(ordered) { entry in
                    RatingRow(entry: entry, showsAvatar: showsAvatars)
                }
            }
            .padding(.top, DS.Spacing.s3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                RatingList(entries: Array(entries.prefix(3)), total: 4, showsAvatars: true)
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { RatingListGallery() }
#Preview("Dark") { RatingListGallery().preferredColorScheme(.dark) }
