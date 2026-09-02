import SwiftUI
import Charts

/// Score point representing a rated meal occasion for a specific dinner party.
struct RecipeScorePoint: Identifiable {
    let id: UUID
    let date: Date
    let score: Double
    let partyName: String
    let meal: Meal
}

/// Interactive, horizontally scrollable line graph showing meal scores over time with multi-party lines.
struct RecipeScoreHistorySection: View {
    let recipe: Recipe
    let history: [Meal]
    @Binding var selectedPartyID: UUID?
    let onSelectMeal: (Meal) -> Void

    @Environment(FoodStore.self) private var store
    @State private var scrollPosition: Date = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    @State private var tappedPointID: UUID?

    private var availableParties: [Party] {
        let partyIDs = Set(history.flatMap { store.parties(forMeal: $0.id).map(\.id) })
        return store.myParties.filter { partyIDs.contains($0.id) }
    }

    private var points: [RecipeScorePoint] {
        var result: [RecipeScorePoint] = []
        for meal in history.sorted(by: { $0.eatenOn < $1.eatenOn }) {
            let ratings = store.ratings(forMeal: meal.id)
            guard !ratings.isEmpty else { continue }
            let avg = (ratings.map(\.reaction.score).reduce(0, +) / Double(ratings.count)) * 100.0
            let mealParties = store.parties(forMeal: meal.id)

            if let selectedPartyID {
                if mealParties.contains(where: { $0.id == selectedPartyID }) {
                    let name = store.party(selectedPartyID)?.name ?? "Dinner Party"
                    result.append(RecipeScorePoint(id: UUID(), date: meal.eatenOn, score: avg, partyName: name, meal: meal))
                }
            } else {
                if mealParties.isEmpty {
                    result.append(RecipeScorePoint(id: UUID(), date: meal.eatenOn, score: avg, partyName: "Household", meal: meal))
                } else {
                    for party in mealParties {
                        result.append(RecipeScorePoint(id: UUID(), date: meal.eatenOn, score: avg, partyName: party.name, meal: meal))
                    }
                }
            }
        }
        return result
    }

    var body: some View {
        SectionCard(headerTitle) {
            VStack(alignment: .leading, spacing: 10) {
                if points.isEmpty {
                    Text("No score history yet")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 24)
                } else {
                    chartView
                        .frame(height: 180)
                        .padding(.vertical, 10)
                }
            }
            .contentShape(Rectangle())
            .contextMenu { dinnerPartyMenuContent }
        }
    }

    private var headerTitle: String {
        if let selectedPartyID, let party = store.party(selectedPartyID) {
            return "Score History — \(party.name)"
        }
        return "Score History"
    }

    // MARK: - Chart View

    private var chartView: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Time", point.date), y: .value("Average Score", point.score))
                    .foregroundStyle(by: .value("Party", point.partyName))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)

                PointMark(x: .value("Time", point.date), y: .value("Average Score", point.score))
                    .foregroundStyle(by: .value("Party", point.partyName))
                    .symbolSize(tappedPointID == point.id ? 140 : 85)
            }
        }
        .chartLegend(.hidden)
        .chartYScale(domain: -12...112)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intVal = value.as(Int.self), (0...100).contains(intVal) {
                        Text("\(intVal)%").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 30 * 24 * 3600)
        .chartScrollPosition(x: $scrollPosition)
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { handleChartTap(at: $0.location, proxy: proxy, geometry: geo) })
            }
        }
    }

    // MARK: - Interactive Tap

    private func handleChartTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let origin = geometry[plotFrame].origin
        let relX = location.x - origin.x
        let relY = location.y - origin.y

        var closest: RecipeScorePoint?
        var minDist: CGFloat = 44.0

        for pt in points {
            if let px = proxy.position(forX: pt.date), let py = proxy.position(forY: pt.score) {
                let dist = hypot(px - relX, py - relY)
                if dist < minDist {
                    minDist = dist
                    closest = pt
                }
            }
        }

        if let closest {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { tappedPointID = closest.id }
            onSelectMeal(closest.meal)
        }
    }

    // MARK: - Menu Button & Content

    private var partyFilterMenu: some View {
        Menu {
            dinnerPartyMenuContent
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var dinnerPartyMenuContent: some View {
        Section("Filter by Dinner Party") {
            Button { selectedPartyID = nil } label: {
                Label("All Dinner Parties", systemImage: selectedPartyID == nil ? "checkmark" : "")
            }
            ForEach(availableParties) { party in
                Button { selectedPartyID = party.id } label: {
                    Label(party.name, systemImage: selectedPartyID == party.id ? "checkmark" : "")
                }
            }
        }
    }
}
