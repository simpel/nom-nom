// Recommends new recipes for a dinner party: pgvector narrows the candidates to what
// the party's rating history points at, then an LLM picks and explains the best few.
// Results are cached in public.party_recommendations (refreshed after 24h or a new rating).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const MIN_RATED_DISHES = 2;
const MAX_PICKS = 8;

const SYSTEM_PROMPT = `You recommend dinner recipes for a group of people who eat together.
You get the group's rating history (scores 0 to 100, 50 and above is liked, under 30 is disliked),
what each member liked and disliked, and a list of candidate recipes.
Pick ${MAX_PICKS} candidates at most that this specific group is most likely to enjoy. Avoid anything
that resembles what a member disliked. Prefer variety over near-duplicates.
For each pick write one short, concrete reason (max 90 characters) tied to the group's tastes.
Use only candidate ids from the list. Respond with JSON only:
{"picks":[{"dish_id":"<uuid>","reason":"<text>"}]}`;

interface Pick {
  dish_id: string;
  reason: string;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const apiKey = Deno.env.get("VERCEL_AI_GATEWAY_KEY") || Deno.env.get("VERCEL_AI_GATEWAY");
  const gatewayBaseUrl = Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1";
  if (!url || !serviceKey || !anonKey) return json({ error: "Supabase env not configured" }, 500);

