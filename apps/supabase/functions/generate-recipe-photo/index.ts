// Edge function that generates editorial photographs of recipes (and category covers) using
// Vercel AI Gateway, in two modes that share one setting (oak table, overhead camera,
// daylight; see _shared/photos/prompts.ts):
// - recipe:   the plate alone, saved to recipe-photos and recipes.photo_paths (recipe_id)
// - category: a spread of the category's signature dishes, saved to category-photos
// Photos of meals are made by generate-meal-photo.
// A text model first turns the input into a food description.

import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";
import { resolveCategoryBrief, resolveRecipeBrief, type RecipeBriefInput } from "../_shared/photos/briefs.ts";
import { authenticate, generateImage, jsonResponse } from "../_shared/photos/pipeline.ts";
import { categoryPhotoPrompt, detectImageFormat, recipePhotoPrompt } from "../_shared/photos/prompts.ts";
import { attachRowPhoto, saveCategoryPhoto } from "../_shared/photos/storage.ts";

interface RequestPayload extends RecipeBriefInput {
  mode?: "recipe" | "category";
  recipe_id?: string;
  category?: string;
}

const NIL_UUID = "00000000-0000-0000-0000-000000000000";

Deno.serve(async (req) => {
  const gateway = authenticate(req);
  if (gateway instanceof Response) return gateway;

  let payload: RequestPayload & { record?: Record<string, any>; table?: string };
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  // Handle Supabase Database Webhook payloads from triggers
  if (payload.record && (payload.table === "categories" || payload.record.slug || payload.record.name)) {
    const rec = payload.record;
    payload = { mode: "category", category: rec.name || rec.slug };
  }

  const isCategoryMode = payload.mode === "category" || (Boolean(payload.category) && !payload.recipe_id && !payload.name);

  if (!isCategoryMode && !payload.name && !payload.cuisine) {
    return jsonResponse({ error: "Recipe name or cuisine is required" }, 400);
  }
  if (isCategoryMode && !payload.category && !payload.cuisine && !payload.name) {
    return jsonResponse({ error: "Category or cuisine name is required" }, 400);
  }

  const logger = GenerationLogger.fromEnv();
  const admin = logger.client;
  const textModel = await getFeatureModel(admin, "recipe-photo-brief", "text");
  const imageModel = await getFeatureModel(admin, "generate-recipe-photo", "image");

  const categoryName = (payload.category || payload.cuisine || payload.name || "Global Cuisine").trim();
  const categoryBrief = isCategoryMode ? await resolveCategoryBrief(gateway, textModel, categoryName) : undefined;
  const recipeBrief = isCategoryMode ? undefined : await resolveRecipeBrief(gateway, textModel, payload);

  const imagePrompt = categoryBrief
    ? categoryPhotoPrompt(categoryBrief.category, categoryBrief.dishes, categoryBrief.vessels)
    : recipePhotoPrompt(recipeBrief!.dish, recipeBrief!.elements, recipeBrief!.garnish);

  // entity_id is a uuid: the recipe, or the nil UUID for categories.
  await logger.start({
    type: "recipe_photo",
    entityId: payload.recipe_id || NIL_UUID,
    prompt: imagePrompt,
    model: imageModel,
  });

  const image = await generateImage(gateway, logger, imageModel, imagePrompt);
  if (image instanceof Response) return image;

  let storagePath: string | null = null;
  const format = detectImageFormat(image.bytes);
  if (admin) {
    try {
      if (isCategoryMode) {
        storagePath = await saveCategoryPhoto(admin, categoryName, image.bytes, format);
      } else if (payload.recipe_id) {
        storagePath = await attachRowPhoto(admin, { bucket: "recipe-photos", table: "recipes", id: payload.recipe_id }, image.bytes, format);
      }
    } catch (storageErr) {
      console.error("Storage persistence error:", storageErr);
    }
  }

  return jsonResponse({
    success: true,
    photo_path: storagePath,
    image_base64: image.base64,
    resolved_category: categoryBrief?.category,
    resolved_dishes: categoryBrief?.dishes,
    resolved_dish: recipeBrief?.dish,
    resolved_elements: recipeBrief?.elements,
    resolved_garnish: recipeBrief?.garnish,
  });
});
