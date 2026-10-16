import { GenerationLogger } from "../_shared/generation-logger.ts";
import { flattenIngredients, type IngredientGroup } from "../_shared/ingredients.ts";

interface RecipeRow {
  id: string;
  name: string;
  cuisine: string | null;
  cuisine_id: string | null;
  recipe_kind_id: string | null;
  cooking_method_id: string | null;
  ingredient_groups: IngredientGroup[] | null;
  instructions: string[] | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE";
  table: string;
  record: RecipeRow;
  old_record: RecipeRow | null;
}

Deno.serve(async (req) => {
  // 1. Validate the secret
  const signature = req.headers.get("x-webhook-secret");
  const expected = Deno.env.get("WEBHOOK_SECRET");
  if (!signature || signature !== expected) {
    return new Response("Unauthorized", { status: 401 });
  }

  let logger: GenerationLogger | null = null;

  try {
    const payload: WebhookPayload = await req.json();
    const recipe = payload.record;

    // Check if we actually need to update the embedding
    if (payload.type === "UPDATE" && payload.old_record) {
      if (
        recipe.name === payload.old_record.name &&
        recipe.cuisine === payload.old_record.cuisine &&
        recipe.cuisine_id === payload.old_record.cuisine_id &&
        recipe.recipe_kind_id === payload.old_record.recipe_kind_id &&
        recipe.cooking_method_id === payload.old_record.cooking_method_id &&
        JSON.stringify(recipe.ingredient_groups) === JSON.stringify(payload.old_record.ingredient_groups) &&
        JSON.stringify(recipe.instructions) === JSON.stringify(payload.old_record.instructions)
      ) {
        return new Response(JSON.stringify({ skipped: "no-change" }), {
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    const aiGatewayUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";
    const apiKey = Deno.env.get("VERCEL_AI_GATEWAY_KEY") || Deno.env.get("VERCEL_AI_GATEWAY");

    if (!apiKey) {
      console.warn("No AI API Key configured");
      return new Response(JSON.stringify({ error: "no-api-key" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    logger = GenerationLogger.fromEnv();

    // Format a rich string for embedding
    let inputStr = `${recipe.name}`;
    if (recipe.cuisine) inputStr += `\nCuisine: ${recipe.cuisine}`;

    if (logger.client && (recipe.recipe_kind_id || recipe.cooking_method_id)) {
      const ids = [recipe.recipe_kind_id, recipe.cooking_method_id].filter(Boolean) as string[];
      if (ids.length > 0) {
        const { data: terms } = await logger.client
          .from("taxonomy_terms")
          .select("dimension, name")
          .in("id", ids);
        if (terms) {
          for (const t of terms) {
            if (t.dimension === "recipe_kind") inputStr += `\nRecipe Kind: ${t.name}`;
            if (t.dimension === "cooking_method") inputStr += `\nCooking Method: ${t.name}`;
          }
        }
      }
    }
    
    const ingList = flattenIngredients(recipe.ingredient_groups).map((i) => i.ingredient).filter(Boolean);
    if (ingList.length > 0) inputStr += `\nIngredients: ${ingList.join(", ")}`;
    
    if (recipe.instructions && recipe.instructions.length > 0) {
      inputStr += `\nInstructions: ${recipe.instructions.join(" ")}`;
    }

    const embedModel = "text-embedding-3-small";
    await logger.start({
      type: "recipe_embed",
      entityId: recipe.id,
      prompt: inputStr,
      model: embedModel,
    });

    const aiResponse = await fetch(`${aiGatewayUrl}/embeddings`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: embedModel,
        input: inputStr,
      }),
    });

    if (!aiResponse.ok) {
      const errText = await aiResponse.text();
      console.error(`AI API Error for recipe ${recipe.id}:`, errText);
      await logger.failure(`AI Gateway error (${aiResponse.status}): ${errText}`);
      return new Response(JSON.stringify({ error: errText }), { status: 502 });
    }

    const completion = await aiResponse.json();
    const embedding = completion.data?.[0]?.embedding;

    if (embedding && logger.client) {
      const { error: updateErr } = await logger.client
        .from("recipes")
        .update({ embedding })
        .eq("id", recipe.id);

      if (updateErr) {
        console.error(`Failed to persist embedding for recipe ${recipe.id}:`, updateErr);
        await logger.failure(`Failed to persist embedding: ${updateErr.message}`);
        return new Response(JSON.stringify({ error: updateErr.message }), { status: 500 });
      }
    }

    await logger.success(`embedding[${Array.isArray(embedding) ? embedding.length : 0}]`);

    return new Response(JSON.stringify({ success: true, recipe_id: recipe.id }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: any) {
    console.error("Error generating embedding:", err);
    if (logger) await logger.failure(err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
