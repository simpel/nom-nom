import SwiftUI

struct MealDetailView: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store
    @State private var showEditor = false

    private var meal: Meal? { store.meal(mealID) }

    var body: some View {
        Group {
            if let meal {
                content(for: meal)
            } else {
                // The meal was deleted — from here, or on another device.
                ContentUnavailableView("Meal is gone",
                                       systemImage: "questionmark.folder",
                                       description: Text("It looks like this meal was deleted."))
            }
        } 
        .navigationTitle(meal.map { store.dishName(forMeal: $0) } ?? "Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let meal, meal.createdBy == store.userID {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEditor = true }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            MealEditorView(mealID: mealID)
        }
    }

    @ViewBuilder
    private func content(for meal: Meal) -> some View {
        let dish = store.dish(meal.dishID)
        let verdicts = store.verdictEntries(forMeal: meal.id)
        let invites = store.invites(forMeal: meal.id)
        let history = store.servings(of: meal.dishID).filter { $0.id != meal.id }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RemoteMealPhoto(path: meal.photoPath, cornerRadius: 18)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text(store.dishName(forMeal: meal))
                        .font(.title2.bold())
                    Text(meal.eatenOn, format: .dateTime.weekday(.wide).day().month(.wide).year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if meal.createdBy != store.userID {
                        let cook = store.label(for: .account(meal.createdBy))
                        Text("Cooked by \(cook.emoji) \(cook.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if meal.createdBy != store.userID {
                    MyVerdictCard(mealID: meal.id)
                }

                if !verdicts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verdict").font(.headline)
                        ForEach(Array(verdicts.enumerated()), id: \.offset) { entry in
                            HStack {
                                Text(entry.element.emoji)
                                Text(entry.element.name)
                                Spacer()
                                if let reaction = entry.element.reaction {
                                    Text(reaction.emoji)
                                    Text(reaction.shortLabel)
                                        .foregroundStyle(reaction.tint)
                                        .font(.subheadline.weight(.medium))
                                }
                            }
                        }
                    }
                }

                if !meal.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(.headline)
                        Text(meal.notes)
                            .foregroundStyle(.secondary)
                    }
                }

                if let tags = dish?.tags, !tags.isEmpty {
                    WrappingHStack {
                        ForEach(tags, id: \.self) { tag in
                            Chip(text: tag, systemImage: "tag", tint: .indigo)
                        }
                    }
                }

                if !invites.isEmpty, meal.createdBy == store.userID {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Asked to rate this").font(.headline)
                        ForEach(invites) { invite in
                            InviteRow(invite: invite)
                        }
                    }
                }

                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("We've also had this")
                            .font(.headline)
                        ForEach(history.prefix(8)) { past in
                            HStack(spacing: 10) {
                                RemoteMealPhoto(path: past.photoPath, cornerRadius: 8)
                                    .frame(width: 40, height: 40)
                                Text(past.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                                    .font(.subheadline)
                                Spacer()
                                let reactions = store.ratings(forMeal: past.id).map(\.reaction.emoji).joined()
                                if !reactions.isEmpty {
                                    Text(reactions)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

/// Where I record my own verdict on somebody else's meal.
struct MyVerdictCard: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false

    private var mine: Reaction? { store.myRating(forMeal: mealID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(mine == nil ? "How was it?" : "Your verdict")
                    .font(.headline)
                Spacer()
                if isSaving { ProgressView().controlSize(.small) }
            }

            HStack(spacing: 8) {
                ForEach(Reaction.allCases) { reaction in
                    Button {
                        submit(reaction)
                    } label: {
                        VStack(spacing: 2) {
                            Text(reaction.emoji).font(.title2)
                            Text(reaction.shortLabel).font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(mine == reaction ? reaction.tint.opacity(0.2) : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(mine == reaction ? reaction.tint : Color.secondary.opacity(0.25),
                                              lineWidth: mine == reaction ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }
            }

            Text(mine == nil
                 ? "Whoever cooked it gets told what you thought."
                 : "Tap another to change your mind.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.accentColor.opacity(0.08))
        }
    }

    private func submit(_ reaction: Reaction) {
        isSaving = true
        Task {
            await store.rate(mealID: mealID, as: reaction)
            isSaving = false
        }
    }
}

/// One invited person, and how far the invite got.
struct InviteRow: View {
    let invite: MealInvite

    @Environment(FoodStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            if let id = invite.inviteeID {
                let who = store.label(for: .account(id))
                Text(who.emoji)
                Text(who.name)
            } else {
                Text("✉️")
                Text(invite.inviteeEmail ?? "Someone")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            statusChip
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var statusChip: some View {
        if invite.isUnclaimed {
            Chip(text: "No account yet", systemImage: "clock", tint: .secondary)
        } else if store.ratings(forMeal: invite.mealID).contains(where: { $0.raterID == invite.inviteeID }) {
            Chip(text: "Rated", systemImage: "checkmark.circle.fill", tint: .green)
        } else {
            switch invite.status {
            case .declined:
                Chip(text: "Declined", systemImage: "xmark.circle", tint: .red)
            case .accepted, .pending:
                Chip(text: "Waiting", systemImage: "hourglass", tint: .orange)
            }
        }
    }
}
