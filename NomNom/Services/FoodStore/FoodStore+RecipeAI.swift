import Foundation
import Supabase

/// Extracted recipe structure returned by the AI parsing service.
struct ParsedRecipeResult: Decodable {
    let name: String
    let serves: Int?
    let cuisine: String?
    let effort: Int?
    let tags: [String]
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let healthScore: Int?
    let healthVerdict: String?
    let healthRationale: String?
    let healthBreakdown: HealthBreakdown?

    var healthIndex: HealthIndex? {
        guard let score = healthScore, let verdict = healthVerdict, let rationale = healthRationale else {
            return nil
        }
        return HealthIndex(score: score, verdict: verdict, rationale: rationale, breakdown: healthBreakdown)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case serves
        case cuisine
        case effort
        case tags
        case ingredients
        case instructions
        case healthScore = "health_score"
        case healthVerdict = "health_verdict"
        case healthRationale = "health_rationale"
        case healthBreakdown = "health_breakdown"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        serves = try container.decodeIfPresent(Int.self, forKey: .serves)
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        effort = try container.decodeIfPresent(Int.self, forKey: .effort)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        ingredients = try container.decodeIfPresent([RecipeIngredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        healthScore = try container.decodeIfPresent(Int.self, forKey: .healthScore)
        healthVerdict = try container.decodeIfPresent(String.self, forKey: .healthVerdict)
        healthRationale = try container.decodeIfPresent(String.self, forKey: .healthRationale)
        healthBreakdown = try container.decodeIfPresent(HealthBreakdown.self, forKey: .healthBreakdown)
    }
}

extension FoodStore {

    struct ParseRecipePayload: Encodable {
        struct ImageInput: Encodable {
            let data: String
            let mime_type: String
        }
        let images: [ImageInput]
    }

    /// Calls the `parse-recipe` edge function via Vercel AI Gateway with multiple photo inputs.
    func parseRecipeFromPhotos(_ photoDataList: [Data]) async throws -> ParsedRecipeResult {
        let imagesPayload = photoDataList.map { data in
            ParseRecipePayload.ImageInput(
                data: data.base64EncodedString(),
                mime_type: "image/jpeg"
            )
        }

        let payload = ParseRecipePayload(images: imagesPayload)

        let result: ParsedRecipeResult = try await supabase.functions.invoke(
            "parse-recipe",
            options: FunctionInvokeOptions(body: payload)
        )

        return result
    }
}
