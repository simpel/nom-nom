// recipes.ingredient_groups: the recipe's ingredients in optional named groups
// ("Sauce", "Salad"). A recipe without sections is one group with name null.
// See migrations/20261016120000_recipe_ingredient_groups.sql.

export interface Ingredient {
  quantity?: string;
  measurement?: string;
  ingredient: string;
}

export interface IngredientGroup {
  name?: string | null;
  ingredients: Ingredient[];
}

/** Every ingredient in order (group 0's, then group 1's, …). Cook-mode step indexes
 *  (recipes.instruction_details[].ingredients) point into this list. */
export function flattenIngredients(groups: IngredientGroup[] | null | undefined): Ingredient[] {
  if (!Array.isArray(groups)) return [];
  return groups.flatMap((g) => (Array.isArray(g?.ingredients) ? g.ingredients : []));
}

/** "500 g flour", "Salt & pepper". */
export function ingredientLine(ing: Ingredient): string {
  return [ing.quantity, ing.measurement, ing.ingredient].map((s) => s?.trim()).filter(Boolean).join(" ");
}

/** The groups as prompt text: named groups get a "Sauce:" heading, lines are "- …".
 *  `numbered` prefixes each line with its flat index instead ("0. …"). */
export function ingredientGroupsText(groups: IngredientGroup[] | null | undefined, numbered = false): string {
  if (!Array.isArray(groups)) return "";
  let index = 0;
  return groups
    .map((g) => {
      const lines = (g?.ingredients ?? []).map((ing) => `${numbered ? `${index++}.` : "-"} ${ingredientLine(ing)}`);
      const name = g?.name?.trim();
      return name ? [`${name}:`, ...lines].join("\n") : lines.join("\n");
    })
    .filter(Boolean)
    .join("\n");
}
