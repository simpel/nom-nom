import UIKit

/// Utilities for image preprocessing, compression, and downscaling.
enum PhotoTools {
    /// Downscale + JPEG-encode so photos don't bloat local storage or network payload.
    static func prepare(_ image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.82) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    static func prepare(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return prepare(image)
    }
}
