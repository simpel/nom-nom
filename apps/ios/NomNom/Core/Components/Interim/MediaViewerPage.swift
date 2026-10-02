// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI
import UIKit

/// One full-screen page of a MediaViewerSheet: the whole photo fitted to the
/// screen on black, a spinner while a stored photo downloads.
struct MediaViewerPage: View {
    let source: MediaViewerPageSource

    @State private var image: UIImage?
    @State private var didLoad = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Photo")
            } else if !didLoad {
                ProgressView().tint(DS.Color.Stone.stone0)
            } else {
                Image(systemName: "fork.knife")
                    .textStyle(.sansXl, tone: .tertiary)
                    .accessibilityLabel("Photo unavailable")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: source.id) { await load() }
    }

    private func load() async {
        switch source {
        case .data(_, let data):
            image = UIImage(data: data)
        case .remote(let path, let bucket):
            var data = PhotoCache.shared.cached(path)
            if data == nil {
                data = await PhotoCache.shared.data(for: path, bucket: bucket)
            }
            guard !Task.isCancelled else { return }
            image = data.flatMap(UIImage.init(data:))
        }
        didLoad = true
    }
}
