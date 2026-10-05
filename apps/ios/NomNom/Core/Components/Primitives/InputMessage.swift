import SwiftUI

/// The line under an Input or TextArea: the `hint`, replaced by the `error` message
/// (with an alert glyph) when there is one, plus TextArea's optional `{n} / {max}` counter.
/// `sans-xs`; hint `text-secondary`, error and an over-limit counter `destructive-text`,
/// counter `text-tertiary` tabular. Draws nothing when there is nothing to say.
struct InputMessage: View {
    var hint: String?
    var error: String?
    /// Error state without a sentence (`isError`): the hint, if any, turns `destructive-text`.
    var isError: Bool = false
    var count: Int?
    var maxLength: Int?

    private var message: String? {
        if let error, !error.isEmpty { return error }
        if let hint, !hint.isEmpty { return hint }
        return nil
    }

    private var showsAlert: Bool { !(error ?? "").isEmpty }
    private var isOver: Bool {
        guard let count, let maxLength else { return false }
        return count > maxLength
    }

    var body: some View {
        if message != nil || maxLength != nil {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s3) {
                if let message {
                    HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s1) {
                        if showsAlert {
                            Image(systemName: "exclamationmark.circle")
                                .textStyle(.sansXs, tone: nil)
                                .accessibilityHidden(true)
                        }
                        Text(message).textStyle(.sansXs, tone: nil)
                    }
                    .foregroundStyle(showsAlert || isError ? DS.Color.destructiveText : DS.Color.textSecondary)
                    .padding(.horizontal, DS.Spacing.s1)
                }
                Spacer(minLength: 0)
                if let maxLength {
                    Text("\(count ?? 0) / \(maxLength)")
                        .textStyle(.sansXs, tone: nil, numeric: true)
                        .foregroundStyle(isOver ? DS.Color.destructiveText : DS.Color.textTertiary)
                        .accessibilityLabel("\(count ?? 0) of \(maxLength) characters")
                }
            }
            .lineLimit(1)
            .transition(.opacity)
        }
    }
}

extension View {
    /// Announces an error message when it appears (README: an error "is announced when it appears").
    func announcesInputError(_ error: String?) -> some View {
        onChange(of: error) { _, newValue in
            guard let newValue, !newValue.isEmpty else { return }
            AccessibilityNotification.Announcement(newValue).post()
        }
    }
}
