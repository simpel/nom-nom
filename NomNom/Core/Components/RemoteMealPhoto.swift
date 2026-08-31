import SwiftUI

/// A meal photo stored in private cloud storage, downloaded and cached via PhotoCache.
struct RemoteMealPhoto: View {
    let path: String?
    var cornerRadius: CGFloat = 12

    @State private var data: Data?
    @State private var isLoading = false

    var body: some View {
        MealPhoto(data: data, cornerRadius: cornerRadius)
            .overlay {
                if isLoading, data == nil {
                    ProgressView().controlSize(.small)
                }
            }
            .task(id: path) { await load() }
    }

    private func load() async {
        guard let path else {
            data = nil
            return
        }
        if let hit = PhotoCache.shared.cached(path) {
            data = hit
            return
        }
        isLoading = true
        let loaded = await PhotoCache.shared.data(for: path)
        // Guard against row recycling while request was in-flight
        guard self.path == path else { return }
        data = loaded
        isLoading = false
    }
}
