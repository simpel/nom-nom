import SwiftUI

/// Section for selecting or customizing a recipe's kitchen / cuisine.
struct CuisinePickerSection: View {
    @Binding var selection: String?

    @State private var showingCustomField = false
    @State private var customText = ""

    private var selectedCuisine: Cuisine? {
        guard let selection else { return nil }
        return Cuisine.matching(from: selection)
    }

    private var isCustomSelected: Bool {
        guard let selection, !selection.isEmpty else { return false }
        return selectedCuisine == nil
    }

    var body: some View {
        SectionCard("Kitchen / Cuisine") {
            VStack(alignment: .leading, spacing: 12) {
                WrappingHStack(spacing: 8, lineSpacing: 8) {
                    ForEach(Cuisine.allCases) { cuisine in
                        let isSelected = selection?.lowercased() == cuisine.rawValue.lowercased()
                        Button {
                            if isSelected {
                                selection = nil
                            } else {
                                selection = cuisine.rawValue
                                showingCustomField = false
                            }
                        } label: {
                            Text(cuisine.displayName)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected
                                        ? Color.accentColor.opacity(0.15)
                                        : Color(uiColor: .tertiarySystemFill)
                                )
                                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            isSelected ? Color.accentColor : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showingCustomField.toggle()
                        if showingCustomField && selection != nil && selectedCuisine != nil {
                            selection = nil
                        }
                    } label: {
                        Text(isCustomSelected ? (selection ?? "Custom") : "Other…")
                            .font(.subheadline.weight(isCustomSelected ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isCustomSelected
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(uiColor: .tertiarySystemFill)
                            )
                            .foregroundStyle(isCustomSelected ? Color.accentColor : Color.secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isCustomSelected ? Color.accentColor : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                if showingCustomField || isCustomSelected {
                    TextField("Enter custom kitchen (e.g. Ethiopian, Lebanese)", text: $customText)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: customText) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            selection = trimmed.isEmpty ? nil : trimmed
                        }
                        .onAppear {
                            if isCustomSelected, let current = selection {
                                customText = current
                            }
                        }
                }
            }
        }
    }
}
