// DS-GAP: pending design system
import SwiftUI

/// The person at the top of the rater and member sheets ("Nom Nom iOS" canvas): Avatar
/// `lg`, the first name in `serif-sm` (`serif-md` on the member sheet) over a `sans-sm`
/// tertiary meta line, and a `primary` chevron when it opens their profile. A
/// `spacing-14` minimum height, `spacing-3` gap. The DS has no bare person row
/// (ListRow's title is sans and lives in a Card), so this composes Avatar and Text.
struct PersonHeaderRow: View {
    let avatar: Avatar
    let name: String
    var meta: String?
    var nameStyle: DS.TextStyle = .serifSm
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(ListRowButtonStyle())
                .accessibilityHint("Opens \(name)\u{2019}s profile")
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: DS.Spacing.s3) {
            avatar
            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                Text(name).textStyle(nameStyle, lines: 1)
                if let meta {
                    Text(meta).textStyle(.sansSm, tone: .tertiary, lines: 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if action != nil {
                Image(systemName: "chevron.right")
                    .textStyle(.sansLg, tone: .accent)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: DS.Spacing.s14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
