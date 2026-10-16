// The text-model step before an image is drawn: turn a recipe (or a category) into a
// food description the photo prompt can use. Falls back to generic text when the model
// is unavailable, so a photo is still made.

import { chatJson, type GatewayConfig } from "./pipeline.ts";
import { flattenIngredients, ingredientLine, type IngredientGroup } from "../ingredients.ts";

export interface RecipeBriefInput {
  name?: string;
  cuisine?: string | null;
  ingredient_groups?: IngredientGroup[];
  instructions?: string[];
}

export interface RecipeBrief {
  dish: string;
  elements: string;
  garnish: string;
  beverage: string;
}

export interface CategoryBrief {
  category: string;
  dishes: string;
  vessels?: string;
}

interface RecipeResolution {
  resolved_dish?: string;
  resolved_elements?: string;
  resolved_garnish?: string;
  resolved_beverage?: string;
}

interface CategoryResolution {
  resolved_category?: string;
  resolved_dishes?: string;
  vessels_narrative?: string;
}

const CATEGORY_RESOLUTION_SYSTEM_PROMPT = `You are an expert culinary director and food photographer art director.
Analyze the culinary category / kitchen provided by the user:

Rules:
1. Category Spread: Select 3 to 4 iconic, visually complementary dishes representing the authentic culinary tradition of this kitchen/category.
2. Distinct Textures & Garnishes: Each dish should feature distinct textured components (e.g. braised, roasted, fresh, sauced) and classic culinary garnishes.
3. Category-Specific Traditional Vessels: If this culinary category has traditional, iconic plates or serving vessels strongly associated with its heritage (for example: a shallow rustic terracotta cazuela in Mexican or Spanish cuisine, a dark textured Japanese ceramic yakimono or tenmoku plate, an Indian hammered brass/earthenware handi, a Korean stone ttukbaegi bowl, or a French enameled cast-iron gratin dish), replace 1 or 2 of the plates in the picture with these authentic traditional vessels to better portray the category. The remaining dishes should stay on round stoneware coupe plates. If no unique traditional vessel is customary, use matching stoneware coupe plates throughout.
4. Strict Exclusion Rules: No Cutlery or Utensils (no forks, knives, spoons, chopsticks, skewers). No Table Props (no glasses, cups, napkins, ramekins, side bowls, condiment bottles, placemats). Never Render Empty Plates: every plate or vessel in the spread must be filled with food — no bare, unfilled, or empty dishware anywhere in frame.
5. In resolved_dishes, name each dish and its vessel, but never mention the table, props, the camera or lighting; the photo brief sets those.
6. Identify:
   - resolved_category: Canonical display name of the kitchen/category (e.g. "Mexican Kitchen").
   - resolved_dishes: A descriptive narrative detailing the 3 to 4 dishes plated across the spread, explicitly specifying the plate or vessel each dish is served on (e.g. "a central round stoneware coupe plate of slow-braised cochinita pibil; a second dish of charred street-style elote served in an authentic shallow rustic Mexican terracotta cazuela; and a third coupe plate of fresh citrus ceviche").
   - vessels_narrative: Concise summary of the plating vessels (e.g. "two round stoneware coupe plates and one traditional rustic Mexican terracotta cazuela").

Return ONLY valid JSON matching:
{
  "resolved_category": "string",
  "resolved_dishes": "string",
  "vessels_narrative": "string"
}`;

const RECIPE_RESOLUTION_SYSTEM_PROMPT = `You are an expert culinary food stylist and photography art director.
Analyze the following recipe details provided by the user:

Rules:
1. Input Resolution: If only dish or cuisine is provided, automatically select an iconic, visually distinct dish with 2–3 textured components and a classic garnish.
2. One serving of one dish, generously portioned.
3. Describe only the food itself (components, textures, colours, garnish). Never mention plates, the table, props, the camera or lighting; the photo brief sets those.
4. Pick one drink that suits the dish and its cuisine, described as it looks from above in its glass or cup (e.g. "a stemmed glass of chilled white wine", "a tumbler of sparkling water with a lemon slice", "a small cup of green tea").
5. Identify:
   - resolved_dish: Name of the dish (e.g. "Crispy Pan-Seared Salmon").
   - resolved_elements: 2 to 3 textured components reflecting the ingredients and cooking method (e.g. "a golden seared salmon fillet with flaky layers, accompanied by charred tender asparagus spears and silky parsnip puree").
   - resolved_garnish: Classic culinary garnish (e.g. "a delicate drizzle of extra virgin olive oil and micro-chives").
   - resolved_beverage: The drink from rule 4.

Return ONLY valid JSON matching:
{
  "resolved_dish": "string",
  "resolved_elements": "string",
  "resolved_garnish": "string",
  "resolved_beverage": "string"
}`;

export async function resolveRecipeBrief(
  gateway: GatewayConfig,
  textModel: string,
  input: RecipeBriefInput,
): Promise<RecipeBrief> {
  const ingredients = flattenIngredients(input.ingredient_groups).map(ingredientLine).filter(Boolean).join(", ");
  const instructions = (input.instructions || []).filter(Boolean).join(" ");

  const userMessage = `Recipe Name: ${input.name || "Untitled Recipe"}
Cuisine: ${input.cuisine || "Unspecified"}
Ingredients: ${ingredients || "None specified"}
Cooking Method / Instructions: ${instructions || "None specified"}`;

  const brief: RecipeBrief = {
    dish: input.name || "Gourmet Dish",
    elements: "succulent main dish with complementary roasted textures",
    garnish: "a delicate garnish of fresh microgreens",
    beverage: "a tumbler of sparkling water with a slice of lemon",
  };

  try {
    const parsed = await chatJson<RecipeResolution>(gateway, textModel, RECIPE_RESOLUTION_SYSTEM_PROMPT, userMessage);
    if (parsed?.resolved_dish) brief.dish = parsed.resolved_dish;
    if (parsed?.resolved_elements) brief.elements = parsed.resolved_elements;
    if (parsed?.resolved_garnish) brief.garnish = parsed.resolved_garnish;
    if (parsed?.resolved_beverage) brief.beverage = parsed.resolved_beverage;
  } catch (err) {
    console.warn("Input resolution fallback used:", err);
  }
  return brief;
}

export async function resolveCategoryBrief(
  gateway: GatewayConfig,
  textModel: string,
  categoryName: string,
): Promise<CategoryBrief> {
  const brief: CategoryBrief = {
    category: `${categoryName} Kitchen`,
    dishes:
      "a central coupe plate with iconic regional main course, flanked by two complementary coupe plates of authentic side dishes and specialties",
  };

  try {
    const parsed = await chatJson<CategoryResolution>(
      gateway,
      textModel,
      CATEGORY_RESOLUTION_SYSTEM_PROMPT,
      `Category: ${categoryName}`,
    );
    if (parsed?.resolved_category) brief.category = parsed.resolved_category;
    if (parsed?.resolved_dishes) brief.dishes = parsed.resolved_dishes;
    if (parsed?.vessels_narrative) brief.vessels = parsed.vessels_narrative;
  } catch (err) {
    console.warn("Category input resolution fallback used:", err);
  }
  return brief;
}
