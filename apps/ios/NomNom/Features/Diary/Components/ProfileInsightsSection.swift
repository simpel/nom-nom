import SwiftUI

/// Personal taste profile + health trend for one rater, shown on `PersonDetailView`.
/// Works identically for "my profile" and viewing someone else's — both just a `RaterRef`.
struct ProfileInsightsSection: View {
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store
    @State private var flavorProfile: [FlavorProfileEntry] = []

    private var tasteProfile: RaterTasteProfile? {
        store.tasteProfile(for: raterRef)
    }

    private var healthInsights: PartyHealthInsights? {
        store.healthInsights(for: raterRef)
    }

    var body: some View {
        if tasteProfile != nil || healthInsights != nil {
            VStack(alignment: .leading, spacing: DS.Spacing.section) {
                Text("Insights")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                if tasteProfile != nil || healthInsights != nil {
                    ProGate {
                        VStack(alignment: .leading, spacing: DS.Spacing.section) {
                            if let tasteProfile {
                                tasteProfileCard(tasteProfile)
                            }

                            if let healthInsights {
                                healthTrendChart(healthInsights)

                                if let macros = healthInsights.averageMacros {
                                    AverageMacrosCard(macros: macros)
                                }
                            }

                            FlavorProfileCard(entries: flavorProfile)
                        }
                    }
                }
            }
            .task(id: raterRef) {
                flavorProfile = (try? await store.fetchFlavorProfile(for: raterRef)) ?? []
            }
        }
    }

    private func healthTrendChart(_ healthInsights: PartyHealthInsights) -> some View {
        let trend: [(date: Date, averageScore: Double)] = healthInsights.healthScoreTrend.map {
            (date: $0.date, averageScore: $0.averageHealthScore)
        }
        return InsightsTrendChart(trendData: trend, domain: 1...100, valueFormat: "%.0f")
    }

    private func tasteProfileCard(_ profile: RaterTasteProfile) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Taste Profile")
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Average Score Given")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(Int((profile.averageScoreGiven * 100).rounded()))")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Ratings Given")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(profile.totalRatingsGiven)")
                        .font(.headline)
                }
            }

            if !profile.ratingDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Reaction.allCases.sorted { $0.rawValue > $1.rawValue }) { reaction in
                        let count = profile.ratingDistribution[reaction] ?? 0
                        if count > 0 {
                            HStack(spacing: DS.Spacing.sm) {
                                Text(reaction.shortLabel)
                                    .font(.caption)
                                    .foregroundStyle(reaction.text)
                                    .frame(width: 60, alignment: .leading)

                                GeometryReader { geo in
                                    Capsule()
                                        .fill(reaction.fill.opacity(0.6))
                                        .frame(
                                            width: geo.size.width * CGFloat(count) / CGFloat(profile.totalRatingsGiven),
                                            height: 8
                                        )
                                }
                                .frame(height: 8)

                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .frame(width: 20, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(.top, DS.Spacing.xs)
            }

            if !profile.topCuisines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Cuisines")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(.top, DS.Spacing.xs)

                    Text(profile.topCuisines.map(\.cuisine).joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textPrimary)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.sunken)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}
