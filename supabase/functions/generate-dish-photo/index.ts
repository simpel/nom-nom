// Edge function to generate editorial recipe and category photographs using Vercel AI Gateway.
// Resolves dish elements and garnish for single recipes, or multi-dish spreads for categories/kitchens,
// adhering strictly to matching stoneware coupe plates and seamless oak surface specifications.

import { createClient } from "jsr:@supabase/supabase-js@2";

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
  mode?: "recipe" | "category";
  recipe_id?: string;
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
}

interface CategoryResolutionResult {
  resolved_category: string;
  resolved_dishes: string;
  vessels_narrative?: string;
}

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
    Deno.env.get("VERCEL_AI_GATEWAY_TOKEN") ||
    Deno.env.get("OPENAI_API_KEY") ||
    Deno.env.get("GEMINI_API_KEY");

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

  const gatewayBaseUrl =
    Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";
  const textModel =
    Deno.env.get("AI_GATEWAY_TEXT_MODEL") || "google/gemini-2.5-flash";
  const imageModel =
    Deno.env.get("AI_IMAGE_MODEL") || "bfl/flux-2-pro";

  let imagePrompt: string;
  let resolvedCategory: string | undefined;
  let resolvedDishes: string | undefined;
  let resolvedDish: string | undefined;
  let resolvedElements: string | undefined;
  let resolvedGarnish: string | undefined;

  if (isCategoryMode) {
    // =========================================================================
    // CATEGORY / KITCHEN MODE: Curated spread of 3-4 dishes on matching plates
    // =========================================================================
    const categoryName = (payload.category || payload.cuisine || payload.name || "Global Cuisine").trim();

    let vesselsNarrative: string | undefined;

    const categoryResolutionPrompt = `You are an expert culinary director and food photographer art director.
Analyze the culinary category / kitchen:
Category: ${categoryName}

Rules:
1. Category Spread: Select 3 to 4 iconic, visually complementary dishes representing the authentic culinary tradition of this kitchen/category.
2. Distinct Textures & Garnishes: Each dish should feature distinct textured components (e.g. braised, roasted, fresh, sauced) and classic culinary garnishes.
3. Category-Specific Traditional Vessels: If this culinary category has traditional, iconic plates or serving vessels strongly associated with its heritage (for example: a shallow rustic terracotta cazuela in Mexican or Spanish cuisine, a dark textured Japanese ceramic yakimono or tenmoku plate, an Indian hammered brass/earthenware handi, a Korean stone ttukbaegi bowl, or a French enameled cast-iron gratin dish), replace 1 or 2 of the plates in the picture with these authentic traditional vessels to better portray the category. The remaining dishes should stay on round stoneware coupe plates. If no unique traditional vessel is customary, use matching stoneware coupe plates throughout.
4. Strict Exclusion Rules: No Cutlery or Utensils (no forks, knives, spoons, chopsticks, skewers). No Table Props (no glasses, cups, napkins, ramekins, side bowls, condiment bottles, placemats). Never Render Empty Plates: every plate or vessel in the spread must be filled with food — no bare, unfilled, or empty dishware anywhere in frame.
5. Identify:
   - resolved_category: Canonical display name of the kitchen/category (e.g. "${categoryName} Kitchen").
   - resolved_dishes: A descriptive narrative detailing the 3 to 4 dishes plated across the spread, explicitly specifying the plate or vessel each dish is served on (e.g. "a central round stoneware coupe plate of slow-braised cochinita pibil; a second dish of charred street-style elote served in an authentic shallow rustic Mexican terracotta cazuela; and a third coupe plate of fresh citrus ceviche").
   - vessels_narrative: Concise summary of the plating vessels (e.g. "two round stoneware coupe plates and one traditional rustic Mexican terracotta cazuela").

Return ONLY valid JSON matching:
{
  "resolved_category": "string",
  "resolved_dishes": "string",
  "vessels_narrative": "string"
}`;

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
          messages: [{ role: "user", content: categoryResolutionPrompt }],
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

    const platingContext = vesselsNarrative
      ? `The dishes are plated across ${vesselsNarrative}, harmoniously paired with round stoneware coupe plates (20–28cm in diameter) with shallow curved wells (~1.5–2cm deep) and low uniform raised rims (~1.5–2cm wide) with subtly hand-thrown edge profiles in a matte beige/off-white glaze with fine brown-to-charcoal reactive speckles, where 1 or 2 plates are replaced by authentic traditional serving vessels deeply characteristic of ${resolvedCategory} (such as rustic earthenware, terracotta cazuela, or textured artisan ceramic)`
      : `Each dish is neatly plated on round stoneware coupe plates of varying sizes (20–28cm in diameter) with shallow curved wells (~1.5–2cm deep) and low uniform raised rims (~1.5–2cm wide) with subtly hand-thrown edge profiles — matte beige/off-white glaze with fine brown-to-charcoal reactive speckles, where 1 or 2 plates may be replaced by authentic traditional serving vessels deeply characteristic of ${resolvedCategory}`;

    imagePrompt = `Directly overhead bird's-eye food photograph, camera mounted on an overhead rig pointing straight down at the tabletop at exactly 90 degrees — a perfect right angle straight down (true top-down flat-lay perspective, like looking down through the ceiling) — absolutely NOT eye-level, NOT a low angle, NOT a 3/4 angle, NOT a front-on or side-on view; the viewer sees the tops of the plates as full circles/ovals with no vertical rim walls visible on the near side. A professional editorial food photograph showcasing the essence of ${resolvedCategory}, featuring a curated spread of ${resolvedDishes}. ${platingContext}. All vessels sit harmoniously arranged together on a single continuous, seamless slab of natural oak — one uninterrupted pale warm honey-beige wood surface — a consistent light tan/blonde oak color, exactly like fresh natural European white oak flooring; the color must NEVER shift toward dark, reddish, orange, amber, walnut, or rustic-distressed tones, and must show zero visible knots, zero dark mineral streaks, and zero patchy color variation anywhere on the surface — with absolutely no plank boards, no joints, no seams, no grooves, and no gaps anywhere; the grain of the wood runs perfectly horizontal, parallel to the bottom edge of the frame, flowing left-to-right — the grain lines must never point toward or away from the camera, must never run vertically (top-to-bottom), and must never run diagonally; fine, flat, straight-to-gently-wavy grain lines flowing horizontally from left to right only, with no change in surface height and no shadow lines suggesting a board edge, like one solid sanded panel. Finish is raw/lightly-oiled matte — no gloss, scratches, stains, or props. The seamless oak wood tabletop completely fills the entire background of the frame from edge to edge with no table edges, no room, no walls, no windows, no curtains, and no horizon line visible anywhere — strictly wood surface and plates only. Shot straight down from directly overhead (true top-down bird's-eye view, camera parallel to the tabletop), cohesive multi-plate spread composition occupying 75% of the frame with clean wood negative space around it; every plate and vessel must be fully contained within the frame with a clear margin of wood on all sides — no plate or vessel may touch, overlap, extend past, or be cropped by any edge of the frame. A single large, heavily diffused natural daylight source enters from the upper-left at roughly a 45-degree angle (off-frame diffused daylight, no visible light source, no visible window, no curtains) — broad and wraparound, with shadow edges that fade gradually rather than cutting a hard line, and shadows that stay open and detailed, never going fully black. Exposure is medium-bright and evenly balanced, with no clipped white highlights and no crushed blacks; neutral-to-warm color temperature, no artificial color cast. This creates gentle, low-intensity specular highlights on glossy or oiled surfaces and smooth, soft tonal falloff on matte surfaces, with soft-edged, low-to-medium contrast contact shadows falling diagonally to the lower-right of each vessel and food element. No backlight, no top light, no fill light, no rim light, no spotlighting, no harsh direct sun, no hard-edged shadows, no blown highlights, no crushed shadows. Critical sharp focus on food surface textures, shallow depth of field softly blurring the background wood into clean negative space. Minimalist food styling, absolutely no cutlery, no forks, no knives, no spoons, no chopsticks, no napkins, no glasses, no side bowls, curated dish vessels on wood only. Every plate and vessel in the spread must be generously filled with food — never render an empty, bare, or unfilled plate or vessel anywhere in frame. --ar 1:1 --no cutlery, forks, knives, spoons, chopsticks, napkins, glassware, cups, bottles, wood seams, plank lines, grooves, panel joints, vertical wood grain, vertical grain, diagonal wood grain, table edges, walls, windows, curtains, room, background furniture, empty plate, empty plates, bare plate, unfilled plate, empty vessel, empty bowl, eye-level angle, eye level shot, low angle, front-on angle, side view, straight-on angle, 3/4 angle, oblique angle, dark wood, reddish wood, orange wood, amber wood, walnut, rustic wood, distressed wood, weathered wood, wood knots, mineral streaks, uneven wood color, patchy wood color, cropped plate, plate cut off, plate touching frame edge, plate extending past frame, plate bleeding off edge --style raw --v 6.1`;

  } else {
    // =========================================================================
    // RECIPE MODE: Single serving on exactly one centered plate
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

    const resolutionPrompt = `You are an expert culinary food stylist and photography art director.
Analyze the following recipe details:
Recipe Name: ${payload.name || "Untitled Dish"}
Cuisine: ${payload.cuisine || "Unspecified"}
Ingredients: ${ingredientsList || "None specified"}
Cooking Method / Instructions: ${instructionsList || "None specified"}

Rules:
1. Input Resolution: If only dish or cuisine is provided, automatically select an iconic, visually distinct dish with 2–3 textured components and a classic garnish.
2. Strict Exclusion Rules: No Cutlery or Utensils (no forks, knives, spoons, chopsticks, skewers). No Table Props (no glasses, cups, napkins, ramekins, side bowls, condiment bottles, placemats). Single Subject Only (exactly one centered plate containing one dish). Never Render Empty Plates: the plate must be filled with food — never a bare, unfilled, or empty plate.
3. Identify:
   - resolved_dish: Name of the dish (e.g. "Crispy Pan-Seared Salmon").
   - resolved_elements: 2 to 3 textured components reflecting the ingredients and cooking method (e.g. "a golden seared salmon fillet with flaky layers, accompanied by charred tender asparagus spears and silky parsnip puree").
   - resolved_garnish: Classic culinary garnish (e.g. "a delicate drizzle of extra virgin olive oil and micro-chives").

Return ONLY valid JSON matching:
{
  "resolved_dish": "string",
  "resolved_elements": "string",
  "resolved_garnish": "string"
}`;

    resolvedDish = payload.name || "Gourmet Dish";
    resolvedElements = "succulent main dish with complementary roasted textures";
    resolvedGarnish = "a delicate garnish of fresh microgreens";

    try {
      const textRes = await fetch(`${gatewayBaseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: textModel,
          messages: [{ role: "user", content: resolutionPrompt }],
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
        }
      }
    } catch (err) {
      console.warn("Input resolution fallback used:", err);
    }

    imagePrompt = `Directly overhead bird's-eye food photograph, camera mounted on an overhead rig pointing straight down at the tabletop at exactly 90 degrees — a perfect right angle straight down (true top-down flat-lay perspective, like looking down through the ceiling) — absolutely NOT eye-level, NOT a low angle, NOT a 3/4 angle, NOT a front-on or side-on view; the viewer sees the top of the plate as a full circle with no vertical rim wall visible on the near side. A professional editorial food photograph of a single serving of ${resolvedDish}, featuring ${resolvedElements}, garnished with ${resolvedGarnish}. Neatly plated in the center of exactly one round stoneware coupe plate, 27–28cm in diameter, with a shallow curved well (~1.5–2cm deep) and a low uniform raised rim (~1.5–2cm wide) with a subtly hand-thrown edge profile — matte beige/off-white glaze with fine brown-to-charcoal reactive speckles, denser near the rim, no pattern or glossy sheen. The plate sits completely isolated on a single continuous, seamless slab of natural oak — one uninterrupted pale warm honey-beige wood surface — a consistent light tan/blonde oak color, exactly like fresh natural European white oak flooring; the color must NEVER shift toward dark, reddish, orange, amber, walnut, or rustic-distressed tones, and must show zero visible knots, zero dark mineral streaks, and zero patchy color variation anywhere on the surface — with absolutely no plank boards, no joints, no seams, no grooves, and no gaps anywhere; the grain of the wood runs perfectly horizontal, parallel to the bottom edge of the frame, flowing left-to-right — the grain lines must never point toward or away from the camera, must never run vertically (top-to-bottom), and must never run diagonally; fine, flat, straight-to-gently-wavy grain lines flowing horizontally from left to right only, with no change in surface height and no shadow lines suggesting a board edge, like one solid sanded panel. Finish is raw/lightly-oiled matte — no gloss, scratches, stains, or props. The seamless oak wood tabletop completely fills the entire background of the frame from edge to edge with no table edges, no room, no walls, no windows, no curtains, and no horizon line visible anywhere — strictly wood surface and plate only. Shot straight down from directly overhead (true top-down bird's-eye view, camera parallel to the tabletop), centered single-plate composition occupying 75% of the frame, surrounded by clean wood negative space; the entire plate must be fully contained within the frame with a clear margin of wood on all sides — it must not touch, extend past, or be cropped by any edge of the frame. A single large, heavily diffused natural daylight source enters from the upper-left at roughly a 45-degree angle (off-frame diffused daylight, no visible light source, no visible window, no curtains) — broad and wraparound, with shadow edges that fade gradually rather than cutting a hard line, and shadows that stay open and detailed, never going fully black. Exposure is medium-bright and evenly balanced, with no clipped white highlights and no crushed blacks; neutral-to-warm color temperature, no artificial color cast. This creates gentle, low-intensity specular highlights on glossy or oiled surfaces and smooth, soft tonal falloff on matte surfaces, with soft-edged, low-to-medium contrast contact shadows falling diagonally to the lower-right of the food and plate rim. No backlight, no top light, no fill light, no rim light, no spotlighting, no harsh direct sun, no hard-edged shadows, no blown highlights, no crushed shadows. Critical sharp focus on food surface textures, shallow depth of field softly blurring the background wood into clean negative space. Minimalist food styling, absolutely no cutlery, no forks, no knives, no spoons, no chopsticks, no napkins, no glasses, no side bowls, isolated plate only. The plate must be generously filled with food — never render an empty, bare, or unfilled plate. --ar 1:1 --no cutlery, forks, knives, spoons, chopsticks, napkins, glassware, multiple plates, side bowls, wood seams, plank lines, grooves, panel joints, vertical wood grain, vertical grain, diagonal wood grain, table edges, walls, windows, curtains, room, background furniture, empty plate, empty plates, bare plate, unfilled plate, eye-level angle, eye level shot, low angle, front-on angle, side view, straight-on angle, 3/4 angle, oblique angle, dark wood, reddish wood, orange wood, amber wood, walnut, rustic wood, distressed wood, weathered wood, wood knots, mineral streaks, uneven wood color, patchy wood color, cropped plate, plate cut off, plate touching frame edge, plate extending past frame, plate bleeding off edge --style raw --v 6.1`;
  }

  // Step 3: Image Generation via Vercel AI Gateway
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
        size: "1024x1024",
      }),
    });

    if (!imageRes.ok) {
      const errorText = await imageRes.text();
      console.error("AI Gateway image generation failed:", imageRes.status, errorText);
      return new Response(
        JSON.stringify({ error: `Image generation error (${imageRes.status}): ${errorText}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const imageJson = await imageRes.json();
    const firstItem = imageJson.data?.[0];
    if (!firstItem) {
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
      b64Image = btoa(String.fromCharCode(...imageBytes));
    } else {
      return new Response(
        JSON.stringify({ error: "Invalid image format in response" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 4: Storage Persistence
    let storagePath: string | null = null;
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (supabaseUrl && supabaseServiceKey) {
      try {
        const admin = createClient(supabaseUrl, supabaseServiceKey);

        if (isCategoryMode) {
          const categorySlug = (payload.category || payload.cuisine || payload.name || "category")
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "");
          const targetPath = `${categorySlug}.jpg`;

          const { error: uploadErr } = await admin.storage
            .from("category-photos")
            .upload(targetPath, imageBytes, {
              contentType: "image/jpeg",
              upsert: true,
            });

          if (uploadErr) {
            console.error("Failed to upload category image to storage:", uploadErr);
          } else {
            storagePath = targetPath;
            console.log(`Successfully persisted category photo to ${targetPath}`);

            const categoryName = (payload.category || payload.cuisine || payload.name || categorySlug).trim();
            const { error: dbErr } = await admin
              .from("categories")
              .upsert(
                {
                  slug: categorySlug,
                  name: categoryName,
                  photo_path: targetPath,
                  updated_at: new Date().toISOString(),
                },
                { onConflict: "slug" }
              );

            if (dbErr) {
              console.error("Failed to update categories table:", dbErr);
            } else {
              console.log(`Successfully updated categories table for ${categorySlug}`);
            }
          }
        } else if (payload.recipe_id) {
          const photoUUID = crypto.randomUUID().toLowerCase();
          const targetPath = `${payload.recipe_id.toLowerCase()}/${photoUUID}.jpg`;

          const { error: uploadErr } = await admin.storage
            .from("recipe-photos")
            .upload(targetPath, imageBytes, {
              contentType: "image/jpeg",
              upsert: true,
            });

          if (uploadErr) {
            console.error("Failed to upload image to storage:", uploadErr);
          } else {
            storagePath = targetPath;

            const { data: currentDish } = await admin
              .from("dishes")
              .select("photo_paths")
              .eq("id", payload.recipe_id)
              .single();

            const existingPaths: string[] = currentDish?.photo_paths || [];
            const updatedPaths = existingPaths.includes(targetPath)
              ? existingPaths
              : [targetPath, ...existingPaths];

            const { error: dbErr } = await admin
              .from("dishes")
              .update({ photo_paths: updatedPaths })
              .eq("id", payload.recipe_id);

            if (dbErr) {
              console.error("Failed to update dishes table with generated photo path:", dbErr);
            } else {
              console.log(`Successfully attached generated photo to dish ${payload.recipe_id}`);
            }
          }
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
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to generate image:", err);
    return new Response(
      JSON.stringify({ error: `Internal error: ${message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
