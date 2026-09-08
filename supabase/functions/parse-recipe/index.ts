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
  effort: number | null;
  tags: string[];
  ingredients: ParsedIngredient[];
  instructions: string[];
  health_score: number | null;
  health_verdict: string | null;
  health_rationale: string | null;
  health_breakdown: HealthBreakdown | null;
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

  const model = Deno.env.get("AI_GATEWAY_MODEL") || "google/gemini-2.5-flash";
  const gatewayBaseUrl =
    Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";

  const promptText = `Analyze the provided photo(s) of a recipe (which may span across multiple cookbook pages, recipe cards, or notes).
Extract the recipe into a single JSON object matching this schema:
{
  "name": "string (dish title)",
  "serves": integer or null (e.g. 4),
  "cuisine": "string or null - One of: 'asian', 'mexican', 'italian', 'nordic', 'mediterranean', 'indian', 'middle_eastern', 'american', 'french', 'japanese', 'thai', 'korean', 'greek', 'spanish'. If no specific kitchen category clearly fits, set to null.",
  "effort": integer or null (1 for quick/simple <=30m, 2 for medium 30-60m, 3 for elaborate >60m),
  "tags": ["string", "string"],
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
- Cuisine: Identify culinary tradition (soy sauce/ginger -> 'asian', oregano/feta/olive oil -> 'greek'/'mediterranean', cumin/chili -> 'mexican', pasta/parmesan -> 'italian', dill/salmon -> 'nordic'). Leave null if general.
- Health Index: Score based on nutrient density (whole grains, vegetables, lean protein, healthy fats vs. high sodium, sugar, saturated fats) and cooking technique (fresh/steamed/baked vs. deep-fried/excess oil).
- Return ONLY valid JSON. No conversational intro or markdown outside JSON.`;

  const messageContent: Array<
    | { type: "text"; text: string }
    | { type: "image_url"; image_url: { url: string } }
  > = [{ type: "text", text: promptText }];

  for (const img of payload.images) {
    const mime = img.mime_type || "image/jpeg";
    messageContent.push({
      type: "image_url",
      image_url: {
        url: `data:${mime};base64,${img.data}`,
      },
    });
  }

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

    const parsed: ParsedRecipe = JSON.parse(sanitizedJson);

    // Normalize cuisine to standard app keys or null if ambiguous
    const validCuisines = new Set([
      "asian", "mexican", "italian", "nordic", "mediterranean",
      "indian", "middle_eastern", "american", "french", "japanese",
      "thai", "korean", "greek", "spanish"
    ]);

    let normalizedCuisine: string | null = null;
    if (parsed.cuisine) {
      const clean = parsed.cuisine.trim().toLowerCase().replace("-", "_").replace(" ", "_");
      if (validCuisines.has(clean)) {
        normalizedCuisine = clean;
      } else if (clean.includes("middle") || clean.includes("arab") || clean.includes("leban")) {
        normalizedCuisine = "middle_eastern";
      } else if (clean.includes("asia") || clean.includes("orient")) {
        normalizedCuisine = "asian";
      } else if (clean.includes("mediter")) {
        normalizedCuisine = "mediterranean";
      } else if (clean.includes("scandi") || clean.includes("swed")) {
        normalizedCuisine = "nordic";
      }
    }
    parsed.cuisine = normalizedCuisine;

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to parse recipe:", err);
    return new Response(
      JSON.stringify({ error: `Internal error: ${message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
