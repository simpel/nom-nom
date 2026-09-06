import SwiftUI

/// Why is this recipe being suggested? Shows the parts of the score and the history
/// behind them, plus rename so the naming can be cleaned up after the fact.
struct RecipeInsightView: View {
    let suggestion: Suggestion

    @Environment(FoodStore.self) private var store

    @State private var showEditor = false
    @State private var renaming = false
    @State private var newName = ""

    private var recipe: Recipe? { store.recipe(suggestion.dish.id) }
    private var history: [Meal] { store.servings(of: suggestion.dish.id) }

    var body: some View {
        Group {
            if let recipe {
                content(for: recipe)
            } else {
                ContentUnavailableView("Recipe is gone",
                                       systemImage: "questionmark.folder",
                                       description: Text("It was deleted."))
            }
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            MealEditorView(mealID: nil, prefilledDishID: suggestion.dish.id)
        }
        .alert("Rename recipe", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard let recipe else { return }
                let trimmed = newName.trimmedName
                guard !trimmed.isEmpty else { return }
                Task { await store.rename(recipe: recipe, to: trimmed) }
            }
        }
        }

    @ViewBuilder
    private func content(for recipe: Recipe) -> some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 14) {
                            RemoteMealPhoto(path: suggestion.photoPath, cornerRadius: AppRadius.photo)
                                .frame(width: 90, height: 90)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(recipe.name)
                                    .font(AppTypography.displayM)
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text(suggestion.timesServed == 0
                                     ? "Never cooked"
                                     : "Cooked \(suggestion.timesServed) time\(suggestion.timesServed == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(DS.Color.textSecondary)
                                if let gap = suggestion.typicalGapDays {
                                    Text("Roughly every \(Int(gap.rounded())) days")
                                        .font(.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                            }
                        }

                        AppButton(
                            "Cook this tonight",
                            systemImage: "flame.fill",
                            variant: .primary,
                            style: .normal,
                            size: .xl,
                            isFullWidth: true
                        ) {
                            showEditor = true
                        }
                    }
                }

                SectionCard("How it scores") {
                    VStack(spacing: 12) {
                        MeterRow(title: "Liked",
                                 value: suggestion.likeScore,
                                 caption: suggestion.likeScore == nil ? "No verdicts yet" : nil,
                                 tint: Reaction.great.text)
                        Divider()
                        MeterRow(title: "Due for a repeat",
                                 value: suggestion.readiness,
                                 caption: readinessCaption,
                                 tint: DS.Color.accent)
                        Divider()
                        MeterRow(title: "How sure we are",
                                 value: suggestion.confidence,
                                 caption: suggestion.confidence < 0.4 ? "Needs a few more data points" : nil,
                                 tint: DS.Color.lineStrong)
                    }
                }

                if !suggestion.verdicts.isEmpty {
                    SectionCard("Per person") {
                        VStack(spacing: 8) {
                            ForEach(suggestion.verdicts) { verdict in
                                NavigationLink {
                                    PersonDetailView(raterRef: verdict.ref)
                                } label: {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.accentColor.opacity(0.12))
                                                .frame(width: 24, height: 24)
                                            Text(verdict.name.prefix(1).uppercased())
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(Color.accentColor)
                                        }

                                        Text(verdict.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        if let reaction = verdict.reaction {
                                            HStack(spacing: 4) {
                                                Image(systemName: reaction.systemImage)
                                                    .font(.caption2)
                                                Text(reaction.label)
                                                    .font(.subheadline.weight(.medium))
                                            }
                                            .foregroundStyle(reaction.text)
                                            .accessibilityLabel(reaction.name)
                                            Text("(\(verdict.sampleCount))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("No verdict")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)

                                if verdict.id != suggestion.verdicts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                if !suggestion.reasons.isEmpty {
                    SectionCard("In short") {
                        WrappingHStack {
                            ForEach(suggestion.reasons, id: \.self) { reason in
                                Chip(text: reason, tint: .accentColor)
                            }
                        }
                    }
                }

                SectionCard {
                    NavigationLink {
                        RecipeDetailView(recipeID: recipe.id)
                    } label: {
                        HStack {
                            Label("View Full Recipe & Cook History", systemImage: "book.pages")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if recipe.hasInstructions {
                    RecipeInstructionsCard(recipe: recipe)
                }

                if !history.isEmpty {
                    SectionCard("History") {
                        VStack(spacing: 8) {
                            ForEach(history) { meal in
                                NavigationLink {
                                    MealDetailView(mealID: meal.id)
                                } label: {
                                    HStack(spacing: 10) {
                                        RemoteMealPhoto(path: meal.photoPath, cornerRadius: AppRadius.photo)
                                            .frame(width: 40, height: 40)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            let parties = store.parties(forMeal: meal.id)
                                            if !parties.isEmpty {
                                                Text(parties.map(\.name).joined(separator: ", "))
                                                    .font(.caption2)
                                                    .foregroundStyle(DS.Color.accentText)
                                            }
                                        }
                                        Spacer()
                                        let ratings = store.ratings(forMeal: meal.id)
                                        if !ratings.isEmpty {
                                            HStack(spacing: 4) {
                                                ForEach(ratings) { r in
                                                    HStack(spacing: 2) {
                                                        Image(systemName: r.reaction.systemImage)
                                                            .font(.caption2)
                                                        Text(r.reaction.numberLabel)
                                                            .font(.caption2.weight(.bold))
                                                    }
                                                    .foregroundStyle(r.reaction.text)
                                                    .accessibilityLabel(r.reaction.name)
                                                }
                                            }
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)

                                if meal.id != history.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                housekeepingSection(for: recipe)
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func housekeepingSection(for recipe: Recipe) -> some View {
        SectionCard("Housekeeping") {
            VStack(alignment: .leading, spacing: 10) {
                AppButton("Rename recipe", variant: .neutral, style: .outlined, size: .sm) {
                    newName = recipe.name
                    renaming = true
                }
            }
        }
        .background(DS.Color.bg)
    }

    private var readinessCaption: String? {
        guard let days = suggestion.daysSinceServed else { return "Never cooked, so fully due" }
        if days == 0 { return "Cooked today" }
        return "Last cooked \(days) day\(days == 1 ? "" : "s") ago"
    }
}

typealias DishInsightView = RecipeInsightView
