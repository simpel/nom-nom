// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// LabeledPhotoCard crops. The category photography is a square master, so only
/// 1:1 and 4:5 are safe (DS README); there is no wide crop.
enum LabeledPhotoCardShape: Equatable {
    /// 1:1 (PhotoCard `md`): grid tiles, cuisine picker, and the category hero cover.
    case square
    /// 4:5 (PhotoCard `cover`): a tall feature tile.
    case portrait

    var photoSize: PhotoCardSize { self == .square ? .md : .cover }
}

/// A category tile or cover: a PhotoCard filling its width, a bottom scrim
/// (`stone-1000` 72% → clear at 32% from the top) and a label set on the photo,
/// title `sans-md` semibold + subtitle `sans-sm`, both `on-photo`. `isSelected`
/// adds the PhotoCard ring and a "Selected" check Badge.
///
/// ```swift
/// LabeledPhotoCard(.none(cuisine: "italian"), title: "Italian", subtitle: "12 recipes")
/// ```
struct LabeledPhotoCard: View {
    let source: PhotoCardSource
    let title: String
    var subtitle: String?
    var shape: LabeledPhotoCardShape
    var isSelected: Bool
    var action: (() -> Void)?

    init(
        _ source: PhotoCardSource,
        title: String,
        subtitle: String? = nil,
        shape: LabeledPhotoCardShape = .square,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.source = source
        self.title = title
        self.subtitle = subtitle
        self.shape = shape
        self.isSelected = isSelected
        self.action = action
    }

    private var size: PhotoCardSize { shape.photoSize }

    var body: some View {
        if let action {
            Button(action: action) { card }
                .buttonStyle(AppPressableButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            card
        }
    }

    private var card: some View {
        PhotoCard(source, size: size, fillsWidth: true, isSelected: isSelected) {
            ZStack(alignment: .bottomLeading) {
                PhotoScrim()
                label
            }
            .clipShape(RoundedRectangle(cornerRadius: size.radius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Badge("Selected", icon: "checkmark", appearance: .solid, size: .sm)
                        .padding(size.badgeInset)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, subtitle].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isImage)
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
            Text(title)
                .textStyle(.sansMd, tone: nil, weight: .semibold)
                .lineLimit(2)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .textStyle(.sansSm, tone: nil, numeric: true)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(DS.Color.onPhoto)
        .multilineTextAlignment(.leading)
        .padding(DS.Spacing.s3)
    }
}

private struct LabeledPhotoCardGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    LabeledPhotoCard(.none(cuisine: "mexican"), title: "Mexican", subtitle: "5 recipes")
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible())],
                        spacing: DS.Spacing.s3
                    ) {
                        LabeledPhotoCard(.none(cuisine: "italian"), title: "Italian", subtitle: "12 recipes", action: {})
                        LabeledPhotoCard(.none(cuisine: "japanese"), title: "Japanese", isSelected: true, action: {})
                        LabeledPhotoCard(.none(), title: "Other", subtitle: "No recipes yet")
                        LabeledPhotoCard(.none(cuisine: "indian"), title: "Indian", shape: .portrait)
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
