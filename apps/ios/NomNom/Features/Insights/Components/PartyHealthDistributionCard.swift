import SwiftUI

struct PartyHealthDistributionCard: View {
    let distribution: [HealthTier: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Dietary Balance")
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)
            
            // Progress Bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(HealthTier.allCases) { tier in
                        if let percentage = distribution[tier], percentage > 0 {
                            Rectangle()
                                .fill(tier.color)
                                .frame(width: max(0, geometry.size.width * CGFloat(percentage)))
                        }
                    }
                }
            }
            .frame(height: 12)
            .clipShape(Capsule())
            
            // Legend
            VStack(spacing: DS.Spacing.sm) {
                ForEach(HealthTier.allCases) { tier in
                    if let percentage = distribution[tier], percentage > 0 {
                        HStack {
                            Circle()
                                .fill(tier.color)
                                .frame(width: 8, height: 8)
                            Text(tier.displayName)
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textPrimary)
                            Spacer()
                            Text("\(Int(percentage * 100))%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                }
            }
            .padding(.top, DS.Spacing.xs)
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.sunken)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}
