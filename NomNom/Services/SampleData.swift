import Foundation
import Supabase
import UIKit

#if DEBUG
/// A plausible few months of history, so the suggestion tab has something to chew
/// on in the simulator.
///
/// Writes to whichever Supabase the build points at — the local stack, in a debug
/// build. Batched rather than looped through `FoodStore.save`, because seeding ten
/// dishes one meal at a time is dozens of round trips for something that should
/// take three.
///
/// Safe to run twice: existing household members are reused and dishes already
/// present are skipped, so it tops up rather than duplicating.
enum SampleData {

    // name, tags, days-ago each time it was served, verdict per kid
    private static let plan: [(String, [String], [Int], [[Reaction]])] = [
        ("Tacos", ["friday", "quick"], [5, 12, 19, 33], [[.loved, .loved], [.loved, .ok], [.loved, .loved], [.loved, .loved]]),
        ("Pancakes", ["sweet", "quick"], [9, 30, 61], [[.loved, .loved], [.loved, .loved], [.ok, .loved]]),
        ("Fish gratin", ["oven"], [21, 74], [[.disliked, .ok], [.disliked, .disliked]]),
        ("Meatballs and mash", ["classic"], [3, 17, 40, 58], [[.loved, .ok], [.ok, .ok], [.loved, .ok], [.loved, .loved]]),
        ("Pasta bolognese", ["quick", "classic"], [7, 24, 44], [[.ok, .loved], [.loved, .loved], [.ok, .loved]]),
        ("Chickpea curry", ["veggie"], [48], [[.ok, .disliked]]),
        ("Pea soup", ["thursday"], [90], [[.disliked, .ok]]),
        ("Homemade pizza", ["weekend"], [14, 52], [[.loved, .loved], [.loved, .loved]]),
        ("Salmon and potatoes", ["oven"], [28], [[.ok, .ok]]),
        ("Chicken wok", ["quick", "veggie"], [], [])
    ]

    @MainActor
    static func populate(_ store: FoodStore) async {
        do {
            let kids = try await ensureKids(store)
            try await seedDishes(store, kids: kids)
            await store.load()
        } catch {
            store.errorMessage = FoodStore.describe(error)
        }
    }

    @MainActor
    private static func ensureKids(_ store: FoodStore) async throws -> [Eater] {
        let existing = store.myEaters.sorted { $0.sortIndex < $1.sortIndex }
        if existing.count >= 2 { return existing }

        let wanted = [("Elsa", "👧", 0), ("Vidar", "👦", 1)]
            .filter { candidate in
                !existing.contains { $0.name.caseInsensitiveCompare(candidate.0) == .orderedSame }
            }
            .map { NewEater(owner_id: store.userID, name: $0.0, emoji: $0.1, sort_index: $0.2) }

        guard !wanted.isEmpty else { return existing }

        let created: [Eater] = try await supabase
            .from("eaters")
            .insert(wanted)
            .select()
            .execute()
            .value

        return (existing + created).sorted { $0.sortIndex < $1.sortIndex }
    }

    @MainActor
    private static func seedDishes(_ store: FoodStore, kids: [Eater]) async throws {
        let known = Set(store.myDishes.map(\.normalizedName))
        let todo = plan.filter { !known.contains($0.0.normalizedForMatching) }
        guard !todo.isEmpty else { return }

        let dishes: [Dish] = try await supabase
            .from("dishes")
            .insert(todo.map { NewDish(ownerID: store.userID, name: $0.0, tags: $0.1) })
            .select()
            .execute()
            .value

        // Match the inserted rows back to the plan by folded name rather than by
        // position: PostgREST returns rows for a bulk insert without promising the
        // order they were sent in.
        let byKey = Dictionary(dishes.map { ($0.normalizedName, $0) }, uniquingKeysWith: { first, _ in first })

        var newMeals: [NewMeal] = []
        /// Which plan entry each meal came from, so verdicts can be attached once
        /// the meals come back with their ids.
        var provenance: [(dishKey: String, day: Date, verdicts: [Reaction])] = []

        for (name, _, daysAgoList, verdicts) in todo {
            let key = name.normalizedForMatching
            guard let dish = byKey[key] else { continue }
            for (index, daysAgo) in daysAgoList.enumerated() {
                let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
                newMeals.append(NewMeal(dishID: dish.id, createdBy: store.userID, eatenOn: day, notes: ""))
                provenance.append((dishKey: key,
                                   day: Calendar.current.startOfDay(for: day),
                                   verdicts: index < verdicts.count ? verdicts[index] : []))
            }
        }

        guard !newMeals.isEmpty else { return }

        let meals: [Meal] = try await supabase
            .from("meals")
            .insert(newMeals)
            .select()
            .execute()
            .value

        // Same ordering caveat, so pair on (dish, day) — unique within this fixture.
        var mealLookup: [String: UUID] = [:]
        for meal in meals {
            guard let dish = dishes.first(where: { $0.id == meal.dishID }) else { continue }
            mealLookup[pairKey(dish.normalizedName, meal.eatenOn)] = meal.id
        }

        var newRatings: [NewRating] = []
        for entry in provenance {
            guard let mealID = mealLookup[pairKey(entry.dishKey, entry.day)] else { continue }
            for (index, reaction) in entry.verdicts.enumerated() where index < kids.count {
                newRatings.append(NewRating(mealID: mealID,
                                            source: .eater(kids[index].id),
                                            reaction: reaction))
            }
        }

        if !newRatings.isEmpty {
            try await supabase.from("meal_ratings").insert(newRatings).execute()
        }

        try await attachPhotos(to: meals, dishes: dishes)
    }

    /// Gives the most recent serving of each dish a drawn-on-the-spot photo.
    ///
    /// Worth doing rather than leaving the placeholders: it's the only thing in the
    /// seed that exercises the storage path end to end — upload under
    /// `<meal_id>/<uuid>.jpg`, the policy that reads the meal id back out of it, and
    /// the authenticated download — and it's the thumbnail the list and the calendar
    /// actually reach for.
    private static func attachPhotos(to meals: [Meal], dishes: [Dish]) async throws {
        let newestPerDish = Dictionary(grouping: meals, by: \.dishID)
            .compactMapValues { $0.max { $0.eatenOn < $1.eatenOn } }

        for (dishID, meal) in newestPerDish {
            guard let dish = dishes.first(where: { $0.id == dishID }),
                  let data = card(for: dish.name) else { continue }
            let path = "\(meal.id.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
            _ = try await supabase.storage
                .from(SupabaseConfig.photoBucket)
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
            try await supabase
                .from("meals")
                .update(MealPhotoPatch(photo_path: path))
                .eq("id", value: meal.id.uuidString)
                .execute()
            await PhotoCache.shared.put(data, for: path)
        }
    }

    /// A flat colour card with the dish's initials, standing in for a photo. The
    /// hue is derived from the name so the same dish keeps the same colour.
    private static func card(for name: String) -> Data? {
        let size = CGSize(width: 800, height: 800)
        let hue = Double(abs(name.normalizedForMatching.hashValue) % 360) / 360
        let background = UIColor(hue: hue, saturation: 0.45, brightness: 0.72, alpha: 1)
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            background.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 300, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
            let text = initials as NSString
            let bounds = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: (size.width - bounds.width) / 2,
                                  y: (size.height - bounds.height) / 2),
                      withAttributes: attributes)
        }
        return PhotoTools.prepare(image)
    }

    private static func pairKey(_ dishKey: String, _ day: Date) -> String {
        "\(dishKey)|\(PostgresDate.string(from: day))"
    }
}
#endif
