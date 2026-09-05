import SwiftUI

/// Clean key-value details table for a meal: Recipe (tappable row), Chef, Cooking Time, Tags, Chef Notes.
struct MealDetailCookInfoCard: View {
    let meal: Meal
    var onOpenRecipe: (() -> Void)? = nil
    var onOpenParty: ((Party) -> Void)? = nil

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
                // Recipe Row (no button styling, still tappable table row)
                if let onOpenRecipe {
                    Button(action: onOpenRecipe) {
                        HStack {
                            Text("Recipe")
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Text(store.recipeName(forMeal: meal))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(DS.Color.line.opacity(0.3))
                }

                // Chef Row
                HStack {
                    Text("Chef")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                    Spacer()
                    NavigationLink {
                        PersonDetailView(raterRef: .account(meal.createdBy))
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(DS.Color.accentSoft)
                                    .frame(width: 24, height: 24)
                                Text(cookLabel.name.prefix(1).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DS.Color.accentText)
                            }
                            Text(meal.createdBy == store.userID ? "You" : cookLabel.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(DS.Color.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Dinner Party Row
                if let party = parties.first {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    HStack {
                        Text("Dinner Party")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        if let onOpenParty {
                            Button {
                                onOpenParty(party)
                            } label: {
                                HStack(spacing: 6) {
                                    PartyAvatar(party: party, size: 20)
                                    Text(parties.map(\.name).joined(separator: ", "))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DS.Color.accentText)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(DS.Color.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            HStack(spacing: 6) {
                                PartyAvatar(party: party, size: 20)
                                Text(parties.map(\.name).joined(separator: ", "))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                        }
                    }
                }

                // Cooking Time / Effort (if specified)
                if let effort = displayEffort {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    HStack {
                        Text("Cooking Time")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        BurnerMeter(effort: effort, showLabel: true)
                    }
                }

                // Tags
                if let tags = dish?.tags, !tags.isEmpty {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    LabeledWrappingRow(label: "Tags", alignment: .trailing) {
                        ForEach(tags, id: \.self) { tag in
                            Chip(text: tag, tint: DS.Color.textSecondary)
                        }
                    }
                }

                // Chef Notes
                if !meal.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    HStack(alignment: .top) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        Text(meal.notes)
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
}
