// recipes.ingredient_groups: ingredients in optional named groups ("Sauce", "Salad").
// A recipe without sections is one group with name null.

export interface Ingredient {
  quantity?: string
  measurement?: string
  ingredient: string
}

export interface IngredientGroup {
  name?: string | null
  ingredients: Ingredient[]
}

export function flattenIngredients(groups: IngredientGroup[] | null | undefined): Ingredient[] {
  if (!Array.isArray(groups)) return []
  return groups.flatMap((g) => (Array.isArray(g?.ingredients) ? g.ingredients : []))
}
