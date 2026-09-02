import Foundation

/// One occasion of eating a cooked recipe.
struct Meal: Identifiable, Hashable, Decodable {
    let id: UUID
    var recipeID: UUID
    var dishID: UUID {
        get { recipeID }
        set { recipeID = newValue }
    }
    /// Whoever cooked it. Only this person may edit the meal or invite others.
    var createdBy: UUID
    /// Calendar day, at local midnight — the column is a `date`, so there is no
    /// time of day to keep.
    var eatenOn: Date
    var notes: String
    /// Object paths in the private `meal-photos` bucket, `<meal_id>/<uuid>.jpg`.
    var photoPaths: [String]
    /// Primary cover photo path.
    var photoPath: String? { photoPaths.first }
    /// Effort required to make the meal.
    var effort: EffortLevel?
    /// Rotation goal / repeat desire.
    var repeatDesire: RotationGoal?
    /// Used only to order two meals eaten on the same day.
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipeID = "dish_id"
        case createdBy = "created_by"
        case eatenOn = "eaten_on"
        case notes
        case photoPath = "photo_path"
        case photoPaths = "photo_paths"
        case effort
        case repeatDesire = "repeat_desire"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipeID = try container.decode(UUID.self, forKey: .recipeID)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        eatenOn = try container.decodeDay(.eatenOn)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        if let paths = try container.decodeIfPresent([String].self, forKey: .photoPaths), !paths.isEmpty {
            photoPaths = paths
        } else if let single = try container.decodeIfPresent(String.self, forKey: .photoPath) {
            photoPaths = [single]
        } else {
            photoPaths = []
        }
        if let rawEffort = try container.decodeIfPresent(Int.self, forKey: .effort) {
            effort = EffortLevel(rawValue: rawEffort)
        } else {
            effort = nil
        }
        if let rawRepeat = try container.decodeIfPresent(Int.self, forKey: .repeatDesire) {
            repeatDesire = RotationGoal(rawValue: rawRepeat)
        } else {
            repeatDesire = nil
        }
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    init(
        id: UUID = UUID(),
        recipeID: UUID,
        createdBy: UUID,
        eatenOn: Date = .now,
        notes: String = "",
        photoPaths: [String] = [],
        effort: EffortLevel? = nil,
        repeatDesire: RotationGoal? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.recipeID = recipeID
        self.createdBy = createdBy
        self.eatenOn = eatenOn
        self.notes = notes
        self.photoPaths = photoPaths
        self.effort = effort
        self.repeatDesire = repeatDesire
        self.createdAt = createdAt
    }
}

// MARK: - Writes

struct NewMeal: Encodable {
    let dish_id: UUID
    let created_by: UUID
    let eaten_on: String
    let notes: String
    let photo_paths: [String]
    let effort: Int?
    let repeat_desire: Int?

    init(recipeID: UUID, createdBy: UUID, eatenOn: Date, notes: String, photoPaths: [String] = [], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.dish_id = recipeID
        self.created_by = createdBy
        self.eaten_on = PostgresDate.string(from: eatenOn)
        self.notes = notes
        self.photo_paths = photoPaths
        self.effort = effort?.rawValue
        self.repeat_desire = repeatDesire?.rawValue
    }

    init(dishID: UUID, createdBy: UUID, eatenOn: Date, notes: String, photoPaths: [String] = [], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.init(recipeID: dishID, createdBy: createdBy, eatenOn: eatenOn, notes: notes, photoPaths: photoPaths, effort: effort, repeatDesire: repeatDesire)
    }
}

struct MealPatch: Encodable {
    let dish_id: UUID
    let eaten_on: String
    let notes: String
    let effort: Int?
    let repeat_desire: Int?

    init(recipeID: UUID, eatenOn: Date, notes: String, effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.dish_id = recipeID
        self.eaten_on = PostgresDate.string(from: eatenOn)
        self.notes = notes
        self.effort = effort?.rawValue
        self.repeat_desire = repeatDesire?.rawValue
    }

    init(dishID: UUID, eatenOn: Date, notes: String, effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.init(recipeID: dishID, eatenOn: eatenOn, notes: notes, effort: effort, repeatDesire: repeatDesire)
    }
}

/// Photo paths patch for a meal.
struct MealPhotosPatch: Encodable {
    let photo_paths: [String]
    let photo_path: String?

    init(photoPaths: [String]) {
        self.photo_paths = photoPaths
        self.photo_path = photoPaths.first
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
        reaction = Reaction(rawValue: raw) ?? .good
    }

    init(
        id: UUID = UUID(),
        mealID: UUID,
        raterID: UUID? = nil,
        eaterID: UUID? = nil,
        reaction: Reaction
    ) {
        self.id = id
        self.mealID = mealID
        self.raterID = raterID
        self.eaterID = eaterID
        self.reaction = reaction
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
