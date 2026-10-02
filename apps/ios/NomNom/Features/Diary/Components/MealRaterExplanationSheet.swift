import SwiftUI

/// Why a rater likely scored a meal the way they did, from their own history across
/// dish kinds, methods, ingredients, cuisines and their baseline. A DS BottomSheet:
/// SheetHero (their score vs their usual) over a SheetCard of reasons. Pro only.
struct MealRaterExplanationSheet: View {
    let target: MealExplanationTarget

    var body: some View {
        NavigationStack {
            SheetBody {
                ProGate {
                    VStack(alignment: .leading, spacing: DS.Spacing.s6) {
                        SheetHero(score: target.score, lead: lead.text, emphasis: lead.emphasis)
                        SheetCard(
                            "Why \(target.raterName) scored it this way",
                            provenance: provenance,
                            reasons: target.affinities.map { affinity in
                                SheetReason(
                                    id: affinity.id,
                                    title: heading(for: affinity),
                                    text: affinity.sentence(name: target.raterName)
                                )
                            }
                        )
                    }
                }
            }
            .screenTitle("\(target.raterName)\u{2019}s score", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: [.medium, .large])
    }

    private var provenance: String? {
        guard target.ratingCount > 0 else { return nil }
        let count = target.ratingCount == 1 ? "1 rating" : "\(target.ratingCount) ratings"
        return "Based on \(target.raterName)\u{2019}s \(count)"
    }

    private var lead: (text: String?, emphasis: String?) {
        guard let score = target.score else { return (nil, nil) }
        guard let usual = target.usualScore else {
            return ("\(target.raterName)\u{2019}s first rating.", nil)
        }
        let usualPoints = Int((usual * 100).rounded())
        let delta = Int(((score - usual) * 100).rounded())
        let owner = "\(target.raterName)\u{2019}s usual of \(usualPoints)"
        if delta == 0 { return ("Right on \(owner).", nil) }
        let emphasis = "\(abs(delta)) \(delta > 0 ? "above" : "below")"
        return ("\(emphasis) \(owner).", emphasis)
    }

    private func heading(for affinity: RaterTagAffinity) -> String {
        switch affinity.kind {
        case .dishKind(let name): return "Dish kind: \(name)"
        case .cookingMethod(let name): return "Cooking method: \(name.capitalized)"
        case .ingredient(let name): return "Ingredient: \(name.capitalized)"
        case .cuisine(let name): return "Cuisine: \(name.capitalized)"
        case .baseline: return "Overall baseline"
        }
    }
}
