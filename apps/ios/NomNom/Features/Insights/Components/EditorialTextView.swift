import SwiftUI

/// An AI narrative in `serif-xs`. Positive fragments are inked `primary-text` and
/// negative ones `warning-text` (README "Colour": warning marks a downward change);
/// reaction colours stay out of body text (README: reaction colour "never tints a
/// card, body text or a photo").
struct EditorialTextView: View {
    let segments: [GuestNoteSegment]

    var body: some View {
        segments.reduce(Text("")) { result, segment in
            switch segment.tone {
            case .neutral:
                return result + Text(segment.text)
            case .positive:
                return result + Text(segment.text).foregroundStyle(DS.Color.primaryText)
            case .negative:
                return result + Text(segment.text).foregroundStyle(DS.Color.warningText)
            }
        }
        .textStyle(.serifXs)
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension EditorialTextView {
    /// A party's AI summary sentence (markdown-inked), or the "check back later" line
    /// when there is none yet.
    init(insightSummary: String?) {
        let text = insightSummary ?? ""
        self.init(segments: text.isEmpty
            ? [GuestNoteSegment(text: "Check back later when enough meals have been rated by the party.", tone: .neutral)]
            : MarkdownSegmentParser.parse(text))
    }
}
