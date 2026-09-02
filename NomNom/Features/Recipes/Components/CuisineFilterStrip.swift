import SwiftUI

/// Horizontal scrollable pill strip for quick kitchen / cuisine filtering.
struct CuisineFilterStrip: View {
    @Binding var selectedCuisine: String?
    var availableCuisines: [String] = Cuisine.allCases.map(\.rawValue)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedCuisine = nil
                } label: {
                    Text("All Cuisines")
                        .font(.subheadline.weight(selectedCuisine == nil ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            selectedCuisine == nil
                                ? Color.primary
                                : Color(uiColor: .secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(
                            selectedCuisine == nil
                                ? Color(uiColor: .systemBackground)
                                : Color.primary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(availableCuisines, id: \.self) { raw in
                    let isSelected = selectedCuisine?.lowercased() == raw.lowercased()
                    let displayName = Cuisine.formatDisplayName(raw) ?? raw

                    Button {
                        if isSelected {
                            selectedCuisine = nil
                        } else {
                            selectedCuisine = raw
                        }
                    } label: {
                        Text(displayName)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                isSelected
                                    ? Color.primary
                                    : Color(uiColor: .secondarySystemGroupedBackground)
                            )
                            .foregroundStyle(
                                isSelected
                                    ? Color(uiColor: .systemBackground)
                                    : Color.primary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}
