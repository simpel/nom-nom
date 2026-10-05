// Shared universal taxonomy resolver across culinary dimensions (dish_kind, cooking_method, cuisine, etc.).
// Performs exact alias/slug lookup, then vector embedding semantic matching (threshold ~0.82),
// or dynamically registers a new canonical term with a permanent UUID and human-readable name.

import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { suggestRatingTraits } from "./rating-traits.ts";

export interface TaxonomyTermResult {
  id: string;
  dimension: string;
  slug: string;
  name: string;
}

export interface ResolveTaxonomyOptions {
  client: SupabaseClient;
  dimension: string;
  proposedTerm: string;
  apiKey?: string;
  gatewayBaseUrl?: string;
  matchThreshold?: number;
}

const EMBED_MODEL = "text-embedding-3-small";
const DEFAULT_MATCH_THRESHOLD = 0.82;

function toSlug(text: string): string {
  return text
    .trim()
    .toLowerCase()
    .replace(/[\s\-–—]+/g, "_")
    .replace(/[^a-z0-9_]/g, "")
    .replace(/^_+|_+$/g, "");
}

function toHumanReadableName(text: string): string {
  const words = text.trim().replace(/[_\-]+/g, " ").split(/\s+/);
  return words
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(" ");
}

export async function resolveTaxonomyTerm({
  client,
  dimension,
  proposedTerm,
  apiKey,
  gatewayBaseUrl = "https://ai-gateway.vercel.sh/v1",
  matchThreshold = DEFAULT_MATCH_THRESHOLD,
}: ResolveTaxonomyOptions): Promise<TaxonomyTermResult | null> {
  const rawTerm = proposedTerm.trim();
  if (!rawTerm) return null;

  const normalizedLower = rawTerm.toLowerCase();
  const slug = toSlug(rawTerm);
  if (!slug) return null;

  // 1. Exact match on slug
  const { data: exactBySlug } = await client
    .from("taxonomy_terms")
    .select("id, dimension, slug, name")
    .eq("dimension", dimension)
    .eq("slug", slug)
    .maybeSingle();

  if (exactBySlug) {
    return exactBySlug as TaxonomyTermResult;
  }

  // 2. Exact match in aliases
  const { data: exactByAlias } = await client
    .from("taxonomy_terms")
    .select("id, dimension, slug, name")
    .eq("dimension", dimension)
    .contains("aliases", [normalizedLower])
    .maybeSingle();

  if (exactByAlias) {
    return exactByAlias as TaxonomyTermResult;
  }

  let embedding: number[] | null = null;

  // 3. Compute embedding if API key is present
  if (apiKey) {
    try {
      const embedRes = await fetch(`${gatewayBaseUrl}/embeddings`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: EMBED_MODEL,
          input: rawTerm,
        }),
      });

      if (embedRes.ok) {
        const embedJson = await embedRes.json();
        embedding = embedJson.data?.[0]?.embedding || null;
      } else {
        console.warn(`[taxonomy-resolver] embedding failed (${embedRes.status}):`, await embedRes.text());
      }
    } catch (e) {
      console.warn(`[taxonomy-resolver] embedding network error:`, e);
    }
  }

  // 4. Semantic match using pgvector
  if (embedding) {
    const { data: matches, error: matchErr } = await client.rpc("match_taxonomy_terms", {
      p_dimension: dimension,
      p_embedding: embedding,
      p_match_threshold: matchThreshold,
      p_match_count: 1,
    });

    if (!matchErr && matches && matches.length > 0) {
      const matched = matches[0];
      // Append proposed term as an alias to the matched canonical term
      await client.rpc("append_taxonomy_term_alias", {
        p_id: matched.id,
        p_alias: normalizedLower,
      });

      return {
        id: matched.id,
        dimension: matched.dimension,
        slug: matched.slug,
        name: matched.name,
      };
    }
  }

  // 5. No match found: register a brand new canonical term, with its rating traits
  const humanName = toHumanReadableName(rawTerm);
  const insertPayload: Record<string, unknown> = {
    dimension,
    slug,
    name: humanName,
    aliases: [normalizedLower],
    rating_traits: await suggestRatingTraits({
      client,
      dimension,
      name: humanName,
      apiKey,
      gatewayBaseUrl,
      embedding,
    }),
  };
  if (embedding) {
    insertPayload.embedding = embedding;
  }

  const { data: inserted, error: insertErr } = await client
    .from("taxonomy_terms")
    .insert(insertPayload)
    .select("id, dimension, slug, name")
    .single();

  if (insertErr) {
    // If concurrent insert occurred with the same (dimension, slug), fetch that row
    const { data: fallback } = await client
      .from("taxonomy_terms")
      .select("id, dimension, slug, name")
      .eq("dimension", dimension)
      .eq("slug", slug)
      .maybeSingle();

    if (fallback) return fallback as TaxonomyTermResult;
    console.error(`[taxonomy-resolver] failed to insert term:`, insertErr);
    return null;
  }

  return inserted as TaxonomyTermResult;
}
