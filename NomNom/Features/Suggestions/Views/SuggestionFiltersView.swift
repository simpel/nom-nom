import SwiftUI

/// The filter sheet. Everything here is a knob on the same scoring function, so
/// changes take effect instantly against the list underneath.
struct SuggestionFiltersView: View {
    @Binding var filters: SuggestionFilters
    /// Everyone who can hold an opinion — household members and account holders.
    let roster: [(ref: RaterRef, emoji: String, name: String)]
    let tags: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var originalFilters: SuggestionFilters?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    SectionCard("Ranking") {
                        VStack(spacing: 12) {
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

                                if mode != SuggestionMode.allCases.last {
                                    Divider()
                                }
                            }
                        }
                    }

                    if !roster.isEmpty {
                        SectionCard("Must be liked by") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(roster, id: \.ref) { person in
                                    Toggle(isOn: Binding(
                                        get: { filters.requiredRaters.contains(person.ref) },
                                        set: { on in
                                            if on { filters.requiredRaters.insert(person.ref) }
                                            else { filters.requiredRaters.remove(person.ref) }
                                        }
                                    )) {
                                        Text(person.name)
                                    }

                                    if person.ref != roster.last?.ref {
                                        Divider()
                                    }
                                }

                                Text("Keeps only dishes where this person's recent verdicts average out to a yes.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }

                    SectionCard("Rotation") {
                        VStack(spacing: 12) {
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

                            Divider()

                            Toggle("Hide dishes somebody disliked", isOn: $filters.hideDisliked)

                            Divider()

                            Toggle("Include dishes we've never rated", isOn: $filters.includeUntried)
                        }
                    }

                    if !tags.isEmpty {
                        SectionCard("Tags") {
                            VStack(spacing: 10) {
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

                                    if tag != tags.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    SectionCard {
                        AppButton(
                            "Reset to defaults",
                            variant: .neutral,
                            style: .ghost,
                            size: .md,
                            isFullWidth: true,
                            disabled: filters.isDefault
                        ) {
                            filters = SuggestionFilters(mode: filters.mode)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .screenTitle("Filters", displayMode: .inline)
            .sheetCommitToolbar(
                onCancel: {
                    if let original = originalFilters {
                        filters = original
                    }
                    dismiss()
                },
                onSave: {
                    dismiss()
                }
            )
            .onAppear {
                if originalFilters == nil {
                    originalFilters = filters
                }
            }
        }
    }
}
