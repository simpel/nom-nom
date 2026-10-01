import SwiftUI

/// Horizontal pill selector for choosing which party member's taste trendline
/// to compare against the overall party average.
struct PartyMemberTrendPicker: View {
    let memberSeries: [MemberTrendSeries]
    let selectedMemberID: RaterRef?
    let onSelect: (RaterRef) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(Array(memberSeries.enumerated()), id: \.element.id) { index, series in
                    let isSelected = (selectedMemberID == series.id)
                    let memberColor = DS.Color.Chart.series[index % DS.Color.Chart.series.count]

                    Button {
                        onSelect(series.id)
                    } label: {
                        Text(series.name)
                            .font(.caption.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xxs)
                            .background(isSelected ? memberColor.opacity(0.16) : DS.Color.panel)
                            .foregroundStyle(isSelected ? memberColor : DS.Color.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(isSelected ? memberColor : DS.Color.line.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
        }
    }
}
