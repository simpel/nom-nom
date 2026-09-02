import SwiftUI

/// A shared, reusable card container for sections across the entire app.
/// The section title and optional caption are always rendered outside above the card,
/// with consistent photo-deck soft shadow and optional reactive gradient tinting.
struct SectionCard<Content: View>: View {
    var title: String?
    var caption: String?
    var color: Color?
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        caption: String? = nil,
        color: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.caption = caption
        self.color = color
        self.content = content
    }

    init(
        title: String? = nil,
        caption: String? = nil,
        color: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.caption = caption
        self.color = color
        self.content = content
    }

    init(
        header: String,
        caption: String? = nil,
        color: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = header
        self.caption = caption
        self.color = color
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section heading is ALWAYS outside above the card
            if title != nil || caption != nil {
                HStack(alignment: .firstTextBaseline) {
                    if let title {
                        Text(title)
                            .font(.inter(.title3, weight: .semibold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(.horizontal, 4)
                    }

                    Spacer()

                    if let caption {
                        Text(caption)
                            .font(.inter(.subheadline, weight: .regular))
                            .foregroundStyle(color ?? DS.Color.textSecondary)
                            .padding(.trailing, 4)
                    }
                }
            }

            // Card container
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: color != nil ? [
                                    color!.opacity(0.18),
                                    color!.opacity(0.05),
                                    DS.Color.panel
                                ] : [
                                    DS.Color.panel,
                                    DS.Color.panel
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                .strokeBorder(DS.Color.line, lineWidth: 0.5)
                        }
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: color)
    }
}
