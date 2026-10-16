import SwiftUI

/// The one verb a section offers on the right of its header ("New party", "Log meal",
/// "See all"), drawn by `SectionHeader` as an `AppButton` `primary soft sm`
/// (design-system/components/SectionHeader/README.md, "The section action").
///
/// `label` is one or two words in sentence case. `accessibilityLabel` is the long form
/// VoiceOver reads ("Log a meal"). Hand a section an action only when the viewer can act;
/// never draw one disabled. "See all" is a navigation link (`init(link:destination:)`)
/// and looks exactly the same.
struct SectionAction {
    let label: String
    var accessibilityLabel: String?
    fileprivate let kind: Kind

    fileprivate enum Kind {
        case button(() -> Void)
        case link(AnyView)
        case share(url: URL, subject: String, message: String)
    }

    /// The system share sheet for `url` ("Invite"), drawn as the same soft capsule.
    init(share label: String, accessibilityLabel: String? = nil, url: URL, subject: String, message: String) {
        self.label = label
        self.accessibilityLabel = accessibilityLabel
        self.kind = .share(url: url, subject: subject, message: message)
    }

    init(_ label: String, accessibilityLabel: String? = nil, perform: @escaping () -> Void) {
        self.label = label
        self.accessibilityLabel = accessibilityLabel
        self.kind = .button(perform)
    }

    /// A push to `destination`, drawn as the same soft capsule ("See all").
    init<Destination: View>(
        link label: String,
        accessibilityLabel: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.label = label
        self.accessibilityLabel = accessibilityLabel
        self.kind = .link(AnyView(destination()))
    }
}

/// Draws a `SectionAction`: `AppButton` `primary soft sm`, or the same label as a
/// `NavigationLink` (AGENTS.md §8: a NavigationLink uses `AppButtonLabel`).
struct SectionActionView: View {
    let action: SectionAction

    var body: some View {
        Group {
            switch action.kind {
            case .button(let perform):
                AppButton(action.label, appearance: .soft, size: .sm, action: perform)
            case .link(let destination):
                NavigationLink { destination } label: {
                    AppButtonLabel(action.label, appearance: .soft, size: .sm)
                }
                .buttonStyle(AppPressableButtonStyle())
            case .share(let url, let subject, let message):
                ShareLink(item: url, subject: Text(subject), message: Text(message)) {
                    AppButtonLabel(action.label, appearance: .soft, size: .sm)
                }
                .buttonStyle(AppPressableButtonStyle())
            }
        }
        .accessibilityLabel(action.accessibilityLabel ?? action.label)
    }
}
