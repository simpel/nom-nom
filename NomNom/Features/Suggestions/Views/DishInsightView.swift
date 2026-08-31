import SwiftUI

/// Why is this dish being suggested? Shows the parts of the score and the history
/// behind them, plus rename/merge so the naming can be cleaned up after the fact.
struct DishInsightView: View {
    let suggestion: Suggestion

    @Environment(FoodStore.self) private var store

    @State private var showEditor = false
    @State private var renaming = false
    @State private var newName = ""
    @State private var mergeTarget: Dish?

    /// Read back from the store rather than using the snapshot inside `suggestion`,
    /// so a rename done on this screen is reflected here immediately.
    private var dish: Dish? { store.dish(suggestion.dish.id) }

    private var history: [Meal] { store.servings(of: suggestion.dish.id) }

    var body: some View {
        Group {
            if let dish {
                content(for: dish)
            } else {
                ContentUnavailableView("Dish is gone",
                                       systemImage: "questionmark.folder",
                                       description: Text("It was deleted or merged into another dish."))
            }
        }
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            MealEditorView(mealID: nil, prefilledDishID: suggestion.dish.id)
        }
        .alert("Rename dish", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard let dish else { return }
                let trimmed = newName.trimmedName
                guard !trimmed.isEmpty else { return }
                Task { await store.rename(dish: dish, to: trimmed) }
            }
        }
        // A confirmation dialog rather than a second `.alert`: two alerts on one
        // view compete for the same presentation slot.
        .confirmationDialog("Merge into “\(mergeTarget?.name ?? "")”?",
                            isPresented: Binding(get: { mergeTarget != nil },
                                                 set: { if !$0 { mergeTarget = nil } }),
                            titleVisibility: .visible) {
            Button("Merge \(history.count) meal\(history.count == 1 ? "" : "s")", role: .destructive) {
                if let dish, let mergeTarget {
                    Task { await store.merge(dish: dish, into: mergeTarget) }
                }
                mergeTarget = nil
            }
            Button("Cancel", role: .cancel) { mergeTarget = nil }
        } message: {
            Text("“\(dish?.name ?? "")” will be removed and its history kept under the other name.")
        }
    }

    @ViewBuilder
    private func content(for dish: Dish) -> some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    RemoteMealPhoto(path: suggestion.photoPath, cornerRadius: 12)
                        .frame(width: 90, height: 90)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dish.name)
                            .font(.title3.weight(.semibold))
                        Text(suggestion.timesServed == 0
                             ? "Never cooked"
                             : "Cooked \(suggestion.timesServed) time\(suggestion.timesServed == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let gap = suggestion.typicalGapDays {
                            Text("Roughly every \(Int(gap.rounded())) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                Button {
                    showEditor = true
                } label: {
                    Label("Cook this tonight", systemImage: "flame.fill")
                }
            }

            Section("How it scores") {
                MeterRow(title: "Liked",
                         value: suggestion.likeScore,
                         caption: suggestion.likeScore == nil ? "No verdicts yet" : nil,
                         tint: .green)
                MeterRow(title: "Due for a repeat",
                         value: suggestion.readiness,
                         caption: readinessCaption,
                         tint: .blue)
                MeterRow(title: "How sure we are",
                         value: suggestion.confidence,
                         caption: suggestion.confidence < 0.4 ? "Needs a few more data points" : nil,
                         tint: .purple)
            }

            if !suggestion.verdicts.isEmpty {
                Section("Per person") {
                    ForEach(suggestion.verdicts) { verdict in
                        HStack {
                            Text(verdict.emoji)
                            Text(verdict.name)
                            Spacer()
                            if let reaction = verdict.reaction {
                                Text("\(reaction.emoji) \(reaction.shortLabel)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(reaction.tint)
                                Text("(\(verdict.sampleCount))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No verdict")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !suggestion.reasons.isEmpty {
                Section("In short") {
                    WrappingHStack {
                        ForEach(suggestion.reasons, id: \.self) { reason in
                            Chip(text: reason, tint: .accentColor)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if !history.isEmpty {
                Section("History") {
                    ForEach(history) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            HStack(spacing: 10) {
                                RemoteMealPhoto(path: meal.photoPath, cornerRadius: 8)
                                    .frame(width: 40, height: 40)
                                Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                                Spacer()
                                Text(store.ratings(forMeal: meal.id).map(\.reaction.emoji).joined())
                            }
                        }
                    }
                }
            }

            Section {
                Button("Rename dish") {
                    newName = dish.name
                    renaming = true
                }
                if !mergeCandidates(excluding: dish).isEmpty {
                    Menu("Merge into another dish") {
                        ForEach(mergeCandidates(excluding: dish)) { candidate in
                            Button(candidate.name) {
                                mergeTarget = candidate
                            }
                        }
                    }
                }
            } header: {
                Text("Housekeeping")
            } footer: {
                Text("Merging moves every logged meal onto the other dish and keeps its name.")
            }
        }
    }

    private func mergeCandidates(excluding dish: Dish) -> [Dish] {
        store.myDishes
            .filter { $0.id != dish.id }
            .sorted { Fuzzy.similarity($0.normalizedName, dish.normalizedName) > Fuzzy.similarity($1.normalizedName, dish.normalizedName) }
            .prefix(8)
            .map { $0 }
    }

    private var readinessCaption: String? {
        guard let days = suggestion.daysSinceServed else { return "Never cooked, so fully due" }
        if days == 0 { return "Cooked today" }
        return "Last cooked \(days) day\(days == 1 ? "" : "s") ago"
    }
}

/// Horizontal 0...1 bar used for the score breakdown.
struct MeterRow: View {
    let title: String
    let value: Double?
    let caption: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value == nil ? "–" : "\(Int(((value ?? 0) * 100).rounded()))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(0, min(1, value ?? 0)) * geometry.size.width)
                }
            }
            .frame(height: 7)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
