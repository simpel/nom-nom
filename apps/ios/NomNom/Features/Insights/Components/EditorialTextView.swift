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
