// Edge function for cook mode: for each instruction step, how many minutes it waits
// on (a timer, or null) and which of the recipe's ingredients it uses.
// Triggered by the analyze_recipe_steps_webhook DB trigger on
// recipes insert/update (see migrations/20261006223500_analyze_recipe_steps_webhook.sql).

import { z } from "npm:zod";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";
import { flattenIngredients, ingredientGroupsText, type IngredientGroup } from "../_shared/ingredients.ts";

interface RecipeRow {
  id: string;
  name: string;
  ingredient_groups: IngredientGroup[] | null;
  instructions: string[] | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE";
  table: string;
  record: RecipeRow;
  old_record: RecipeRow | null;
}

const SYSTEM_PROMPT = `You prepare recipes for a step-by-step cook mode.

For every numbered instruction step, return:
- "minutes": the time the cook waits on in that step (roasting, simmering, resting, marinating, boiling pasta). An integer, or null when the step is hands-on with no wait. Use the time the step states; if it gives a range, use the upper bound; if it says "until golden" with no time, estimate a typical integer.
- "ingredients": the indexes (0-based, the numbers in the ingredient list; group headings like "Sauce:" are not numbered) of the ingredients first added or used in that step. An ingredient may appear in more than one step only if it is split across them (e.g. oil used twice). When a step refers to ingredients without naming them ("add the spices", "the remaining ingredients", "the dressing ingredients"), list each ingredient it means. Every ingredient is used in at least one step. A step that uses none (preheating the oven, resting, serving) gets []. Never invent indexes.

Return exactly one entry per instruction step, in order, as:
{ "steps": [ { "minutes": 20, "ingredients": [0, 4] }, { "minutes": null, "ingredients": [] } ] }

Return ONLY valid JSON.`;

Deno.serve(async (req) => {
  const signature = req.headers.get("x-webhook-secret");
  const expected = Deno.env.get("WEBHOOK_SECRET");
  if (!signature || signature !== expected) {
    return new Response("Unauthorized", { status: 401 });
  }

  let logger: GenerationLogger | null = null;

  try {
    const payload: WebhookPayload = await req.json();
    const recipe = payload.record;
    
    const instructions = (recipe.instructions || []).map((s) => s.trim()).filter(Boolean);
    if (!recipe.name || instructions.length === 0) {
      return new Response(JSON.stringify({ skipped: "no-instructions" }), {
        headers: { "Content-Type": "application/json" },
      });
    }
    const ingredients = flattenIngredients(recipe.ingredient_groups);

    const apiKey =
      Deno.env.get("VERCEL_AI_GATEWAY") ||
      Deno.env.get("VERCEL_AI_GATEWAY_KEY") ||
      Deno.env.get("AI_GATEWAY_API_KEY") ||
      Deno.env.get("VERCEL_AI_GATEWAY_TOKEN");
    
    const gatewayBaseUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";

    if (!apiKey) {
      return new Response(JSON.stringify({ error: "no-api-key" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !serviceKey) {
      return new Response(JSON.stringify({ error: "no-service-credentials" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
    const admin = createClient(url, serviceKey);

    logger = GenerationLogger.fromEnv();
    const model = await getFeatureModel(admin, "analyze-recipe-steps", "text");

    const ingredientList = ingredientGroupsText(recipe.ingredient_groups, true);
    const stepList = instructions.map((s, i) => `${i + 1}. ${s}`).join("\n");
    const userMessage = `Recipe: ${recipe.name}\n\nIngredients:\n${ingredientList || "(none listed)"}\n\nSteps:\n${stepList}`;

    await logger.start({ type: "recipe_steps", entityId: recipe.id, prompt: userMessage, model });

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
      return new Response(JSON.stringify({ error: `AI Gateway error (${response.status})` }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    const completion = await response.json();
    const raw: string | undefined = completion.choices?.[0]?.message?.content;
    if (!raw) {
      await logger.failure("Empty response from AI Gateway");
      return new Response(JSON.stringify({ error: "Empty response from AI Gateway" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
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

    // Update the recipe with the generated step details
    const { error: updateErr } = await admin
      .from("recipes")
      .update({ instruction_details: steps })
      .eq("id", recipe.id);

    if (updateErr) {
      console.error(`Failed to update instruction_details for recipe ${recipe.id}:`, updateErr);
      return new Response(JSON.stringify({ error: updateErr.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, recipe_id: recipe.id }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: any) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to analyze recipe steps:", err);
    if (logger) await logger.failure(message);
    return new Response(JSON.stringify({ error: `Internal error: ${message}` }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
