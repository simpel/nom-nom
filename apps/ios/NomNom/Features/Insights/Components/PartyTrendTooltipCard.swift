import SwiftUI

/// A row entry in the tooltip, representing one series (party average or a member).
struct TooltipEntry {
    let label: String
    let color: Color
    let score: Double?
}

/// Floating inspection card for trend charts.
/// Displays a date header + optional X dismiss button, then one labelled row per entry.
struct PartyTrendTooltipCard: View {
    let date: Date
    let primaryLabel: String
    let primaryScore: Double?
    let primaryColor: Color
    let secondaryLabel: String?
    let secondaryScore: Double?
    let secondaryColor: Color?
    let valueFormat: String
    var memberEntries: [TooltipEntry] = []
    /// Supply a closure to show an X dismiss button in the top-right corner.
    var onDismiss: (() -> Void)? = nil

    init(
        date: Date,
        primaryLabel: String = "Total",
        primaryScore: Double?,
        primaryColor: Color = DS.Color.Chart.total,
        secondaryLabel: String? = nil,
        secondaryScore: Double? = nil,
        secondaryColor: Color? = nil,
        valueFormat: String = "%.0f",
        memberEntries: [TooltipEntry] = [],
        onDismiss: (() -> Void)? = nil
    ) {
        self.date = date
        self.primaryLabel = primaryLabel
        self.primaryScore = primaryScore
        self.primaryColor = primaryColor
        self.secondaryLabel = secondaryLabel
        self.secondaryScore = secondaryScore
        self.secondaryColor = secondaryColor
        self.valueFormat = valueFormat
        self.memberEntries = memberEntries
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            // Header: date + optional X
            HStack(alignment: .firstTextBaseline) {
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer(minLength: 12)
                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            scoreRow(color: primaryColor, label: primaryLabel, score: primaryScore)

            // Legacy single-secondary support
            if memberEntries.isEmpty, let secondaryLabel, let secondaryColor {
                scoreRow(color: secondaryColor, label: secondaryLabel, score: secondaryScore)
            }

            ForEach(memberEntries.indices, id: \.self) { i in
                scoreRow(
                    color: memberEntries[i].color,
                    label: memberEntries[i].label,
                    score: memberEntries[i].score
                )
            }
        }
        .padding(DS.Spacing.sm)
        .frame(minWidth: 160, alignment: .leading)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private func scoreRow(color: Color, label: String, score: Double?) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
            Spacer(minLength: 20)
            Text(score.map { String(format: valueFormat, $0) } ?? "—")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Color.textPrimary)
        }
    }
}
