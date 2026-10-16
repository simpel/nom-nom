// Edge function that generates editorial photographs of recipes (and category covers) using
// Vercel AI Gateway, in two modes that share one setting (oak table, overhead camera,
// daylight; see _shared/photos/prompts.ts):
// - recipe:   the plate alone, saved to recipe-photos and recipes.photo_paths (recipe_id)
// - category: a spread of the category's signature dishes, saved to category-photos
// Photos of meals are made by generate-meal-photo.
// A text model first turns the input into a food description.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";
import { resolveCategoryBrief, resolveRecipeBrief, type RecipeBriefInput } from "../_shared/photos/briefs.ts";
import { authenticate, generateImage, jsonResponse } from "../_shared/photos/pipeline.ts";
import { categoryPhotoPrompt, detectImageFormat, recipePhotoPrompt } from "../_shared/photos/prompts.ts";
import { attachRowPhoto, saveCategoryPhoto } from "../_shared/photos/storage.ts";

interface RequestPayload extends RecipeBriefInput {
  mode?: "recipe" | "category";
  recipe_id?: string;
  /** The recipe's first photo when the app asked; the photo is attached only if it is still first. */
  expected_cover?: string | null;
  category?: string;
}

const NIL_UUID = "00000000-0000-0000-0000-000000000000";

/** Null when the caller owns the recipe and has Pro; otherwise the response to send. */
async function checkRecipeAccess(
  req: Request,
  admin: SupabaseClient | null,
  recipeId: string | undefined,
): Promise<Response | null> {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!admin || !url || !anonKey) return jsonResponse({ error: "Server is not configured" }, 500);
  if (!recipeId) return jsonResponse({ error: "recipe_id is required" }, 400);

  // Who is asking: resolved from the JWT, never from the body.
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return jsonResponse({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  // Postgres returns uuids lower case; iOS sends them upper case.
  const { data: recipe } = await admin
    .from("recipes").select("owner_id").eq("id", recipeId.toLowerCase()).maybeSingle();
  if (!recipe) return jsonResponse({ error: "Recipe not found" }, 404);
  if (recipe.owner_id !== userId) return jsonResponse({ error: "Only the recipe's owner can add photos" }, 403);

  const { data: pro } = await admin.rpc("has_pro", { p_user_id: userId });
  if (pro !== true) return jsonResponse({ error: "Nom Nom Pro required" }, 402);
  return null;
}

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

  // A person asking for a recipe photo (not the categories webhook) must own the
  // recipe and have Nom Nom Pro.
  if (!isCategoryMode && !req.headers.get("x-webhook-secret")) {
    const denied = await checkRecipeAccess(req, admin, payload.recipe_id);
    if (denied) return denied;
  }
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
        // A photo the person added while this ran wins over the generated one.
        storagePath = await attachRowPhoto(
          admin,
          { bucket: "recipe-photos", table: "recipes", id: payload.recipe_id },
          image.bytes,
          format,
          { expectedCover: payload.expected_cover },
        );
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
