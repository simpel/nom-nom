import SwiftUI

/// Arc deck layout with interactive drag-to-reorder for meal draft photos.
struct MealPhotoDeckArcView: View {
    @Binding var draft: FoodStore.PhotosDraft
    let onTapCard: (Int) -> Void

    @State private var draggingItemID: String?
    @State private var dragOffset: CGSize = .zero
    @State private var activeTargetSlot: Int?

    var body: some View {
        let total = draft.count
        ZStack {
            ForEach(Array(draft.items.enumerated()), id: \.element.id) { index, item in
                let isDragging = (draggingItemID == item.id)
                let visualSlot = isDragging ? (activeTargetSlot ?? index) : effectiveVisualSlot(for: index, total: total)

                MealPhotoCardView(
                    item: item,
                    visualSlot: visualSlot,
                    isDragging: isDragging,
                    onDelete: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            if let itemIndex = draft.items.firstIndex(where: { $0.id == item.id }) {
                                draft.remove(at: itemIndex)
                            }
                        }
                    }
                )
                .rotationEffect(.degrees(isDragging ? Double(dragOffset.width) * 0.04 : cardAngle(index: visualSlot, total: total)))
                .offset(
                    x: isDragging
                        ? cardXOffset(index: index, total: total) + dragOffset.width
                        : cardXOffset(index: visualSlot, total: total),
                    y: isDragging
                        ? cardYOffset(index: index, total: total) + dragOffset.height - 12
                        : cardYOffset(index: visualSlot, total: total)
                )
                .scaleEffect(isDragging ? 1.08 : 1.0)
                .zIndex(isDragging ? 200 : Double(total - visualSlot))
                .animation(.spring(response: 0.32, dampingFraction: 0.75), value: visualSlot)
                .gesture(dragGesture(for: item, index: index, total: total))
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Deck Arc Math

    private func cardSpacing(total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        return total <= 3 ? 54.0 : max(32.0, min(50.0, 220.0 / CGFloat(total)))
    }

    private func cardAngle(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let maxAngle = min(20.0, Double(total - 1) * 4.8)
        return (rel / max(1.0, mid)) * maxAngle
    }

    private func cardXOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return rel * cardSpacing(total: total)
    }

    private func cardYOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let curve: CGFloat = total <= 3 ? 3.5 : min(3.0, 14.0 / CGFloat(total))
        return (rel * rel) * curve
    }

    private func effectiveVisualSlot(for index: Int, total: Int) -> Int {
        guard let draggingItemID,
              let draggedIndex = draft.items.firstIndex(where: { $0.id == draggingItemID }),
              let target = activeTargetSlot,
              draggedIndex != target else {
            return index
        }

        if index == draggedIndex {
            return target
        }

        if target < draggedIndex {
            if index >= target && index < draggedIndex {
                return index + 1
            }
        } else if target > draggedIndex {
            if index > draggedIndex && index <= target {
                return index - 1
            }
        }

        return index
    }

    private func dragGesture(for item: FoodStore.PhotosDraft.Item, index: Int, total: Int) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                if draggingItemID == nil {
                    draggingItemID = item.id
                    activeTargetSlot = index
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

                guard draggingItemID == item.id else { return }
                dragOffset = value.translation

                guard let originalIndex = draft.items.firstIndex(where: { $0.id == item.id }) else { return }
                guard total > 1 else { return }

                let mid = Double(total - 1) / 2.0
                let spacing = cardSpacing(total: total)
                let originalSlotX = cardXOffset(index: originalIndex, total: total)
                let currentFingerX = originalSlotX + value.translation.width

                let rawTargetSlot = Int(round((currentFingerX / spacing) + mid))
                let clampedTargetSlot = max(0, min(total - 1, rawTargetSlot))

                if clampedTargetSlot != activeTargetSlot {
                    activeTargetSlot = clampedTargetSlot
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
            .onEnded { value in
                let wasTap = abs(value.translation.width) < 6 && abs(value.translation.height) < 6

                if let currentDraggingID = draggingItemID,
                   let originalIndex = draft.items.firstIndex(where: { $0.id == currentDraggingID }),
                   let target = activeTargetSlot,
                   target != originalIndex,
                   !wasTap {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                        let moved = draft.items.remove(at: originalIndex)
                        draft.items.insert(moved, at: target)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                    draggingItemID = nil
                    dragOffset = .zero
                    activeTargetSlot = nil
                }

                if wasTap {
                    if let idx = draft.items.firstIndex(where: { $0.id == item.id }) {
                        onTapCard(idx)
                    }
                }
            }
    }
}
