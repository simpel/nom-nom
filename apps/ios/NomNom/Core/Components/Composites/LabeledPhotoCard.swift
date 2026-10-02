import SwiftUI

/// A photo tile with a label laid over it (components/LabeledPhotoCard/README.md): a
/// category, a cuisine, a cover. Built from PhotoCard (`size` × `format`, PhotoCard's),
/// its bottom-up scrim, a label and an optional selected check.
///
/// - Label: `serif-sm` on `lg`, `sans-md` semibold on `sm`/`md`; one line of meta in
///   `sans-xs` at `opacity-80`. Both `stone-0`, `spacing-3` from the edges.
/// - Selected: PhotoCard's 2pt `primary` ring plus a `spacing-6` `primary` check disc
///   `spacing-2` from the top-right corner, never a wash over the photo.
/// - With `action` it is a button (`isSelected` trait when selected). To make it a link,
///   put it in a NavigationLink with `AppPressableButtonStyle`.
///
/// ```swift
/// LabeledPhotoCard(.none(cuisine: "italian"), label: "Italian", meta: "12 recipes", fillsWidth: true) { open() }
/// LabeledPhotoCard(.none(cuisine: "thai"), label: "Thai", selected: true) { pick() }
/// ```
struct LabeledPhotoCard: View {
    let source: PhotoCardSource
    let label: String
    var meta: String?
    var size: PhotoCardSize
    var format: PhotoCardFormat
    /// Fill the proposed width (a grid column) at the format's ratio.
    var fillsWidth: Bool
    var selected: Bool
    var action: (() -> Void)?

    init(
        _ source: PhotoCardSource,
        label: String,
        meta: String? = nil,
        size: PhotoCardSize = .md,
        format: PhotoCardFormat = .square,
        fillsWidth: Bool = false,
        selected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.source = source
        self.label = label
        self.meta = meta
        self.size = size
        self.format = format
        self.fillsWidth = fillsWidth
        self.selected = selected
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) { tile }
                .buttonStyle(AppPressableButtonStyle())
                .accessibilityAddTraits(selected ? .isSelected : [])
        } else {
            tile
        }
    }

    private var tile: some View {
        PhotoCard(source, size: size, format: format, fillsWidth: fillsWidth, isSelected: selected) {
            ZStack(alignment: .bottomLeading) {
                PhotoScrim()
                labelBlock
            }
            .clipShape(RoundedRectangle(cornerRadius: size.radius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if selected { check }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([label, meta].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isImage)
    }

    /// bundle.css `.nn-labeled-photo__label`: `spacing-3` inset, `spacing-0.5` gap.
    private var labelBlock: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
            if size == .lg {
                Text(label).textStyle(.serifSm, tone: nil, lines: 2)
            } else {
                Text(label).textStyle(.sansMd, tone: nil, weight: .semibold, lines: 2)
            }
            if let meta, !meta.isEmpty {
                Text(meta)
                    .textStyle(.sansXs, tone: nil, numeric: true, lines: 1)
                    .opacity(DS.Opacity.o80)
            }
        }
        .foregroundStyle(DS.Color.Stone.stone0)
        .multilineTextAlignment(.leading)
        .padding(DS.Spacing.s3)
    }

    /// bundle.css `.nn-labeled-photo__check`: `spacing-6` disc in `primary`, `on-primary`
    /// glyph at `text-xs`, `spacing-2` from the top and right.
    private var check: some View {
        Image(systemName: "checkmark")
            .textStyle(.sansXs, tone: nil)
            .foregroundStyle(DS.Color.onPrimary)
            .frame(width: DS.Spacing.s6, height: DS.Spacing.s6)
            .background(Circle().fill(DS.Color.primary))
            .padding(DS.Spacing.s2)
            .accessibilityHidden(true)
    }
}

private struct LabeledPhotoCardGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    LabeledPhotoCard(.none(cuisine: "mexican"), label: "Mexican", meta: "5 recipes",
                                     size: .lg, format: .landscape, fillsWidth: true)
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible())],
                        spacing: DS.Spacing.s3
                    ) {
                        LabeledPhotoCard(.none(cuisine: "italian"), label: "Italian", meta: "12 recipes", fillsWidth: true) {}
                        LabeledPhotoCard(.none(cuisine: "japanese"), label: "Japanese", fillsWidth: true, selected: true) {}
                        LabeledPhotoCard(.none(), label: "Other", meta: "No recipes yet", fillsWidth: true)
                        LabeledPhotoCard(.none(cuisine: "indian"), label: "Indian", format: .portrait, fillsWidth: true)
                    }
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { LabeledPhotoCardGallery() }
#Preview("Dark") { LabeledPhotoCardGallery().preferredColorScheme(.dark) }
