import SwiftUI
import UIKit

/// Wraps `UIImagePickerController` to capture camera photos directly in-app.
/// With `onLibrary`, a library button floats over the native controls (top trailing);
/// tapping it dismisses the camera and calls `onLibrary` so the caller can open Photos.
struct CameraPicker: UIViewControllerRepresentable {
    var device: UIImagePickerController.CameraDevice = .rear
    var onLibrary: (() -> Void)?
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        if UIImagePickerController.isCameraDeviceAvailable(device) {
            controller.cameraDevice = device
        }
        controller.delegate = context.coordinator
        if onLibrary != nil {
            controller.cameraOverlayView = libraryOverlay(in: controller, coordinator: context.coordinator)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    /// A full-size overlay that lets touches through to the native controls except on its button.
    private func libraryOverlay(in controller: UIImagePickerController, coordinator: Coordinator) -> UIView {
        let overlay = PassthroughView(frame: controller.view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .glass()
        } else {
            config = .filled()
            config.baseBackgroundColor = .secondarySystemBackground
            config.baseForegroundColor = .label
            config.cornerStyle = .capsule
        }
        config.image = UIImage(systemName: "photo.on.rectangle")
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in coordinator.openLibrary() })
        button.accessibilityLabel = "Choose from library"
        button.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: DS.Spacing.s11),
            button.heightAnchor.constraint(equalToConstant: DS.Spacing.s11),
            button.trailingAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.trailingAnchor, constant: -DS.Spacing.gutter),
            button.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.s2),
        ])
        return overlay
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func openLibrary() {
            parent.onLibrary?()
            parent.dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}

/// Hit-tests only its subviews, so the camera's own controls stay tappable underneath.
private final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}
