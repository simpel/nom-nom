import { z } from "npm:zod";
import { GenerationLogger } from "../_shared/generation-logger.ts";
import { resolveTaxonomyTerm } from "../_shared/taxonomy-resolver.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";

// Edge function to parse recipes from photos using Vercel AI Gateway.
// Receives an array of base64 images and extracts structured recipe details.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ImageInput {
  data: string; // base64
  mime_type?: string;
}

interface RequestPayload {
  images: ImageInput[];
}

interface ParsedIngredient {
  quantity: string;
  measurement: string;
  ingredient: string;
}

interface HealthBreakdown {
  positives: string[];
  considerations: string[];
  cooking_impact: string;
}

interface ParsedRecipe {
  name: string;
  serves: number | null;
  cuisine: string | null;
  cuisine_id?: string | null;
  cooking_method?: string | null;
  cooking_method_id?: string | null;
  dish_kind?: string | null;
  dish_kind_id?: string | null;
  effort: number | null;
  ingredients: ParsedIngredient[];
  instructions: string[];
  health_score: number | null;
  health_verdict: string | null;
  health_rationale: string | null;
  health_breakdown: HealthBreakdown | null;
}

const SYSTEM_PROMPT = `Analyze the provided photo(s) of a recipe (which may span across multiple cookbook pages, recipe cards, or notes).
Extract the recipe into a single JSON object matching this schema:
{
  "name": "string (dish title)",
  "serves": integer or null (e.g. 4),
  "cuisine": "string or null - Identify the culinary tradition with a wide, canonical category (e.g. 'asian', 'mexican', 'italian', 'nordic', 'mediterranean', 'indian', 'middle_eastern', 'american', 'french', 'japanese', 'thai', 'korean', 'greek', 'spanish', 'chinese', 'vietnamese', 'moroccan'). Never use compound, crossover, or hyperspecific variants (e.g. use 'mexican', NEVER 'mexican crossover' or 'mexican/south american'). If no specific kitchen category clearly fits, set to null.",
  "cooking_method": "string or null - Primary cooking method (e.g. 'baking', 'grilling', 'slow_cooking', 'roasting', 'steaming', 'frying', 'sauteing', 'simmering', 'raw_cured', 'smoking'). If none clearly dominates, set to null.",
  "dish_kind": "string or null - The culinary format/kind of the dish (e.g. 'stew', 'casserole', 'soup', 'bbq', 'pasta', 'pizza', 'curry', 'salad', 'roast', 'stir_fry', 'sandwich', 'pie', 'tacos', 'risotto'). If ambiguous, set to null.",
  "effort": integer or null (1 for quick/simple <=30m, 2 for medium 30-60m, 3 for elaborate >60m),
  "ingredients": [
    {
      "quantity": "string (e.g. '500', '2', '1/2', or '' if none)",
      "measurement": "string (e.g. 'g', 'ml', 'tbsp', 'tsp', 'cups', 'pinch', or '' if none)",
      "ingredient": "string (e.g. 'all-purpose flour', 'garlic, minced')"
    }
  ],
  "instructions": [
    "string (step 1 without number prefix)",
    "string (step 2 without number prefix)"
  ],
  "health_score": integer (1-100 based on nutritional profiling of ingredients and cooking method),
  "health_verdict": "string (One of: 'Nutritious' for 80-100, 'Balanced' for 60-79, 'Moderate' for 40-59, 'Indulgent' for 1-39)",
  "health_rationale": "string (A crisp, concise 1-2 sentences strictly under 35 words explaining why the recipe earned this score number)",
  "health_breakdown": {
    "positives": ["string", "string"],
    "cooking_impact": "string (1 concise sentence on how the cooking method affected score)",
    "macros": {
      "calories": integer (estimated total kcal per serving),
      "protein_g": number (estimated grams of protein per serving),
      "carbs_g": number (estimated grams of carbohydrates per serving),
      "fat_g": number (estimated grams of fat per serving)
    }
  }
}

Classification Guidelines:
- Cuisine: Make wide umbrella picks. For example: soy sauce/ginger -> 'asian', oregano/feta/olive oil -> 'greek' or 'mediterranean', cumin/chili -> 'mexican', pasta/parmesan -> 'italian', dill/salmon -> 'nordic'. Do not invent crossover or hyphenated cuisines.
- Health Index: Score based on nutrient density (whole grains, vegetables, lean protein, healthy fats vs. high sodium, sugar, saturated fats) and cooking technique (fresh/steamed/baked vs. deep-fried/excess oil).
- Return ONLY valid JSON. No conversational intro or markdown outside JSON.`;

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

  let payload: RequestPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!payload.images || !Array.isArray(payload.images) || payload.images.length === 0) {
    return new Response(
      JSON.stringify({ error: "At least one image is required" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const logger = GenerationLogger.fromEnv();
  const admin = logger.client;
  const model = await getFeatureModel(admin, "parse-recipe");
  const gatewayBaseUrl =
    Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";

  const messageContent: Array<
    | { type: "text"; text: string }
    | { type: "image_url"; image_url: { url: string } }
  > = [{ type: "text", text: "Analyze the provided photo(s) and extract the recipe." }];

  for (const img of payload.images) {
    const mime = img.mime_type || "image/jpeg";
    messageContent.push({
      type: "image_url",
      image_url: {
        url: `data:${mime};base64,${img.data}`,
      },
    });
  }

  await logger.start({
    type: "recipe_parse",
    entityId: "00000000-0000-0000-0000-000000000000", // No specific entity yet
    prompt: `[${payload.images.length} image(s) provided]`,
    model,
  });

  try {
    const response = await fetch(`${gatewayBaseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: model,
        messages: [
          {
            role: "system",
            content: SYSTEM_PROMPT,
          },
          {
            role: "user",
            content: messageContent,
          },
        ],
        response_format: { type: "json_object" },
        temperature: 0.2,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("AI Gateway request failed:", response.status, errorText);
      await logger.failure(`AI Gateway error (${response.status}): ${errorText}`);
      return new Response(
        JSON.stringify({
          error: `AI Gateway error (${response.status}): ${errorText}`,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const completion = await response.json();
    const rawContent = completion.choices?.[0]?.message?.content;
    if (!rawContent) {
      await logger.failure("Empty response from AI Gateway");
      return new Response(
        JSON.stringify({ error: "Empty response from AI Gateway" }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Clean any accidental markdown code blocks
    let sanitizedJson = rawContent.trim();
    if (sanitizedJson.startsWith("```json")) {
      sanitizedJson = sanitizedJson.slice(7);
    }
    if (sanitizedJson.startsWith("```")) {
      sanitizedJson = sanitizedJson.slice(3);
    }
    if (sanitizedJson.endsWith("```")) {
      sanitizedJson = sanitizedJson.slice(0, -3);
    }
    sanitizedJson = sanitizedJson.trim();

    await logger.success(rawContent);

    let parsedData;
    try {
      parsedData = JSON.parse(sanitizedJson);
    } catch (e) {
      throw new Error('Response is not valid JSON');
    }

    const RecipeSchema = z.object({
      name: z.string(),
      serves: z.number().nullable().optional(),
      cuisine: z.string().nullable().optional(),
      cooking_method: z.string().nullable().optional(),
      dish_kind: z.string().nullable().optional(),
      effort: z.number().nullable().optional(),
      ingredients: z.array(z.object({
        quantity: z.string(),
        measurement: z.string(),
        ingredient: z.string()
      })).default([]),
      instructions: z.array(z.string()).default([]),
      health_score: z.number().nullable().optional(),
      health_verdict: z.string().nullable().optional(),
      health_rationale: z.string().nullable().optional(),
      health_breakdown: z.object({
        positives: z.array(z.string()),
        cooking_impact: z.string(),
        macros: z.object({
          calories: z.number(),
          protein_g: z.number(),
          carbs_g: z.number(),
          fat_g: z.number(),
        })
      }).nullable().optional()
    });

    const parsed: ParsedRecipe = RecipeSchema.parse(parsedData) as unknown as ParsedRecipe;

    // Validate enum boundaries securely
    if (parsed.health_score != null) {
      parsed.health_score = Math.max(1, Math.min(100, Math.round(parsed.health_score)));
    }
    if (
      parsed.health_verdict &&
      !["Nutritious", "Balanced", "Moderate", "Indulgent"].includes(parsed.health_verdict)
    ) {
      if (parsed.health_score != null) {
        if (parsed.health_score >= 80) parsed.health_verdict = "Nutritious";
        else if (parsed.health_score >= 60) parsed.health_verdict = "Balanced";
        else if (parsed.health_score >= 40) parsed.health_verdict = "Moderate";
        else parsed.health_verdict = "Indulgent";
      } else {
        parsed.health_verdict = null;
      }
    }

    const admin = logger.client;
    if (admin) {
      if (parsed.dish_kind) {
        try {
          const resolved = await resolveTaxonomyTerm({
            client: admin,
            dimension: "dish_kind",
            proposedTerm: parsed.dish_kind,
            apiKey,
            gatewayBaseUrl,
          });
          if (resolved) {
            parsed.dish_kind_id = resolved.id;
            parsed.dish_kind = resolved.name;
          }
        } catch (e) {
          console.warn("Failed to resolve dish_kind:", e);
        }
      }

      if (parsed.cooking_method) {
        try {
          const resolved = await resolveTaxonomyTerm({
            client: admin,
            dimension: "cooking_method",
            proposedTerm: parsed.cooking_method,
            apiKey,
            gatewayBaseUrl,
          });
          if (resolved) {
            parsed.cooking_method_id = resolved.id;
            parsed.cooking_method = resolved.name;
          }
        } catch (e) {
          console.warn("Failed to resolve cooking_method:", e);
        }
      }

      if (parsed.cuisine) {
        try {
          const resolved = await resolveTaxonomyTerm({
            client: admin,
            dimension: "cuisine",
            proposedTerm: parsed.cuisine,
            apiKey,
            gatewayBaseUrl,
          });
          if (resolved) {
            parsed.cuisine_id = resolved.id;
            parsed.cuisine = resolved.slug;
          }
        } catch (e) {
          console.warn("Failed to resolve cuisine:", e);
        }
      }
    }

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to parse recipe:", err);
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
