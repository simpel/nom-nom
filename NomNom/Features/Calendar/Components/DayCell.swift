import SwiftUI

struct DayCell: View {
    let day: Date
    let photoPath: String?
    let mealCount: Int
    let moodTint: Color?
    let dishNames: [String]
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                .fill(Color.secondary.opacity(0.08))

            if photoPath != nil {
                RemoteMealPhoto(path: photoPath, cornerRadius: AppRadius.photo)
                    .frame(height: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .fill(.black.opacity(0.28))
                    }
            }

            VStack {
                HStack {
                    Text(day, format: .dateTime.day())
                        .font(.caption.weight(isToday ? .bold : .regular))
                        .foregroundStyle(dayNumberStyle)
                        .padding(4)
                    Spacer()
                }
                Spacer()
                if let moodTint {
                    HStack(spacing: 2) {
                        ForEach(0..<min(mealCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(moodTint)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.45) : .clear),
                              lineWidth: isSelected ? 2 : 1.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var dayNumberStyle: AnyShapeStyle {
        if photoPath != nil { return AnyShapeStyle(.white) }
        if isToday { return AnyShapeStyle(Color.accentColor) }
        return AnyShapeStyle(.primary)
    }

    private var accessibilityText: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        let dayText = formatter.string(from: day)
        if dishNames.isEmpty { return dayText }
        return "\(dayText): " + dishNames.joined(separator: ", ")
    }
}
