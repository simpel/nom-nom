import SwiftUI

/// The root tabs, so any screen (the page menu, "See all meals") can switch tab.
enum AppTab: Int, Hashable {
    case meals = 0, parties, recipes, insights, search
}

/// Root navigation state shared through the environment.
@Observable
final class AppNavigator {
    var tab: AppTab = .meals
}
