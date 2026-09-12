import SwiftUI

/// A reusable vertical list component that mimics iOS native lists.
/// Automatically handles iteration, unique row IDs, and places a standard `Divider` between rows.
struct AppList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    var dividerPadding: CGFloat = 16
    @ViewBuilder let rowContent: (Data.Element) -> Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, element in
                rowContent(element)

                if index < data.count - 1 {
                    Divider()
                        .overlay(DS.Color.line.opacity(0.3))
                        .padding(.leading, dividerPadding)
                }
            }
        }
    }
}
