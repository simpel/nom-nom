// Maintenance script to backfill dish_kind_id for all dishes missing a taxonomy term.
// Reads from public.dishes, asks AI for the culinary format, and resolves via resolveTaxonomyTerm.

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
Return a single JSON object: { "dish_kind": "..." }`;

async function backfill() {
  console.log("Fetching dishes without dish_kind_id...");
  const { data: dishes, error } = await client
    .from("dishes")
    .select("id, name, cuisine, ingredients")
    .is("dish_kind_id", null);

  if (error) {
    console.error("Error fetching dishes:", error);
    return;
  }

  console.log(`Found ${dishes.length} dishes to classify.`);

  for (const dish of dishes) {
    const rawIngs = (dish.ingredients || [])
      .map((i: { ingredient?: string }) => i.ingredient)
      .filter(Boolean)
      .slice(0, 8)
      .join(", ");

    const userMessage = `Recipe Name: ${dish.name}
Cuisine: ${dish.cuisine || "Unknown"}
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
          proposedKind = parsed.dish_kind || "";
        }
      }

      if (!proposedKind) {
        proposedKind = "specialty";
      }

      const resolved = await resolveTaxonomyTerm({
        client,
        dimension: "dish_kind",
        proposedTerm: proposedKind,
        apiKey,
        gatewayBaseUrl,
      });

      if (resolved) {
        await client
          .from("dishes")
          .update({ dish_kind_id: resolved.id })
          .eq("id", dish.id);
        console.log(`✓ '${dish.name}' -> ${resolved.name} (${resolved.slug})`);
      }
    } catch (e) {
      console.error(`Failed to process '${dish.name}':`, e);
    }
  }

  console.log("Backfill complete.");
}

if (import.meta.main) {
  backfill();
}
