// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A whole screen still on its way, in screen anatomy order (root README): a ScreenHeader
/// of bones (avatar, title, date), then a score Card and a list, `block` apart in the
/// gutter on `bg`. Built only from Skeleton parts. The Skeleton README says a screen
/// shows its real chrome and header and skeletons the blocks below; a detail screen
/// fetched by id has no header yet either, so the header is bones too.
struct ScreenSkeleton: View {
    /// What the bones stand in for, read by VoiceOver.
    var label: String = "Loading"

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                VStack(spacing: DS.Spacing.s3) {
                    SkeletonBone(width: DS.Spacing.s20, height: DS.Spacing.s20)
                    SkeletonBone(width: DS.Spacing.s72, height: DS.Spacing.s9)
                    SkeletonBone(width: DS.Spacing.s36, height: DS.Spacing.s4)
                }
                .frame(maxWidth: .infinity)
                Skeleton(layout: .card, lines: 2)
                Skeleton(rows: 3, leading: .avatar, trailing: true)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s4)
        }
        .scrollDisabled(true)
        .background(DS.Color.bg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

#Preview { ScreenSkeleton() }
