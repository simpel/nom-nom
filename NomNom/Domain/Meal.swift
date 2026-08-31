import Foundation

/// One occasion of eating a dish.
struct Meal: Identifiable, Hashable, Decodable {
    let id: UUID
    var dishID: UUID
    /// Whoever cooked it. Only this person may edit the meal or invite others.
    var createdBy: UUID
    /// Calendar day, at local midnight — the column is a `date`, so there is no
    /// time of day to keep.
    var eatenOn: Date
    var notes: String
    /// Object path in the private `meal-photos` bucket, `<meal_id>/<uuid>.jpg`.
    var photoPath: String?
    /// Used only to order two meals eaten on the same day.
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case dishID = "dish_id"
        case createdBy = "created_by"
        case eatenOn = "eaten_on"
        case notes
        case photoPath = "photo_path"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dishID = try container.decode(UUID.self, forKey: .dishID)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        eatenOn = try container.decodeDay(.eatenOn)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
        createdAt = try container.decodeTimestamp(.createdAt)
    }
}

// MARK: - Writes

struct NewMeal: Encodable {
    let dish_id: UUID
    let created_by: UUID
    let eaten_on: String
    let notes: String

    init(dishID: UUID, createdBy: UUID, eatenOn: Date, notes: String) {
        self.dish_id = dishID
        self.created_by = createdBy
        self.eaten_on = PostgresDate.string(from: eatenOn)
        self.notes = notes
    }
}

struct MealPatch: Encodable {
    let dish_id: UUID
    let eaten_on: String
    let notes: String

    init(dishID: UUID, eatenOn: Date, notes: String) {
        self.dish_id = dishID
        self.eaten_on = PostgresDate.string(from: eatenOn)
        self.notes = notes
    }
}

/// Photo path is patched on its own: the upload happens after the meal row exists,
/// because the storage policy checks the meal id in the object path against a real
/// row in `meals`, so there is nothing to upload *to* until the row is there.
///
/// The encoder is written out by hand because the synthesized one uses
/// `encodeIfPresent` for optionals, which *omits* a nil rather than emitting
/// `null`. Removing a photo would then PATCH an empty body `{}`, which updates no
/// columns, matches no rows under `return=representation`, and fails with PGRST116
/// — while the path stayed in the database. Clearing a column needs an explicit
/// null on the wire.
struct MealPhotoPatch: Encodable {
    let photo_path: String?

    enum CodingKeys: String, CodingKey {
        case photo_path
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let photo_path {
            try container.encode(photo_path, forKey: .photo_path)
        } else {
            try container.encodeNil(forKey: .photo_path)
        }
    }
}

// MARK: - Ratings

/// Who a verdict came from.
///
/// The schema allows exactly one of two sources per rating — an invited account
/// holder rating for themselves, or a household member the cook rated on their
/// behalf — enforced by the `one_rating_source` check. Modelling that as a single
/// key rather than two nullable UUIDs means the ranking can treat "Elsa" and "the
/// friend we invited" the same way without the two id spaces ever colliding.
enum RaterRef: Hashable {
    /// A household member with no account: one of the kids.
    case eater(UUID)
    /// Somebody with an `auth.users` row — the cook, or an invited guest.
    case account(UUID)
}

/// A single verdict on a single meal.
struct MealRating: Identifiable, Hashable, Decodable {
    let id: UUID
    var mealID: UUID
    var raterID: UUID?
    var eaterID: UUID?
    var reaction: Reaction

    enum CodingKeys: String, CodingKey {
        case id
        case mealID = "meal_id"
        case raterID = "rater_id"
        case eaterID = "eater_id"
        case reaction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mealID = try container.decode(UUID.self, forKey: .mealID)
        raterID = try container.decodeIfPresent(UUID.self, forKey: .raterID)
        eaterID = try container.decodeIfPresent(UUID.self, forKey: .eaterID)
        let raw = try container.decode(Int.self, forKey: .reaction)
        reaction = Reaction(rawValue: raw) ?? .ok
    }

    /// The check constraint guarantees one of the two is set, so the fallback is
    /// unreachable in practice — but a decode of a hand-edited row shouldn't crash.
    var source: RaterRef {
        if let eaterID { return .eater(eaterID) }
        if let raterID { return .account(raterID) }
        return .eater(id)
    }
}

struct NewRating: Encodable {
    let meal_id: UUID
    let rater_id: UUID?
    let eater_id: UUID?
    let reaction: Int

    init(mealID: UUID, source: RaterRef, reaction: Reaction) {
        self.meal_id = mealID
        switch source {
        case .eater(let id):
            self.eater_id = id
            self.rater_id = nil
        case .account(let id):
            self.rater_id = id
            self.eater_id = nil
        }
        self.reaction = reaction.rawValue
    }
}

struct RatingPatch: Encodable {
    let reaction: Int
}
