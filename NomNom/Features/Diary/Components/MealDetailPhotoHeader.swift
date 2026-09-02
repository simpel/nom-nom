import SwiftUI

/// Header carousel or hero photo for MealDetailView.
struct MealDetailPhotoHeader: View {
    let photoPaths: [String]
    let onSelectPhotoIndex: (Int) -> Void

    var body: some View {
        if photoPaths.count > 1 {
            TabView {
                ForEach(Array(photoPaths.enumerated()), id: \.element) { index, path in
                    Button {
                        onSelectPhotoIndex(index)
                    } label: {
                        RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo)
                            .frame(height: 280)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .photoBottomScrim()
            .frame(height: 280)
            .tabViewStyle(.page)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
        } else if let singlePath = photoPaths.first {
            Button {
                onSelectPhotoIndex(0)
            } label: {
                RemoteMealPhoto(path: singlePath, cornerRadius: AppRadius.photo)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        } else {
            RemoteMealPhoto(path: nil, cornerRadius: AppRadius.photo)
                .frame(height: 280)
                .frame(maxWidth: .infinity)
        }
    }
}
