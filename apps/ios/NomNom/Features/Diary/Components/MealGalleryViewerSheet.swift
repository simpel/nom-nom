import SwiftUI

/// Full-screen swipeable photo gallery viewer sheet.
struct MealGalleryViewerSheet: View {
    let paths: [String]
    var initialIndex: Int = 0
    var bucket: String = SupabaseConfig.photoBucket
    var titlePrefix: String = "Photo"

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(Array(paths.enumerated()), id: \.element) { index, path in
                    RemoteMealPhoto(path: path, cornerRadius: 0, bucket: bucket)
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: paths.count > 1 ? .always : .never))
            .navigationTitle(paths.count > 1 ? "\(titlePrefix) \(selection + 1) of \(paths.count)" : titlePrefix)
            .mediaViewerStyle()
            .onAppear {
                selection = initialIndex
            }
        }
    }
}
