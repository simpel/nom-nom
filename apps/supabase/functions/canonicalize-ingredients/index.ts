// Edge function that resolves a dish's raw ingredient lines to entries in the
// shared public.ingredient_vocabulary table, so "loved/polarizing" stats can be
// computed on atomic, categorized, language-independent flavor entities instead of
// raw recipe text. Triggered by the canonicalize_ingredients_webhook DB trigger on
// dishes insert/update (see migrations/20260915162000_canonicalize_ingredients_webhook.sql).
//
// Two-step resolution, because an LLM call alone can't guarantee two different
// dishes converge on the identical string for the same entity:
//   1. LLM decomposes + translates + categorizes each raw ingredient line.
//   2. Each proposed canonical name is embedded and matched against existing
//      vocabulary via cosine similarity — a match reuses the existing row (and
//      records the new surface form as an alias); no match creates a new row.

import { z } from "npm:zod";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { GenerationLogger } from "../_shared/generation-logger.ts";

interface DishRow {
  id: string;
  ingredients: { quantity?: string; measurement?: string; ingredient: string }[] | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE";
  table: string;
  record: DishRow;
  old_record: DishRow | null;
}

const CATEGORIES = ["spice", "herb", "protein", "produce", "dairy", "grain", "condiment", "other"] as const;

const ExtractionSchema = z.object({
  items: z.array(
    z.object({
      raw_text: z.string(),
      canonical_name: z.string(),
      category: z.enum(CATEGORIES),
    })
  ),
});

const MATCH_THRESHOLD = 0.83;
const EMBED_MODEL = "text-embedding-3-small";

