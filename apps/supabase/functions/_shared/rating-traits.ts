// Rating traits for a new dish kind or cooking method. Traits decide which "what stood
// out" tags a meal offers (see rating_tags in 20261004140000_rating_traits_and_score.sql),
// so a term the resolver creates must get them too. The model picks from the fixed list;
// if it can't, the nearest existing term of the same dimension lends its traits.

import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getFeatureModel } from "./ai-config.ts";

export const RATING_TRAITS = ["crust", "saucy", "raw", "meat_fish", "starch", "smoky"] as const;
export type RatingTrait = typeof RATING_TRAITS[number];

/** Dimensions that carry traits. Cuisine does not. */
export const TRAIT_DIMENSIONS = new Set(["dish_kind", "cooking_method"]);

const SYSTEM_PROMPT = `You classify a dish kind or a cooking method for a dinner-rating app.
Pick every trait that usually applies, from this list only:
- crust: has a crust, crisp coating or crisp edges (pizza, pie, fried, baked, roasted, grilled)
- saucy: built around a sauce, broth or liquid (stew, soup, curry, risotto)
- raw: mostly raw or cured, not cooked (salad, ceviche, gravlax)
- meat_fish: centred on a piece of meat or fish (roast, steak, burger, seafood)
- starch: centred on pasta, rice, noodles or dough (pasta, risotto, dumplings, bowls)
- smoky: smoked or chargrilled flavour (bbq, smoking, grilling)
Pick none if none fit. Answer as JSON: {"traits": ["..."]}`;

export async function suggestRatingTraits({
  client,
  dimension,
  name,
  apiKey,
  gatewayBaseUrl,
  embedding,
}: {
  client: SupabaseClient;
  dimension: string;
  name: string;
  apiKey?: string;
  gatewayBaseUrl: string;
  embedding: number[] | null;
}): Promise<RatingTrait[]> {
  if (!TRAIT_DIMENSIONS.has(dimension)) return [];

  if (apiKey) {
    try {
      const model = await getFeatureModel(client, "taxonomy-traits");
      const res = await fetch(`${gatewayBaseUrl}/chat/completions`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
        body: JSON.stringify({
          model,
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content: `${dimension === "dish_kind" ? "Dish kind" : "Cooking method"}: ${name}` },
          ],
          response_format: { type: "json_object" },
          temperature: 0,
        }),
      });
      if (res.ok) {
        const completion = await res.json();
        const parsed = JSON.parse(completion.choices?.[0]?.message?.content ?? "{}");
        const traits = known(parsed.traits);
        if (traits) return traits;
      } else {
        console.warn(`[rating-traits] model failed (${res.status}):`, await res.text());
      }
    } catch (e) {
      console.warn("[rating-traits] model error:", e);
    }
  }

  return await nearestTraits(client, dimension, embedding);
}

/** The model's answer filtered to the fixed list, or null when it gave no list at all. */
function known(value: unknown): RatingTrait[] | null {
  if (!Array.isArray(value)) return null;
  const set = new Set(value.filter((t): t is RatingTrait => RATING_TRAITS.includes(t)));
  return [...set];
}

async function nearestTraits(
  client: SupabaseClient,
  dimension: string,
  embedding: number[] | null,
): Promise<RatingTrait[]> {
  if (!embedding) return [];
  const { data: matches } = await client.rpc("match_taxonomy_terms", {
    p_dimension: dimension,
    p_embedding: embedding,
    p_match_threshold: 0.5,
    p_match_count: 1,
  });
  const nearest = matches?.[0];
  if (!nearest) return [];
  const { data } = await client
    .from("taxonomy_terms")
    .select("rating_traits")
    .eq("id", nearest.id)
    .maybeSingle();
  return known(data?.rating_traits) ?? [];
}
