// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// First and last name in one stacked SectionCard: two labelled `plain` Inputs
/// split by a `line` divider, an optional leading accessory (an Avatar) and an
/// optional footnote. Return in either field runs `onSubmit`.
struct NameFieldsCard<Accessory: View>: View {
    let title: String
    @Binding var firstName: String
    @Binding var lastName: String
    var placeholder: String
    var footnote: String?
    var onSubmit: (() -> Void)?
    @ViewBuilder var accessory: Accessory

    init(
        _ title: String = "Your Name",
        firstName: Binding<String>,
        lastName: Binding<String>,
        placeholder: String = "Required",
        footnote: String? = nil,
        onSubmit: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self._firstName = firstName
        self._lastName = lastName
        self.placeholder = placeholder
        self.footnote = footnote
        self.onSubmit = onSubmit
        self.accessory = accessory()
    }

    var body: some View {
        SectionCard(title) {
            HStack(spacing: DS.Spacing.s3_5) {
                accessory
                VStack(spacing: 0) {
                    Input(label: "First name", placeholder: placeholder, text: $firstName, appearance: .plain)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .onSubmit { onSubmit?() }
                    Rectangle()
                        .fill(DS.Color.line)
                        .frame(height: 1)
                        .accessibilityHidden(true)
                    Input(label: "Last name", placeholder: placeholder, text: $lastName, appearance: .plain)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                        .onSubmit { onSubmit?() }
                }
            }
            if let footnote {
                Text(footnote)
                    .textStyle(.sansXs, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension NameFieldsCard where Accessory == EmptyView {
    init(
        _ title: String = "Your Name",
        firstName: Binding<String>,
        lastName: Binding<String>,
        placeholder: String = "Required",
        footnote: String? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            title, firstName: firstName, lastName: lastName, placeholder: placeholder,
            footnote: footnote, onSubmit: onSubmit
        ) { EmptyView() }
    }
}

private struct NameFieldsCardPreview: View {
    @State private var first = "Anna"
    @State private var last = ""

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            NameFieldsCard(firstName: $first, lastName: $last)
            NameFieldsCard("Your Profile", firstName: $first, lastName: $last, footnote: "Shown to your dinner parties.") {
                Avatar(name: "Anna", size: .lg)
            }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { NameFieldsCardPreview() }
#Preview("Dark") { NameFieldsCardPreview().preferredColorScheme(.dark) }
