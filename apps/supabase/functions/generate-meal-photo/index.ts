// Edge function that generates the photograph of one meal using Vercel AI Gateway: the
// meal's recipe plated and laid for eating (cutlery, a napkin and a drink), in the shared
// setting from _shared/photos/prompts.ts. Saved to meal-photos and meals.photo_paths.
// Photos of recipes and categories are made by generate-recipe-photo.
// A text model first turns the meal's recipe into a food description and a drink.

import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";
import { resolveRecipeBrief, type RecipeBriefInput } from "../_shared/photos/briefs.ts";
import { authenticate, generateImage, jsonResponse } from "../_shared/photos/pipeline.ts";
import { detectImageFormat, mealPhotoPrompt } from "../_shared/photos/prompts.ts";
import { attachRowPhoto } from "../_shared/photos/storage.ts";

interface RequestPayload extends RecipeBriefInput {
  meal_id?: string;
}

Deno.serve(async (req) => {
  const gateway = authenticate(req);
  if (gateway instanceof Response) return gateway;

  let payload: RequestPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  if (!payload.meal_id) return jsonResponse({ error: "meal_id is required" }, 400);
  if (!payload.name && !payload.cuisine) {
    return jsonResponse({ error: "Recipe name or cuisine is required" }, 400);
  }

  const logger = GenerationLogger.fromEnv();
  const admin = logger.client;
  const textModel = await getFeatureModel(admin, "recipe-photo-brief", "text");
  const imageModel = await getFeatureModel(admin, "generate-meal-photo", "image");

  const brief = await resolveRecipeBrief(gateway, textModel, payload);
  const imagePrompt = mealPhotoPrompt(brief.dish, brief.elements, brief.garnish, brief.beverage);

  await logger.start({ type: "meal_photo", entityId: payload.meal_id, prompt: imagePrompt, model: imageModel });

  const image = await generateImage(gateway, logger, imageModel, imagePrompt);
  if (image instanceof Response) return image;

  let storagePath: string | null = null;
  if (admin) {
    try {
      storagePath = await attachRowPhoto(
        admin,
        { bucket: "meal-photos", table: "meals", id: payload.meal_id },
        image.bytes,
        detectImageFormat(image.bytes),
      );
    } catch (storageErr) {
      console.error("Storage persistence error:", storageErr);
    }
  }

  return jsonResponse({
    success: true,
    photo_path: storagePath,
    image_base64: image.base64,
    resolved_dish: brief.dish,
    resolved_elements: brief.elements,
    resolved_garnish: brief.garnish,
    resolved_beverage: brief.beverage,
  });
});
