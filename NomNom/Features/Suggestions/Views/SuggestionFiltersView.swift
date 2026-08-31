import SwiftUI

/// The filter sheet. Everything here is a knob on the same scoring function, so
/// changes take effect instantly against the list underneath.
struct SuggestionFiltersView: View {
    @Binding var filters: SuggestionFilters
    /// Everyone who can hold an opinion — household members and account holders.
    let roster: [(ref: RaterRef, emoji: String, name: String)]
    let tags: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(SuggestionMode.allCases) { mode in
                        Button {
                            filters.mode = mode
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: mode.symbol)
                                    .frame(width: 22)
                                    .foregroundStyle(filters.mode == mode ? Color.accentColor : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.title)
                                        .foregroundStyle(.primary)
                                    Text(mode.explanation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if filters.mode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Ranking")
                }

                if !roster.isEmpty {
                    Section {
                        ForEach(roster, id: \.ref) { person in
                            Toggle(isOn: Binding(
                                get: { filters.requiredRaters.contains(person.ref) },
                                set: { on in
                                    if on { filters.requiredRaters.insert(person.ref) }
                                    else { filters.requiredRaters.remove(person.ref) }
                                }
                            )) {
                                HStack {
                                    Text(person.emoji)
                                    Text(person.name)
                                }
                            }
                        }
                    } header: {
                        Text("Must be liked by")
                    } footer: {
                        Text("Keeps only dishes where this person's recent verdicts average out to a yes.")
                    }
                }

                Section {
                    Stepper(value: $filters.minDaysSinceServed, in: 0...90, step: filters.minDaysSinceServed < 14 ? 1 : 7) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Not eaten for at least")
                            Text(filters.minDaysSinceServed == 0
                                 ? "No limit"
                                 : "\(filters.minDaysSinceServed) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("Hide dishes somebody disliked", isOn: $filters.hideDisliked)
                    Toggle("Include dishes we've never rated", isOn: $filters.includeUntried)
                } header: {
                    Text("Rotation")
                }

                if !tags.isEmpty {
                    Section("Tags") {
                        ForEach(tags, id: \.self) { tag in
                            Toggle(isOn: Binding(
                                get: { filters.requiredTags.contains(tag) },
                                set: { on in
                                    if on { filters.requiredTags.insert(tag) }
                                    else { filters.requiredTags.remove(tag) }
                                }
                            )) {
                                Text(tag)
                            }
                        }
                    }
                }

                Section {
                    Button("Reset to defaults") {
                        filters = SuggestionFilters(mode: filters.mode)
                    }
                    .disabled(filters.isDefault)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
