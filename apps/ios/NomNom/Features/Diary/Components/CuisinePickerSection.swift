import SwiftUI

/// Clean interactive row section for selecting cuisines/categories via a dedicated sheet.
struct CuisinePickerSection: View {
    @Binding var selection: String?

    @State private var showingSheet = false

    private var selectedItems: [String] {
        Cuisine.parseMultiple(from: selection)
    }

    var body: some View {
        SectionCard(
            "Kitchen / Cuisine",
            caption: selectedItems.isEmpty ? nil : "\(selectedItems.count) selected"
        ) {
            Button {
                showingSheet = true
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    if selectedItems.isEmpty {
                        Text("Choose kitchen / cuisines…")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                    } else {
                        WrappingHStack(spacing: 8, lineSpacing: 8) {
                            ForEach(selectedItems, id: \.self) { item in
                                HStack(spacing: 6) {
                                    if let preset = Cuisine.matching(from: item) {
                                        Image(preset.assetImageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 18, height: 18)
                                            .clipShape(Circle())
                                    }

                                    Text(Cuisine.matching(from: item)?.displayName ?? item.capitalized)
                                        .font(.subheadline.weight(.medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(DS.Color.accent.opacity(0.12))
                                .foregroundStyle(DS.Color.accentText)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(DS.Color.accent.opacity(0.35), lineWidth: 1)
                                )
                            }
                        }
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                selectedItems.isEmpty
                    ? "Select kitchen or cuisine"
                    : "Cuisines: \(selectedItems.joined(separator: ", ")). Tap to edit."
            )
        }
        .sheet(isPresented: $showingSheet) {
            CuisinePickerSheet(selection: $selection)
        }
    }
}

#Preview {
    NomNomPreview {
        VStack(spacing: 16) {
            CuisinePickerSection(selection: .constant(nil))
            CuisinePickerSection(selection: .constant("italian, mexican"))
        }
        .padding()
    }
}
