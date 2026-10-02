// Edge function for cook mode: for each instruction step, how many minutes it waits
// on (a timer, or null) and which of the recipe's ingredients it uses.
//
// Input:  { recipe_id?, name, ingredients: [{quantity, measurement, ingredient}], instructions: [string] }
// Output: { steps: [{ minutes: number | null, ingredients: number[] }] }  (one per instruction,
//          ingredients as indexes into the input array)

import { z } from "npm:zod";
import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";

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
  recipe_id?: string;
  name: string;
  ingredients: IngredientInput[];
  instructions: string[];
}

const SYSTEM_PROMPT = `You prepare recipes for a step-by-step cook mode.

For every numbered instruction step, return:
- "minutes": the time the cook waits on in that step (roasting, simmering, resting, marinating, boiling pasta). An integer, or null when the step is hands-on with no wait. Use the time the step states; if it gives a range, use the upper bound; if it says "until golden" with no time, estimate a typical integer.
- "ingredients": the indexes (0-based, from the numbered ingredient list) of the ingredients first added or used in that step. An ingredient may appear in more than one step only if it is split across them (e.g. oil used twice). Never invent indexes.

Return exactly one entry per instruction step, in order, as:
{ "steps": [ { "minutes": 20, "ingredients": [0, 4] }, { "minutes": null, "ingredients": [] } ] }

Return ONLY valid JSON.`;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const apiKey =
    Deno.env.get("VERCEL_AI_GATEWAY") ||
    Deno.env.get("VERCEL_AI_GATEWAY_KEY") ||
    Deno.env.get("AI_GATEWAY_API_KEY") ||
    Deno.env.get("VERCEL_AI_GATEWAY_TOKEN");
  if (!apiKey) return json({ error: "AI Gateway API key is not configured" }, 500);

  let payload: RequestPayload;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  const instructions = (payload.instructions || []).map((s) => s.trim()).filter(Boolean);
  if (!payload.name || instructions.length === 0) {
    return json({ error: "Recipe name and instructions are required" }, 400);
  }
  const ingredients = payload.ingredients || [];

  const logger = GenerationLogger.fromEnv();
  const model = await getFeatureModel(logger.client, "analyze-recipe-steps");
  const gatewayBaseUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";

  const ingredientList = ingredients
    .map((ing, i) => {
      const amount = [ing.quantity, ing.measurement].filter(Boolean).join(" ");
      return `${i}. ${amount ? `${amount} ` : ""}${ing.ingredient}`;
    })
    .join("\n");
  const stepList = instructions.map((s, i) => `${i + 1}. ${s}`).join("\n");
  const userMessage = `Recipe: ${payload.name}

Ingredients:
${ingredientList || "(none listed)"}

Steps:
${stepList}`;

  if (payload.recipe_id) {
    await logger.start({ type: "recipe_steps", entityId: payload.recipe_id, prompt: userMessage, model });
  }

  try {
    const response = await fetch(`${gatewayBaseUrl}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: userMessage },
        ],
        response_format: { type: "json_object" },
        temperature: 0.1,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      await logger.failure(`AI Gateway error (${response.status}): ${errorText}`);
      return json({ error: `AI Gateway error (${response.status})` }, 502);
    }

    const completion = await response.json();
    const raw: string | undefined = completion.choices?.[0]?.message?.content;
    if (!raw) {
      await logger.failure("Empty response from AI Gateway");
      return json({ error: "Empty response from AI Gateway" }, 502);
    }
    const cleaned = raw.trim().replace(/^```(json)?/, "").replace(/```$/, "").trim();
    await logger.success(raw);

    const StepsSchema = z.object({
      steps: z.array(z.object({
        minutes: z.number().nullable().optional(),
        ingredients: z.array(z.number()).default([]),
      })),
    });
    const parsed = StepsSchema.parse(JSON.parse(cleaned));

    // One entry per instruction, indexes in range, minutes a positive integer or null.
    const steps = instructions.map((_, i) => {
      const step = parsed.steps[i];
      const minutes = step?.minutes != null && step.minutes > 0 ? Math.round(step.minutes) : null;
      const used = [...new Set((step?.ingredients ?? [])
        .map((n) => Math.round(n))
        .filter((n) => n >= 0 && n < ingredients.length))];
      return { minutes, ingredients: used };
    });

    return json({ steps });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to analyze recipe steps:", err);
    await logger.failure(message);
    return json({ error: `Internal error: ${message}` }, 500);
  }
});
