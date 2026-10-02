import SwiftUI

struct EditorialTextView: View {
    let segments: [GuestNoteSegment]

    var body: some View {
        segments.reduce(Text("")) { result, segment in
            switch segment.tone {
            case .neutral:
                return result + Text(segment.text)
            case .positive:
                return result + Text(segment.text)
                    .font(.newsreader(.serifSm))
                    .foregroundStyle(Reaction.great.text)
            case .negative:
                return result + Text(segment.text)
                    .font(.newsreader(.serifSm))
                    .foregroundStyle(Reaction.bad.text)
            }
        }
        .font(.editorialSummary)
        .foregroundStyle(DS.Color.textPrimary)
        .lineSpacing(DS.TextStyle.serifXs.lineSpacing())
    }
}
