// Edge function to analyze recipe health index and rationale using Vercel AI Gateway.
// Evaluates ingredients and cooking methods using validated nutritional profiling principles (Food Compass / Healthy Cooking Index).

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface IngredientInput {
  quantity?: string;
  measurement?: string;
  ingredient: string;
}

interface RequestPayload {
  name: string;
  ingredients: IngredientInput[];
  instructions: string[];
}

interface HealthBreakdown {
  positives: string[];
  considerations: string[];
  cooking_impact: string;
}

interface HealthAnalysisResult {
  health_score: number;
  health_verdict: string;
  health_rationale: string;
  health_breakdown: HealthBreakdown;
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

  if (!payload.name || !payload.ingredients || payload.ingredients.length === 0) {
    return new Response(
      JSON.stringify({ error: "Recipe name and ingredients are required" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const model = Deno.env.get("AI_GATEWAY_MODEL") || "google/gemini-2.5-flash";
  const gatewayBaseUrl =
    Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";

  const ingredientsList = payload.ingredients
    .map((ing) => {
      const amt = [ing.quantity, ing.measurement].filter(Boolean).join(" ");
      return amt ? `${amt} ${ing.ingredient}` : ing.ingredient;
    })
    .join("\n- ");

  const instructionsList = (payload.instructions || []).join("\n1. ");

  const promptText = `You are an expert nutritional scientist and recipe profiler.
Evaluate the healthiness of this recipe based on validated nutritional profiling principles (such as Tufts Food Compass, Nutri-Score, and Healthy Cooking Index).

Recipe Name: ${payload.name}

Ingredients:
- ${ingredientsList}

Cooking Instructions:
1. ${instructionsList || "No specific instructions provided."}

Assessment Framework:
1. Ingredients Assessment:
   - Positive points (+): Whole vegetables, leafy greens, legumes, whole grains, lean proteins (poultry, fish, tofu), healthy fats (olive/rapeseed oil, nuts, seeds), high fiber, antioxidant herbs & spices.
   - Negative points (-): High saturated fats (butter, heavy cream, fatty processed meats), refined sugars/syrups, high sodium/salt, ultra-processed items.
2. Cooking Method Impact:
   - Beneficial (+): Raw/fresh, steaming, light grilling, baking, gentle boiling/poaching, light sautéing.
   - Detrimental (-): Deep-frying, heavy pan-frying in excess fat, deep charring/burning, prolonged boiling that leaches micronutrients.
   Example: Lean chicken steamed or baked scores much higher than deep-fried chicken.

Score Scale (1 to 100):
- 80-100: "Nutritious" (High nutrient density, whole foods, minimal unhealthy fats/sugar)
- 60-79: "Balanced" (Good everyday meal, well-rounded macronutrients)
- 40-59: "Moderate" (Enjoyable, but higher in sodium, refined carbs, or calories)
- 1-39: "Indulgent" (Rich comfort food, treat, or deep-fried / high-sugar meal)

Return a single JSON object matching this schema:
{
  "health_score": integer (1-100),
  "health_verdict": "string (One of: 'Nutritious', 'Balanced', 'Moderate', 'Indulgent')",
  "health_rationale": "string (A concise 2-3 sentence overview explaining how the ingredients and cooking methods produced this score)",
  "health_breakdown": {
    "positives": ["string (key nutritional strength)", "string (key nutritional strength)"],
    "considerations": ["string (point to note or moderate, e.g. sodium/fat)"],
    "cooking_impact": "string (1-2 sentences on how the cooking/prep method helped or hurt the nutritional value)"
  }
}

Return ONLY valid JSON without conversational text or markdown code fence blocks outside JSON.`;

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
            content: promptText,
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

    const parsed: HealthAnalysisResult = JSON.parse(sanitizedJson);

    // Validate score bounds
    parsed.health_score = Math.max(1, Math.min(100, Math.round(parsed.health_score)));
    if (!["Nutritious", "Balanced", "Moderate", "Indulgent"].includes(parsed.health_verdict)) {
      if (parsed.health_score >= 80) parsed.health_verdict = "Nutritious";
      else if (parsed.health_score >= 60) parsed.health_verdict = "Balanced";
      else if (parsed.health_score >= 40) parsed.health_verdict = "Moderate";
      else parsed.health_verdict = "Indulgent";
    }

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to analyze recipe health:", err);
    return new Response(
      JSON.stringify({ error: `Internal error: ${message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
