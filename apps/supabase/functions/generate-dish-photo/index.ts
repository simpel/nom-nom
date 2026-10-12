// Edge function to generate editorial photographs using Vercel AI Gateway, in three modes that
// share one setting (oak table, overhead camera, daylight; see prompts.ts):
// - recipe:   the plate alone, saved to recipe-photos and dishes.photo_paths (recipe_id)
// - meal:     the plate laid with cutlery, a napkin and a drink, saved to meal-photos and
//             meals.photo_paths (meal_id; name/ingredients come from the meal's recipe)
// - category: a spread of the category's signature dishes, saved to category-photos
// A text model first turns the input into a food description (and a drink for meals).

import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";
import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import {
  categoryPhotoPrompt,
  detectImageFormat,
  imageSizeFor,
  mealPhotoPrompt,
  recipePhotoPrompt,
} from "./prompts.ts";
import { attachRowPhoto, saveCategoryPhoto } from "./storage.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface IngredientInput {
  quantity?: string;
  measurement?: string;
  ingredient?: string;
}

interface RequestPayload {
  mode?: "recipe" | "meal" | "category";
  recipe_id?: string;
  meal_id?: string;
  name?: string;
  cuisine?: string | null;
  category?: string;
  ingredients?: Array<IngredientInput | string>;
  instructions?: string[];
}

interface RecipeResolutionResult {
  resolved_dish: string;
  resolved_elements: string;
  resolved_garnish: string;
  resolved_beverage?: string;
}

interface CategoryResolutionResult {
  resolved_category: string;
  resolved_dishes: string;
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Webhook or user JWT authentication
  const expectedSecret = Deno.env.get("WEBHOOK_SECRET") || "local-development-webhook-secret";
  const receivedSecret = req.headers.get("x-webhook-secret");
  const authHeader = req.headers.get("authorization");

