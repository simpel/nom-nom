import Foundation

/// One occasion of eating a cooked recipe.
struct Meal: Identifiable, Hashable, Decodable {
    let id: UUID
    var recipeID: UUID
    /// Optional name for this serving; the recipe's name is shown when it is nil.
    var title: String?
    var dishID: UUID {
        get { recipeID }
        set { recipeID = newValue }
    }
    /// Whoever cooked it. Only this person may edit the meal or invite others.
    var createdBy: UUID?
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
        case title
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
        title = try container.decodeIfPresent(String.self, forKey: .title)
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
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
        title: String? = nil,
        createdBy: UUID?,
        eatenOn: Date = .now,
        notes: String = "",
        photoPaths: [String] = [],
        effort: EffortLevel? = nil,
        repeatDesire: RotationGoal? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.recipeID = recipeID
        self.title = title
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
    let title: String?
    let created_by: UUID?
    let eaten_on: String
    let notes: String
    let photo_paths: [String]
    let effort: Int?
    let repeat_desire: Int?

    init(recipeID: UUID, title: String? = nil, createdBy: UUID, eatenOn: Date, notes: String, photoPaths: [String] = [], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.dish_id = recipeID
        self.title = title
        self.created_by = createdBy
        self.eaten_on = PostgresDate.string(from: eatenOn)
        self.notes = notes
        self.photo_paths = photoPaths
        self.effort = effort?.rawValue
        self.repeat_desire = repeatDesire?.rawValue
    }

    init(dishID: UUID, title: String? = nil, createdBy: UUID, eatenOn: Date, notes: String, photoPaths: [String] = [], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.init(recipeID: dishID, title: title, createdBy: createdBy, eatenOn: eatenOn, notes: notes, photoPaths: photoPaths, effort: effort, repeatDesire: repeatDesire)
    }
}

struct MealPatch: Encodable {
    let dish_id: UUID
    let title: String?
    let eaten_on: String
    let notes: String
    let effort: Int?
    let repeat_desire: Int?

    init(recipeID: UUID, title: String? = nil, eatenOn: Date, notes: String, effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.dish_id = recipeID
        self.title = title
        self.eaten_on = PostgresDate.string(from: eatenOn)
        self.notes = notes
        self.effort = effort?.rawValue
        self.repeat_desire = repeatDesire?.rawValue
    }

    init(dishID: UUID, title: String? = nil, eatenOn: Date, notes: String, effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.init(recipeID: dishID, title: title, eatenOn: eatenOn, notes: notes, effort: effort, repeatDesire: repeatDesire)
    }

    enum CodingKeys: String, CodingKey { case dish_id, title, eaten_on, notes, effort, repeat_desire }

    /// `title` is always sent, as null when cleared, so an edit can remove a custom name.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dish_id, forKey: .dish_id)
        try container.encode(title, forKey: .title)
        try container.encode(eaten_on, forKey: .eaten_on)
        try container.encode(notes, forKey: .notes)
        try container.encode(effort, forKey: .effort)
        try container.encode(repeat_desire, forKey: .repeat_desire)
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

    /// The underlying id, regardless of which source it came from — matches
    /// `coalesce(rater_id, eater_id)` as used server-side (e.g. `get_flavor_profile`).
    var id: UUID {
        switch self {
        case .eater(let id), .account(let id): id
        }
    }
}

/// A single verdict on a single meal, with what that rater said about it.
struct MealRating: Identifiable, Hashable, Decodable {
    let id: UUID
    var mealID: UUID
    var raterID: UUID?
    var eaterID: UUID?
    var reaction: Reaction
    /// `rating_tags` ids.
    var tags: [String]
    var plate: PlateCleared?
    var again: WantAgain?
    var note: String?
    /// This eater's score, 0…1: the verdict moved by again, plate and tags. Set by the
    /// `meal_ratings_set_score` trigger, the one place the formula lives.
    var score: Double

