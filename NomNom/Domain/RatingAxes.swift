import SwiftUI

/// Duration required to prep and cook the dish (0–15, 15–30, 30–60, 60+ min).
enum EffortLevel: Int, Codable, CaseIterable, Identifiable, Hashable, TactilePickerOption {
    case zeroTo15 = 0
    case fifteenTo30 = 1
    case thirtyTo60 = 2
    case over60 = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .zeroTo15: return "0–15 min"
        case .fifteenTo30: return "15–30 min"
        case .thirtyTo60: return "30–60 min"
        case .over60: return "60+ min"
        }
    }

    var icon: String? {
        switch self {
        case .zeroTo15: return "bolt.fill"
        case .fifteenTo30: return "timer"
        case .thirtyTo60: return "clock.fill"
        case .over60: return "hourglass"
        }
    }

    var description: String? {
        switch self {
        case .zeroTo15: return "Quick"
        case .fifteenTo30: return "Weeknight"
        case .thirtyTo60: return "Standard"
        case .over60: return "Slow cook"
        }
    }

    var tint: Color {
        DS.Color.accent
    }

    var title: String { label }
    var subtitle: String { description ?? "" }
    var systemImage: String { icon ?? "" }
}

/// How frequently the household wants this dish in regular rotation.
enum RotationGoal: Int, Codable, CaseIterable, Identifiable, Hashable, TactilePickerOption {
    case oneAndDone = 0
    case sometimes = 1
    case staple = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .oneAndDone: return "One & Done"
        case .sometimes: return "Sometimes"
        case .staple: return "Staple"
        }
    }

    var icon: String? {
        switch self {
        case .oneAndDone: return "archivebox.fill"
        case .sometimes: return "calendar"
        case .staple: return "arrow.triangle.2.circlepath"
        }
    }

    var description: String? {
        switch self {
        case .oneAndDone: return "Rarely or archive"
        case .sometimes: return "Every few weeks"
        case .staple: return "Regularly"
        }
    }

    var tint: Color {
        DS.Color.accent
    }

    var title: String { label }
    var subtitle: String { description ?? "" }
    var systemImage: String { icon ?? "" }
}

