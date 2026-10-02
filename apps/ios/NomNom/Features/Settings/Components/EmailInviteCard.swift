import SwiftUI

/// Invite someone by email: a SectionCard holding an email Input and a "Send"
/// AppButton (`primary soft sm`, AppButton README: "Send" is a supporting branded
/// action). The hint explains what happens; an invalid address replaces it with an
/// error (Input README: "`error` replaces `hint`"), and a confirmation replaces it
/// after a send. Shared by Settings (household) and the party invite sheet.
struct EmailInviteCard: View {
    let title: String
    let placeholder: String
    let hint: String
    @Binding var email: String
    var isSending: Bool
    var confirmation: String?
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var isInvalid: Bool {
        !email.trimmedName.isEmpty && !email.isValidEmail
    }

    var body: some View {
        SectionCard(title) {
            HStack(alignment: .top, spacing: DS.Spacing.s2) {
                Input(
                    placeholder,
                    text: $email,
                    hint: confirmation ?? hint,
                    error: isInvalid ? "Enter a valid email address, like name@example.com." : nil,
                    isFocused: isFocused
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .onSubmit {
                    if email.isValidEmail { onSend() }
                }

                AppButton("Send", appearance: .soft, size: .sm, isLoading: isSending, action: onSend)
                    .disabled(!email.isValidEmail)
            }
        }
    }
}