    enum CodingKeys: String, CodingKey {
        case id
        case mealID = "meal_id"
        case raterID = "rater_id"
        case eaterID = "eater_id"
        case reaction, tags, plate, again, note, score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mealID = try container.decode(UUID.self, forKey: .mealID)
        raterID = try container.decodeIfPresent(UUID.self, forKey: .raterID)
        eaterID = try container.decodeIfPresent(UUID.self, forKey: .eaterID)
        let raw = try container.decode(Int.self, forKey: .reaction)
        reaction = Reaction(rawValue: raw) ?? .good
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        plate = try container.decodeIfPresent(Int.self, forKey: .plate).flatMap(PlateCleared.init(rawValue:))
        again = try container.decodeIfPresent(Int.self, forKey: .again).flatMap(WantAgain.init(rawValue:))
        note = try container.decodeIfPresent(String.self, forKey: .note)
        score = try container.decodeIfPresent(Double.self, forKey: .score) ?? reaction.verdictScore
    }

    init(
        id: UUID = UUID(),
        mealID: UUID,
        raterID: UUID? = nil,
        eaterID: UUID? = nil,
        reaction: Reaction,
        tags: [String] = [],
        plate: PlateCleared? = nil,
        again: WantAgain? = nil,
        note: String? = nil,
        score: Double? = nil
    ) {
        self.id = id
        self.mealID = mealID
        self.raterID = raterID
        self.eaterID = eaterID
        self.reaction = reaction
        self.tags = tags
        self.plate = plate
        self.again = again
        self.note = note
        // Previews only: a saved rating always carries the server's score.
        self.score = score ?? reaction.verdictScore
    }

    /// The verdict word this rating's score reads as. Can differ from `reaction` (a
    /// Great with seconds and "soon" scores 90, Amazing): group by this wherever ratings
    /// are counted beside a score, so the split and the numeral agree.
    var tier: Reaction { Reaction(score: score) }

    /// The check constraint guarantees one of the two is set, so the fallback is
    /// unreachable in practice — but a decode of a hand-edited row shouldn't crash.
    var source: RaterRef {
        if let eaterID { return .eater(eaterID) }
        if let raterID { return .account(raterID) }
        return .eater(id)
    }
}

/// The viewer's own rating row. RLS only accepts `rater_id = auth.uid()`: nobody
/// rates for anybody else.
struct NewRating: Encodable {
    let meal_id: UUID
    let rater_id: UUID
    let reaction: Int
    let tags: [String]
    let plate: Int?
    let again: Int?
    let note: String?

    init(mealID: UUID, raterID: UUID, reaction: Reaction, answers: RatingAnswers = RatingAnswers()) {
        self.meal_id = mealID
        self.rater_id = raterID
        self.reaction = reaction.rawValue
        self.tags = answers.tags.sorted()
        self.plate = answers.plate?.rawValue
        self.again = answers.again?.rawValue
        let note = answers.note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = note.isEmpty ? nil : note
    }
}

/// Every column of the viewer's own rating, so clearing an answer clears it in the row.
struct RatingPatch: Encodable {
    let reaction: Int
    let tags: [String]
    let plate: Int?
    let again: Int?
    let note: String?

    init(reaction: Reaction, answers: RatingAnswers) {
        let row = NewRating(mealID: UUID(), raterID: UUID(), reaction: reaction, answers: answers)
        self.reaction = row.reaction
        self.tags = row.tags
        self.plate = row.plate
        self.again = row.again
        self.note = row.note
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(reaction, forKey: .reaction)
        try c.encode(tags, forKey: .tags)
        // Explicit nulls: a cleared answer must clear the column.
        try c.encode(plate, forKey: .plate)
        try c.encode(again, forKey: .again)
        try c.encode(note, forKey: .note)
    }

    enum CodingKeys: String, CodingKey { case reaction, tags, plate, again, note }
}
