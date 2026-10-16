import Foundation

extension ParsedRecipeResult {
    /// What the scan could not read, or nil when it found both ingredients and steps.
    var extractionWarning: String? {
        switch (ingredientGroups.allIngredients.isEmpty, instructions.isEmpty) {
        case (true, true):
            return "We couldn\u{2019}t read any ingredients or steps from your photos. Try a closer, well-lit shot, or add them below."
        case (true, false):
            return "We couldn\u{2019}t find the ingredients in your photos. Add them below, or scan the ingredients page again."
        case (false, true):
            return "We couldn\u{2019}t find the steps in your photos. Add them below, or scan the method page again."
        case (false, false):
            return nil
        }
    }
}