  // Who is asking: resolved from the JWT, never from the body.
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authHeader } } });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return json({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  let partyId: string | undefined;
  let force = false;
  try {
    const body = await req.json();
    partyId = body.party_id;
    force = body.force === true;
  } catch { /* handled below */ }
  if (!partyId) return json({ error: "party_id is required" }, 400);

  const db = createClient(url, serviceKey);

  const { data: membership } = await db
    .from("party_members").select("id").eq("party_id", partyId).eq("user_id", userId).maybeSingle();
  if (!membership) return json({ error: "Not a member of this party" }, 403);

  // Rating history for the party, one row per (meal, rater).
  const { data: partyMeals, error: histErr } = await db
    .from("meal_parties")
    .select("meals(id, dish_id, dishes(name, cuisine), meal_ratings(score, rater_id, eater_id, updated_at))")
    .eq("party_id", partyId);
  if (histErr) return json({ error: histErr.message }, 500);

  const meals = (partyMeals ?? []).map((r: any) => r.meals).filter(Boolean);
  const latestRating = meals
    .flatMap((m: any) => m.meal_ratings ?? [])
    .map((r: any) => Date.parse(r.updated_at))
    .reduce((a: number, b: number) => Math.max(a, b), 0);

  // Cache hit?
  const { data: cached } = await db
    .from("party_recommendations").select("dish_id, reason, generated_at").eq("party_id", partyId).order("rank");
  if (!force && cached && cached.length > 0) {
    const generatedAt = Math.max(...cached.map((c: any) => Date.parse(c.generated_at)));
    if (Date.now() - generatedAt < CACHE_TTL_MS && latestRating <= generatedAt) {
      return json({ recommendations: cached.map((c: any) => ({ dish_id: c.dish_id, reason: c.reason })), cached: true });
    }
  }

  // Per-dish scores and per-member taste.
  const ratedDishes = new Set<string>();
  const dishScores = new Map<string, { name: string; scores: number[] }>();
  const raterIds = new Set<string>();
  const eaterIds = new Set<string>();
  for (const m of meals) {
    for (const r of m.meal_ratings ?? []) {
      ratedDishes.add(m.dish_id);
      const entry = dishScores.get(m.dish_id) ?? { name: m.dishes?.name ?? "Unknown", scores: [] };
      entry.scores.push(Number(r.score) * 100);
      dishScores.set(m.dish_id, entry);
      if (r.rater_id) raterIds.add(r.rater_id);
      if (r.eater_id) eaterIds.add(r.eater_id);
    }
  }

  const clearCache = async () => { await db.from("party_recommendations").delete().eq("party_id", partyId); };
  if (ratedDishes.size < MIN_RATED_DISHES) {
    await clearCache();
    return json({ recommendations: [], cached: false, reason: "not-enough-history" });
  }
  if (!apiKey) return json({ error: "No AI API key configured" }, 500);

  const { data: candidates, error: candErr } = await db.rpc("party_recommendation_candidates", {
    p_party_id: partyId, p_user_id: userId, p_limit: 30,
  });
  if (candErr) return json({ error: candErr.message }, 500);
  if (!candidates || candidates.length === 0) {
    await clearCache();
    return json({ recommendations: [], cached: false, reason: "no-candidates" });
  }

  const [{ data: profiles }, { data: eaters }] = await Promise.all([
    db.from("profiles").select("id, display_name").in("id", [...raterIds]),
    db.from("eaters").select("id, name").in("id", [...eaterIds]),
  ]);
  const names = new Map<string, string>([
    ...(profiles ?? []).map((p: any): [string, string] => [p.id, p.display_name || "Member"]),
    ...(eaters ?? []).map((e: any): [string, string] => [e.id, e.name]),
  ]);

  const members = new Map<string, { liked: Set<string>; disliked: Set<string> }>();
  for (const m of meals) {
    for (const r of m.meal_ratings ?? []) {
      const who = names.get(r.rater_id ?? r.eater_id) ?? "Someone";
      const entry = members.get(who) ?? { liked: new Set(), disliked: new Set() };
      const dish = m.dishes?.name ?? "Unknown";
      if (Number(r.score) >= 0.5) entry.liked.add(dish);
      if (Number(r.score) < 0.3) entry.disliked.add(dish);
      members.set(who, entry);
    }
  }

  const avg = (xs: number[]) => xs.reduce((a, b) => a + b, 0) / xs.length;
  const history = [...dishScores.values()]
    .map((d) => ({ name: d.name, avg: Math.round(avg(d.scores)) }))
    .sort((a, b) => b.avg - a.avg)
    .slice(0, 20);

  const userMessage = JSON.stringify({
    party_history: history,
    members: [...members.entries()].map(([name, v]) => ({
      name, liked: [...v.liked].slice(0, 8), disliked: [...v.disliked].slice(0, 8),
    })),
    candidates: candidates.map((c: any) => ({
      dish_id: c.id,
      name: c.name,
      cuisine: c.cuisine,
      ingredients: Array.isArray(c.ingredients) ? c.ingredients.map((i: any) => i.ingredient).filter(Boolean).slice(0, 12) : [],
      effort: c.effort,
      health_score: c.health_score,
    })),
  });

  const model = await getFeatureModel(db, "party-recommendations");
  const logger = GenerationLogger.fromEnv();
  await logger.start({ type: "party_recommendation", entityId: partyId, model, prompt: userMessage });

  try {
    const response = await fetch(`${gatewayBaseUrl}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        messages: [{ role: "system", content: SYSTEM_PROMPT }, { role: "user", content: userMessage }],
        response_format: { type: "json_object" },
        temperature: 0.4,
      }),
    });
    if (!response.ok) {
      const text = await response.text();
      await logger.failure(`AI Gateway error (${response.status}): ${text}`);
      return json({ error: "AI Gateway error" }, 502);
    }

    const completion = await response.json();
    const raw = (completion.choices?.[0]?.message?.content ?? "").trim()
      .replace(/^```json/, "").replace(/^```/, "").replace(/```$/, "");
    const parsed = JSON.parse(raw);

    // Keep only real candidates, once each, in the model's order.
    const allowed = new Set<string>(candidates.map((c: any) => c.id));
    const seen = new Set<string>();
    const picks: Pick[] = [];
    for (const p of parsed.picks ?? []) {
      if (!allowed.has(p?.dish_id) || seen.has(p.dish_id)) continue;
      seen.add(p.dish_id);
      picks.push({ dish_id: p.dish_id, reason: String(p.reason ?? "").slice(0, 140) });
      if (picks.length === MAX_PICKS) break;
    }
    if (picks.length === 0) {
      await logger.failure("Model returned no valid picks");
      return json({ recommendations: [], cached: false, reason: "no-valid-picks" });
    }

    await clearCache();
    const { error: insertErr } = await db.from("party_recommendations").insert(
      picks.map((p, i) => ({ party_id: partyId, dish_id: p.dish_id, rank: i, reason: p.reason })),
    );
    if (insertErr) {
      await logger.failure(insertErr.message);
      return json({ error: insertErr.message }, 500);
    }

    await logger.success(JSON.stringify(picks));
    return json({ recommendations: picks, cached: false });
  } catch (err: any) {
    await logger.failure(err.message);
    return json({ error: err.message }, 500);
  }
});
