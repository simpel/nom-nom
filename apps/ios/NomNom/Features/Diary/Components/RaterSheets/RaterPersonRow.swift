import SwiftUI

/// The rater sheets' PersonHeaderRow: Avatar `lg`, first name, and "Chef · Member of
/// Fridays" (or "Member of Fridays"). Opens their profile when they have one.
struct RaterPersonRow: View {
    let meal: Meal
    let rater: RaterRef
    let onOpenProfile: () -> Void

    @Environment(FoodStore.self) private var store

    private var accountID: UUID? {
        if case .account(let id) = rater { return id }
        return nil
    }

    private var meta: String? {
        let chef = rater == .account(meal.createdBy) ? "Chef" : nil
        let party = store.parties(forMeal: meal.id).first.map { "Member of \($0.name)" }
        let parts = [chef, party].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " \u{00B7} ")
    }

    private var avatar: Avatar {
        if let profile = accountID.flatMap({ store.profiles[$0] }) ?? (rater == .account(store.userID) ? store.myProfile : nil) {
            return Avatar(profile: profile, size: .lg, decorative: true)
        }
        return Avatar(name: store.label(for: rater).name, size: .lg, decorative: true)
    }

    var body: some View {
        let isViewer = rater == .account(store.userID)
        let name = isViewer ? "You" : store.firstName(for: rater)
        PersonHeaderRow(
            avatar: avatar,
            name: name,
            meta: meta,
            action: accountID == nil ? nil : onOpenProfile
        )
    }
}
