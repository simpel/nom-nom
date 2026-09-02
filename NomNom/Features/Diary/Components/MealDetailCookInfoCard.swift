import SwiftUI

/// Clean key-value details table for a meal: Cook, Date, Dinner Party, Cooking Time, Tags, Chef Notes.
struct MealDetailCookInfoCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    private var dish: Recipe? { store.dish(meal.dishID) }
    private var parties: [Party] { store.parties(forMeal: meal.id) }
    private var cookLabel: (emoji: String, name: String) {
        store.label(for: .account(meal.createdBy))
    }
    private var displayEffort: EffortLevel? {
        meal.effort ?? dish?.effort
    }

    var body: some View {
        SectionCard(title: "Details") {
            VStack(spacing: 12) {
                // Cook Row
                HStack {
                    Text("Cook")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    NavigationLink {
                        PersonDetailView(raterRef: .account(meal.createdBy))
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                                    .frame(width: 24, height: 24)
                                Text(cookLabel.name.prefix(1).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                            Text(meal.createdBy == store.userID ? "You" : cookLabel.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Date Row
                HStack {
                    Text("Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(meal.eatenOn, format: .dateTime.weekday(.wide).day().month(.wide).year())
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }

                // Dinner Party
                if !parties.isEmpty {
                    Divider()
                    HStack {
                        Text("Dinner Party")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(parties.map(\.name).joined(separator: ", "))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }

                // Cooking Time / Effort (if specified)
                if let effort = displayEffort {
                    Divider()
                    HStack {
                        Text("Cooking Time")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        BurnerMeter(effort: effort, showLabel: true)
                    }
                }

                // Tags
                if let tags = dish?.tags, !tags.isEmpty {
                    Divider()
                    HStack(alignment: .top) {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        Spacer()
                        WrappingHStack {
                            ForEach(tags, id: \.self) { tag in
                                Chip(text: tag, systemImage: "tag", tint: DS.Color.textSecondary)
                            }
                        }
                    }
                }

                // Chef Notes
                if !meal.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                    HStack(alignment: .top) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(meal.notes)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
}