  if (!receivedSecret && !authHeader) {
    return new Response(JSON.stringify({ error: "Missing authentication" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (receivedSecret && receivedSecret !== expectedSecret) {
    return new Response(JSON.stringify({ error: "Invalid webhook secret" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const apiKey =
    Deno.env.get("VERCEL_AI_GATEWAY") ||
    Deno.env.get("VERCEL_AI_GATEWAY_KEY") ||
    Deno.env.get("AI_GATEWAY_API_KEY") ||
    Deno.env.get("VERCEL_AI_GATEWAY_TOKEN");

  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "AI Gateway API key is not configured" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Handle Supabase Database Webhook payloads from triggers
  if (payload.record && (payload.table === "categories" || payload.record.slug || payload.record.name)) {
    const rec = payload.record;
    payload = {
      mode: "category",
      category: rec.name || rec.slug,
    };
  }

  const isCategoryMode = payload.mode === "category" || (Boolean(payload.category) && !payload.recipe_id && !payload.name);
  const isMealMode = payload.mode === "meal";

  if (!isCategoryMode && !payload.name && !payload.cuisine) {
    return new Response(
      JSON.stringify({ error: "Recipe name or cuisine is required" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (isCategoryMode && !payload.category && !payload.cuisine && !payload.name) {
    return new Response(
      JSON.stringify({ error: "Category or cuisine name is required" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const logger = GenerationLogger.fromEnv();
  const admin = logger.client;

  const gatewayBaseUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";
  const textModel = await getFeatureModel(admin, "dish-photo-brief", "text");
  const imageModel = await getFeatureModel(admin, "generate-dish-photo", "image");

  let imagePrompt: string;
  let resolvedCategory: string | undefined;
  let resolvedDishes: string | undefined;
  let resolvedDish: string | undefined;
  let resolvedElements: string | undefined;
  let resolvedGarnish: string | undefined;
  let resolvedBeverage: string | undefined;

  if (isCategoryMode) {
    // =========================================================================
    // CATEGORY / KITCHEN MODE: Curated spread of 3-4 dishes on matching plates
    // =========================================================================
    const categoryName = (payload.category || payload.cuisine || payload.name || "Global Cuisine").trim();

    let vesselsNarrative: string | undefined;

    const userMessage = `Category: ${categoryName}`;

    resolvedCategory = `${categoryName} Kitchen`;
    resolvedDishes = "a central coupe plate with iconic regional main course, flanked by two complementary coupe plates of authentic side dishes and specialties";

    try {
      const textRes = await fetch(`${gatewayBaseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: textModel,
          messages: [
            { role: "system", content: CATEGORY_RESOLUTION_SYSTEM_PROMPT },
            { role: "user", content: userMessage }
          ],
          response_format: { type: "json_object" },
          temperature: 0.3,
        }),
      });

      if (textRes.ok) {
        const completion = await textRes.json();
        const rawText = completion.choices?.[0]?.message?.content?.trim();
        if (rawText) {
          let cleanText = rawText;
          if (cleanText.startsWith("```json")) cleanText = cleanText.slice(7);
          if (cleanText.startsWith("```")) cleanText = cleanText.slice(3);
          if (cleanText.endsWith("```")) cleanText = cleanText.slice(0, -3);
          const parsed: CategoryResolutionResult = JSON.parse(cleanText.trim());
          if (parsed.resolved_category) resolvedCategory = parsed.resolved_category;
          if (parsed.resolved_dishes) resolvedDishes = parsed.resolved_dishes;
          if (parsed.vessels_narrative) vesselsNarrative = parsed.vessels_narrative;
        }
      }
    } catch (err) {
      console.warn("Category input resolution fallback used:", err);
    }

    imagePrompt = categoryPhotoPrompt(resolvedCategory, resolvedDishes, vesselsNarrative);

  } else {
    // =========================================================================
    // RECIPE / MEAL MODE: one serving on one plate (a meal adds cutlery, napkin and a drink)
    // =========================================================================
    const ingredientsList = (payload.ingredients || [])
      .map((ing) => {
        if (typeof ing === "string") return ing;
        const amt = [ing.quantity, ing.measurement].filter(Boolean).join(" ");
        return amt ? `${amt} ${ing.ingredient || ""}`.trim() : (ing.ingredient || "");
      })
      .filter(Boolean)
      .join(", ");

    const instructionsList = (payload.instructions || []).filter(Boolean).join(" ");

    const userMessage = `Recipe Name: ${payload.name || "Untitled Dish"}
Cuisine: ${payload.cuisine || "Unspecified"}
Ingredients: ${ingredientsList || "None specified"}
Cooking Method / Instructions: ${instructionsList || "None specified"}`;

    resolvedDish = payload.name || "Gourmet Dish";
    resolvedElements = "succulent main dish with complementary roasted textures";
    resolvedGarnish = "a delicate garnish of fresh microgreens";
    resolvedBeverage = "a tumbler of sparkling water with a slice of lemon";

    try {
      const textRes = await fetch(`${gatewayBaseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: textModel,
          messages: [
            { role: "system", content: RECIPE_RESOLUTION_SYSTEM_PROMPT },
            { role: "user", content: userMessage }
          ],
          response_format: { type: "json_object" },
          temperature: 0.3,
        }),
      });

      if (textRes.ok) {
        const completion = await textRes.json();
        const rawText = completion.choices?.[0]?.message?.content?.trim();
        if (rawText) {
          let cleanText = rawText;
          if (cleanText.startsWith("```json")) cleanText = cleanText.slice(7);
          if (cleanText.startsWith("```")) cleanText = cleanText.slice(3);
          if (cleanText.endsWith("```")) cleanText = cleanText.slice(0, -3);
          const parsed: RecipeResolutionResult = JSON.parse(cleanText.trim());
          if (parsed.resolved_dish) resolvedDish = parsed.resolved_dish;
          if (parsed.resolved_elements) resolvedElements = parsed.resolved_elements;
          if (parsed.resolved_garnish) resolvedGarnish = parsed.resolved_garnish;
          if (parsed.resolved_beverage) resolvedBeverage = parsed.resolved_beverage;
        }
      }
    } catch (err) {
      console.warn("Input resolution fallback used:", err);
    }

    imagePrompt = isMealMode
      ? mealPhotoPrompt(resolvedDish, resolvedElements, resolvedGarnish, resolvedBeverage)
      : recipePhotoPrompt(resolvedDish, resolvedElements, resolvedGarnish);
  }

  // Step 3: Image Generation via Vercel AI Gateway
  // entity_id is a uuid: the meal or recipe, or the nil UUID for categories.
  await logger.start({
    type: "dish_photo",
    entityId: payload.meal_id || payload.recipe_id || '00000000-0000-0000-0000-000000000000',
    prompt: imagePrompt,
    model: imageModel,
  });

  try {
    const imageRes = await fetch(`${gatewayBaseUrl}/images/generations`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: imageModel,
        prompt: imagePrompt,
        n: 1,
        size: imageSizeFor(imageModel),
      }),
    });

    if (!imageRes.ok) {
      const errorText = await imageRes.text();
      console.error("AI Gateway image generation failed:", imageRes.status, errorText);
      await logger.failure(`AI Gateway error (${imageRes.status}): ${errorText}`);
      return new Response(
        JSON.stringify({ error: `Image generation error (${imageRes.status}): ${errorText}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const imageJson = await imageRes.json();
    const firstItem = imageJson.data?.[0];
    if (!firstItem) {
      await logger.failure("No image received from AI Gateway");
      return new Response(
        JSON.stringify({ error: "No image received from AI Gateway" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let b64Image: string;
    let imageBytes: Uint8Array;

    if (firstItem.b64_json) {
      b64Image = firstItem.b64_json;
      imageBytes = Uint8Array.from(atob(b64Image), (c) => c.charCodeAt(0));
    } else if (firstItem.url) {
      const fetchImg = await fetch(firstItem.url);
      const buffer = await fetchImg.arrayBuffer();
      imageBytes = new Uint8Array(buffer);
      // Spreading a ~1 MB image into String.fromCharCode overflows the stack.
      b64Image = encodeBase64(imageBytes);
    } else {
      await logger.failure("Invalid image format in response");
      return new Response(
        JSON.stringify({ error: "Invalid image format in response" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await logger.success("Image generated successfully");

    // Step 4: Storage Persistence
    let storagePath: string | null = null;
    const format = detectImageFormat(imageBytes);

    if (admin) {
      try {
        if (isCategoryMode) {
          const categoryName = payload.category || payload.cuisine || payload.name || "category";
          storagePath = await saveCategoryPhoto(admin, categoryName, imageBytes, format);
        } else if (isMealMode && payload.meal_id) {
          storagePath = await attachRowPhoto(admin, { bucket: "meal-photos", table: "meals", id: payload.meal_id }, imageBytes, format);
        } else if (payload.recipe_id) {
          storagePath = await attachRowPhoto(admin, { bucket: "recipe-photos", table: "dishes", id: payload.recipe_id }, imageBytes, format);
        }
      } catch (storageErr) {
        console.error("Storage persistence error:", storageErr);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        photo_path: storagePath,
        image_base64: b64Image,
        resolved_category: resolvedCategory,
        resolved_dishes: resolvedDishes,
        resolved_dish: resolvedDish,
        resolved_elements: resolvedElements,
        resolved_garnish: resolvedGarnish,
        resolved_beverage: resolvedBeverage,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to generate image:", err);
    await logger.failure(message);
    return new Response(
      JSON.stringify({ error: `Internal error: ${message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
