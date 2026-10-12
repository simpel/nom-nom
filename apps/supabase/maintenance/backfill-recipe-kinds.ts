// Maintenance script to backfill recipe_kind_id for all recipes missing a taxonomy term.
// Reads from public.recipes, asks AI for the culinary format, and resolves via resolveTaxonomyTerm.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { resolveTaxonomyTerm } from "../functions/_shared/taxonomy-resolver.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "http://127.0.0.1:54341";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const apiKey = Deno.env.get("VERCEL_AI_GATEWAY") || Deno.env.get("AI_GATEWAY_API_KEY");
const gatewayBaseUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";
const model = Deno.env.get("AI_GATEWAY_MODEL") || "google/gemini-2.5-flash";

if (!serviceRoleKey) {
  console.error("SUPABASE_SERVICE_ROLE_KEY is required");
  Deno.exit(1);
}

const client = createClient(supabaseUrl, serviceRoleKey);

const SYSTEM_PROMPT = `Classify this recipe's culinary format/kind (e.g. 'stew', 'casserole', 'soup', 'bbq', 'pasta', 'pizza', 'curry', 'salad', 'roast', 'stir-fry', 'sandwich', 'pie', 'tacos', 'risotto', etc. Do NOT restrict yourself to these examples).
Return a single JSON object: { "recipe_kind": "..." }`;

async function backfill() {
  console.log("Fetching recipes without recipe_kind_id...");
  const { data: recipes, error } = await client
    .from("recipes")
    .select("id, name, cuisine, ingredients")
    .is("recipe_kind_id", null);

  if (error) {
    console.error("Error fetching recipes:", error);
    return;
  }

  console.log(`Found ${recipes.length} recipes to classify.`);

  for (const recipe of recipes) {
    const rawIngs = (recipe.ingredients || [])
      .map((i: { ingredient?: string }) => i.ingredient)
      .filter(Boolean)
      .slice(0, 8)
      .join(", ");

    const userMessage = `Recipe Name: ${recipe.name}
Cuisine: ${recipe.cuisine || "Unknown"}
Sample Ingredients: ${rawIngs}`;

    try {
      let proposedKind = "";
      if (apiKey) {
        const res = await fetch(`${gatewayBaseUrl}/chat/completions`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model,
            messages: [
              { role: "system", content: SYSTEM_PROMPT },
              { role: "user", content: userMessage }
            ],
          }),
        });

        if (res.ok) {
          const json = await res.json();
          const parsed = JSON.parse(json.choices?.[0]?.message?.content || "{}");
          proposedKind = parsed.recipe_kind || "";
        }
      }

      if (!proposedKind) {
        proposedKind = "specialty";
      }

      const resolved = await resolveTaxonomyTerm({
        client,
        dimension: "recipe_kind",
        proposedTerm: proposedKind,
        apiKey,
        gatewayBaseUrl,
      });

      if (resolved) {
        await client
          .from("recipes")
          .update({ recipe_kind_id: resolved.id })
          .eq("id", recipe.id);
        console.log(`✓ '${recipe.name}' -> ${resolved.name} (${resolved.slug})`);
      }
    } catch (e) {
      console.error(`Failed to process '${recipe.name}':`, e);
    }
  }

  console.log("Backfill complete.");
}

if (import.meta.main) {
  backfill();
}