Deno.serve(async (req) => {
  const signature = req.headers.get("x-webhook-secret");
  const expected = Deno.env.get("WEBHOOK_SECRET");
  if (!signature || signature !== expected) {
    return new Response("Unauthorized", { status: 401 });
  }

  let logger: GenerationLogger | null = null;

  try {
    const payload: WebhookPayload = await req.json();
    const dish = payload.record;
    const rawIngredients = (dish.ingredients || []).map((i) => i.ingredient).filter(Boolean);

    if (rawIngredients.length === 0) {
      return new Response(JSON.stringify({ skipped: "no-ingredients" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const apiKey =
      Deno.env.get("VERCEL_AI_GATEWAY") ||
      Deno.env.get("VERCEL_AI_GATEWAY_KEY") ||
      Deno.env.get("AI_GATEWAY_API_KEY") ||
      Deno.env.get("VERCEL_AI_GATEWAY_TOKEN");
    const gatewayBaseUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";
    const model = Deno.env.get("AI_GATEWAY_MODEL") || "google/gemini-2.5-flash";

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

    const promptText = `You are a multilingual culinary ingredient analyst.

Given this list of raw ingredient lines from a recipe (they may be in any language,
and a single line may bundle several distinct ingredients together):

${rawIngredients.map((r) => `- ${r}`).join("\n")}

For EVERY distinct flavor-relevant ingredient you can identify (splitting bundled
lines apart), return one entry with:
- "raw_text": the exact original line it came from (verbatim, keep bundled lines
  identical across their split-out entries)
- "canonical_name": the ingredient's core identity, translated to English,
  lowercase, singular, stripped of quantity/prep/cut/brand detail, and merged with
  its common variants (e.g. "kanelstång" and "cinnamon stick" both become
  "cinnamon"; "boneless chicken thighs" becomes "chicken"; "dried guajillo chiles"
  becomes "guajillo chile")
- "category": one of spice, herb, protein, produce, dairy, grain, condiment, other

Skip ingredients too ubiquitous to signal taste preference: plain salt, plain
black pepper, water, and cooking oil used generically (not a distinctive oil like
sesame or truffle oil).

Return a single JSON object: { "items": [{ "raw_text": "...", "canonical_name": "...", "category": "..." }, ...] }
Return ONLY valid JSON, no markdown fences or commentary.`;

    logger = GenerationLogger.fromEnv();
    await logger.start({ type: "ingredient_canonicalize", entityId: dish.id, prompt: promptText, model });

    const completionRes = await fetch(`${gatewayBaseUrl}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        messages: [{ role: "user", content: promptText }],
        response_format: { type: "json_object" },
        temperature: 0.1,
      }),
    });

    if (!completionRes.ok) {
      const errText = await completionRes.text();
      await logger.failure(`AI Gateway error (${completionRes.status}): ${errText}`);
      return new Response(JSON.stringify({ error: errText }), { status: 502 });
    }

    const completion = await completionRes.json();
    let raw = (completion.choices?.[0]?.message?.content || "").trim();
    if (raw.startsWith("```json")) raw = raw.slice(7);
    if (raw.startsWith("```")) raw = raw.slice(3);
    if (raw.endsWith("```")) raw = raw.slice(0, -3);

    const parsed = ExtractionSchema.parse(JSON.parse(raw.trim()));
    await logger.success(raw);

    if (parsed.items.length === 0) {
      return new Response(JSON.stringify({ success: true, dish_id: dish.id, items: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Embed every unique canonical name in one batch call.
    const uniqueNames = [...new Set(parsed.items.map((i) => i.canonical_name))];
    const embedRes = await fetch(`${gatewayBaseUrl}/embeddings`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({ model: EMBED_MODEL, input: uniqueNames }),
    });

    if (!embedRes.ok) {
      const errText = await embedRes.text();
      console.error(`Embedding error for dish ${dish.id}:`, errText);
      return new Response(JSON.stringify({ error: errText }), { status: 502 });
    }

    const embedCompletion = await embedRes.json();
    const embeddings: number[][] = embedCompletion.data.map((d: { embedding: number[] }) => d.embedding);

    // Resolve each unique canonical name to a vocabulary row (match or create).
    const nameToVocabId = new Map<string, string>();
    for (let i = 0; i < uniqueNames.length; i++) {
      const name = uniqueNames[i];
      const embedding = embeddings[i];
      const category = parsed.items.find((it) => it.canonical_name === name)!.category;

      const { data: matches, error: matchErr } = await admin.rpc("match_ingredient_vocabulary", {
        query_embedding: embedding,
        match_threshold: MATCH_THRESHOLD,
        match_count: 1,
      });

      if (matchErr) {
        console.error("match_ingredient_vocabulary failed:", matchErr);
      }

      if (matches && matches.length > 0) {
        const vocabId = matches[0].id;
        nameToVocabId.set(name, vocabId);
        // Record this surface form as a known alias, without clobbering existing ones.
        await admin.rpc("append_ingredient_alias", { p_id: vocabId, p_alias: name });
      } else {
        const { data: inserted, error: insertErr } = await admin
          .from("ingredient_vocabulary")
          .insert({ canonical_name: name, category, aliases: [name], embedding })
          .select("id")
          .single();

        if (insertErr || !inserted) {
          // Likely a race with another concurrent dish resolving the same new name
          // (canonical_name is unique) — fall back to reading the row it created.
          const { data: existing } = await admin
            .from("ingredient_vocabulary")
            .select("id")
            .eq("canonical_name", name)
            .single();
          if (existing) nameToVocabId.set(name, existing.id);
        } else {
          nameToVocabId.set(name, inserted.id);
        }
      }
    }

    // Replace this dish's canonical ingredient rows.
    await admin.from("dish_ingredients_canonical").delete().eq("dish_id", dish.id);

    const rows = parsed.items
      .map((item) => ({
        dish_id: dish.id,
        raw_text: item.raw_text,
        canonical_ingredient_id: nameToVocabId.get(item.canonical_name),
      }))
      .filter((r) => r.canonical_ingredient_id);

    if (rows.length > 0) {
      const { error: insertRowsErr } = await admin.from("dish_ingredients_canonical").insert(rows);
      if (insertRowsErr) console.error(`Failed to insert canonical ingredients for dish ${dish.id}:`, insertRowsErr);
    }

    return new Response(JSON.stringify({ success: true, dish_id: dish.id, items: rows.length }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: any) {
    console.error("Error canonicalizing ingredients:", err);
    if (logger) await logger.failure(err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
