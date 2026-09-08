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
                    VStack(spacing: DS.Spacing.section) {
                        guidanceHeader

                        captureActions

                        if !stagedPhotos.isEmpty {
                            RecipeScannerStagingTray(
                                photos: stagedPhotos,
                                maxPhotos: maxPhotos,
                                onRemove: { removePhoto(at: $0) }
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.screenHorizontal)
                    .padding(.top, DS.Spacing.screenTop)
                    .padding(.bottom, 100) // Clearance for fixed bottom CTA
                }
                .background(DS.Color.bg)

                // Fixed bottom CTA
                VStack {
                    Spacer()
                    bottomActionBar
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                        .padding(.bottom, DS.Spacing.screenBottom)
                        .background(
                            LinearGradient(
                                colors: [DS.Color.bg.opacity(0), DS.Color.bg],
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        analysisTask?.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Cancel")
                }
            }
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
    }

    // MARK: - Subviews

    private var guidanceHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cookbook & Card Scanner")
                .font(.headline.weight(.semibold))
                .foregroundStyle(DS.Color.textPrimary)

            Text("Take or select up to \(maxPhotos) photos covering the title, ingredients, and cooking steps.")
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var captureActions: some View {
        HStack(spacing: 12) {
            if CameraPicker.isAvailable {
                AppButton(
                    "Camera",
                    systemImage: "camera",
                    variant: .secondary,
                    style: .outlined,
                    size: .md,
                    isFullWidth: true
                ) {
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
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.callout.weight(.semibold))
                    Text("Library")
                        .font(.callout.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .padding(.horizontal, 16)
                .foregroundStyle(DS.Color.textPrimary)
                .background(DS.Color.panel)
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(DS.Color.lineStrong, lineWidth: 1.5)
                }
            }
            .disabled(stagedPhotos.count >= maxPhotos || isAnalyzing)
        }
    }

    private var bottomActionBar: some View {
        AppButton(
            extractButtonTitle,
            systemImage: "sparkles",
            variant: stagedPhotos.isEmpty ? .neutral : .primary,
            style: .normal,
            size: .xl,
            isFullWidth: true
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
