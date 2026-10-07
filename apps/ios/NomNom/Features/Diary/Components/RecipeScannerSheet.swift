import SwiftUI
import PhotosUI

/// Modal sheet for scanning multiple recipe photos (cookbooks, cards, notes) with AI.
struct RecipeScannerSheet: View {
    var onParsed: ((ParsedRecipeResult, [Data]) -> Void)?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var stagedPhotos: [Data] = []
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var analysisTask: Task<Void, Never>?

    private let maxPhotos = 5

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: DS.Spacing.block) {
                        ScreenHeader(
                            "Cookbook & Card Scanner",
                            summary: "Take or select up to \(maxPhotos) photos covering the title, ingredients, and cooking steps."
                        )

                        captureActions

                        if !stagedPhotos.isEmpty {
                            RecipeScannerStagingTray(
                                photos: stagedPhotos,
                                maxPhotos: maxPhotos,
                                onRemove: { removePhoto(at: $0) }
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.gutter)
                    .padding(.top, DS.Spacing.s5)
                    .padding(.bottom, DS.Spacing.block)
                }
                .background(DS.Color.sheet)
                // Fixed bottom CTA; the scroll content insets itself above it.
                .safeAreaInset(edge: .bottom) {
                    bottomActionBar
                        .padding(.horizontal, DS.Spacing.gutter)
                        .padding(.bottom, DS.Spacing.s11)
                        .background(
                            LinearGradient(
                                colors: [DS.Color.sheet.opacity(DS.Opacity.o0), DS.Color.sheet],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                if isAnalyzing {
                    RecipeScannerOverlay {
                        analysisTask?.cancel()
                        isAnalyzing = false
                    }
                }
            }
            .screenTitle("Scan Recipe", displayMode: .inline)
            .sheetCancelToolbar()
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let prepared = PhotoTools.prepare(image), stagedPhotos.count < maxPhotos {
                        stagedPhotos.append(prepared)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .ignoresSafeArea()
            }
            .task(id: selectedPickerItems) {
                await loadPickedPhotos()
            }
            .alert("Couldn't extract recipe",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .discardGuard(isDirty: !stagedPhotos.isEmpty, isSaving: isAnalyzing) { analysisTask?.cancel() }
        .dsSheet()
    }

    // MARK: - Subviews

    private var captureActions: some View {
        HStack(spacing: DS.Spacing.s3) {
            if CameraPicker.isAvailable {
                AppButton("Camera", icon: "camera", appearance: .outline, fullWidth: true) {
                    showCamera = true
                }
                .disabled(stagedPhotos.count >= maxPhotos || isAnalyzing)
            }

            PhotosPicker(
                selection: $selectedPickerItems,
                maxSelectionCount: maxPhotos - stagedPhotos.count,
                matching: .images,
                photoLibrary: .shared()
            ) {
                AppButtonLabel("Library", icon: "photo.on.rectangle", appearance: .outline, fullWidth: true)
            }
            .buttonStyle(AppPressableButtonStyle())
            .disabled(stagedPhotos.count >= maxPhotos || isAnalyzing)
        }
    }

    private var bottomActionBar: some View {
        AppButton(
            extractButtonTitle,
            icon: "sparkles",
            variant: stagedPhotos.isEmpty ? .secondary : .primary,
            appearance: stagedPhotos.isEmpty ? .soft : .solid,
            size: .lg,
            fullWidth: true
        ) {
            extractRecipe()
        }
        .disabled(stagedPhotos.isEmpty || isAnalyzing)
    }

    private var extractButtonTitle: String {
        if stagedPhotos.isEmpty {
            return "Take or Select Photos"
        }
        return stagedPhotos.count == 1
            ? "Extract Recipe (1 Photo)"
            : "Extract Recipe (\(stagedPhotos.count) Photos)"
    }

    // MARK: - Actions

    private func removePhoto(at index: Int) {
        guard stagedPhotos.indices.contains(index) else { return }
        stagedPhotos.remove(at: index)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func loadPickedPhotos() async {
        guard !selectedPickerItems.isEmpty else { return }
        defer { selectedPickerItems = [] }

        for item in selectedPickerItems {
            guard stagedPhotos.count < maxPhotos else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                stagedPhotos.append(prepared)
            }
        }
    }

    private func extractRecipe() {
        guard !stagedPhotos.isEmpty else { return }
        isAnalyzing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        analysisTask = Task {
            do {
                let result = try await store.parseRecipeFromPhotos(stagedPhotos)
                isAnalyzing = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onParsed?(result, stagedPhotos)
                dismiss()
            } catch {
                if !Task.isCancelled {
                    isAnalyzing = false
                    FoodStore.log.error("Failed to parse recipe: \(error.localizedDescription, privacy: .public)")
                    errorMessage = FoodStore.describe(error)
                }
            }
        }
    }
}
