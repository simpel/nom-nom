// "Make it land next time": for one party meal, an LLM reads the recipe and how this
// party has rated it (scores, tags, notes) and suggests up to three changes, each with
// the lift it should give. Nom Nom Pro only. Results are cached per meal in
// public.meal_score_tweaks and regenerated after a newer rating.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { GenerationLogger } from "../_shared/generation-logger.ts";
import { getFeatureModel } from "../_shared/ai-config.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_TIPS = 3;
const AI_TIMEOUT_MS = 30_000;
const MAX_ATTEMPTS = 3;

const SYSTEM_PROMPT = `You help a home cook make a recipe land better with the people they cook for.
You get the recipe, the meal they just had, and every time this group has eaten it: each person's
score (0 to 100, 50 and above is liked, under 30 is disliked), the tags they picked and any notes.
Suggest at most ${MAX_TIPS} concrete changes to the recipe or how it is served that would most likely
raise the group's score next time. Tie each one to what the ratings say.
- title: a short imperative in plain household language, max 40 characters ("Halve the chilli").
- reason: one sentence, max 80 characters, naming the evidence ("Anna and Leo both said too spicy").
- lift: your estimate of how many points the group's score would rise, an integer from 1 to 40.
Also write:
- headline: what most explains this score, max 30 characters ("Heat sank it").
- summary: one sentence, max 120 characters, saying why.
Sentence case everywhere, never Title Case. No emoji. Never invent ratings that are not in the data. Respond with JSON only:
{"headline":"<text>","summary":"<text>","tips":[{"title":"<text>","reason":"<text>","lift":<int>}]}`;

interface Tip {
  title: string;
  reason: string;
  lift: number;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

// Trimmed to `max` characters, cut at a word boundary with an ellipsis when too long.
const clip = (value: unknown, max: number) => {
  const text = String(value ?? "").trim();
  if (text.length <= max) return text;
  const cut = text.slice(0, max - 1);
  const space = cut.lastIndexOf(" ");
  return `${(space > max / 2 ? cut.slice(0, space) : cut).replace(/[\s,;:.]+$/, "")}\u2026`;
};

// The model's reply as JSON: code fences and trailing commas stripped, the outermost
// object taken. Null when it still doesn't parse.
function parseModelJson(content: string): any {
  const text = content.trim().replace(/^```(?:json)?/, "").replace(/```$/, "");
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  const body = text.slice(start, end + 1).replace(/,\s*([}\]])/g, "$1");
  try {
    return JSON.parse(body);
  } catch {
    return null;
  }
}

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

  let mealId: string | undefined;
  let force = false;
  try {
    const body = await req.json();
    // Postgres returns uuids lower case; iOS sends them upper case.
    mealId = typeof body.meal_id === "string" ? body.meal_id.toLowerCase() : undefined;
    force = body.force === true;
  } catch { /* handled below */ }
  if (!mealId) return json({ error: "meal_id is required" }, 400);

  const db = createClient(url, serviceKey);

  // The meal's party, among the ones the caller belongs to.
  const { data: links } = await db.from("meal_parties").select("party_id").eq("meal_id", mealId);
  const partyIds = (links ?? []).map((l: any) => l.party_id);
  if (partyIds.length === 0) return json({ error: "Meal has no dinner party" }, 404);
  const { data: memberships } = await db
    .from("party_members").select("party_id").eq("user_id", userId).in("party_id", partyIds);
  const partyId = memberships?.[0]?.party_id;
  if (!partyId) return json({ error: "Not a member of this party" }, 403);

  const { data: pro } = await db.rpc("has_pro", { p_user_id: userId });
  if (pro !== true) return json({ error: "Nom Nom Pro required" }, 402);

  const { data: meal, error: mealErr } = await db
    .from("meals")
    .select("id, dish_id, eaten_on, notes, dishes(name, cuisine, ingredients, instructions)")
    .eq("id", mealId).maybeSingle();
  if (mealErr) return json({ error: mealErr.message }, 500);
  if (!meal) return json({ error: "Meal not found" }, 404);

  // Every serving of this dish by this party, with its ratings.
  const { data: servings, error: servErr } = await db
    .from("meals")
    .select("id, eaten_on, notes, meal_ratings(score, tags, note, rater_id, eater_id, updated_at), meal_parties!inner(party_id)")
    .eq("dish_id", meal.dish_id)
    .eq("meal_parties.party_id", partyId)
    .order("eaten_on", { ascending: false })
    .limit(12);
  if (servErr) return json({ error: servErr.message }, 500);

  const ratings = (servings ?? []).flatMap((s: any) => s.meal_ratings ?? []);
  const thisMealRatings = (servings ?? []).find((s: any) => s.id === mealId)?.meal_ratings ?? [];
  if (thisMealRatings.length === 0) return json({ error: "Meal has no ratings yet" }, 409);
  const latestRating = ratings
    .map((r: any) => Date.parse(r.updated_at))
    .reduce((a: number, b: number) => Math.max(a, b), 0);

  // Cache hit?
  const { data: cached } = await db
    .from("meal_score_tweaks").select("payload, generated_at").eq("meal_id", mealId).maybeSingle();
  if (!force && cached && latestRating <= Date.parse(cached.generated_at)) {
    return json({ ...cached.payload, cached: true });
  }
  if (!apiKey) return json({ error: "No AI API key configured" }, 500);

  const raterIds = [...new Set(ratings.map((r: any) => r.rater_id).filter(Boolean))];
  const eaterIds = [...new Set(ratings.map((r: any) => r.eater_id).filter(Boolean))];
  const [{ data: profiles }, { data: eaters }, { data: tags }] = await Promise.all([
    db.from("profiles").select("id, first_name, display_name").in("id", raterIds),
    db.from("eaters").select("id, name").in("id", eaterIds),
    db.from("rating_tags").select("id, label"),
  ]);
  const names = new Map<string, string>([
    ...(profiles ?? []).map((p: any): [string, string] => [p.id, p.first_name || p.display_name || "Member"]),
    ...(eaters ?? []).map((e: any): [string, string] => [e.id, e.name]),
  ]);
  const tagLabels = new Map<string, string>((tags ?? []).map((t: any) => [t.id, t.label]));

  const dish: any = meal.dishes ?? {};
  const userMessage = JSON.stringify({
    recipe: {
      name: dish.name,
      cuisine: dish.cuisine,
      ingredients: Array.isArray(dish.ingredients)
        ? dish.ingredients.map((i: any) => [i.quantity, i.measurement, i.ingredient].filter(Boolean).join(" ")).slice(0, 30)
        : [],
      instructions: (dish.instructions ?? []).slice(0, 20),
    },
    this_meal: { date: meal.eaten_on, cook_note: meal.notes || null },
    servings: (servings ?? []).map((s: any) => ({
      date: s.eaten_on,
      is_this_meal: s.id === mealId,
      cook_note: s.notes || null,
      ratings: (s.meal_ratings ?? []).map((r: any) => ({
        who: names.get(r.rater_id ?? r.eater_id) ?? "Someone",
        score: Math.round(Number(r.score) * 100),
        tags: (r.tags ?? []).map((t: string) => tagLabels.get(t) ?? t),
        note: r.note || null,
      })),
    })),
  });

  const model = await getFeatureModel(db, "recipe-tweaks");
  const logger = GenerationLogger.fromEnv();
  await logger.start({ type: "recipe_tweaks", entityId: mealId, targetId: partyId, model, prompt: userMessage });

  try {
    // Up to MAX_ATTEMPTS when the model's JSON doesn't parse; a gateway error fails at once.
    let parsed: any = null;
    let lastContent = "";
    for (let attempt = 0; attempt < MAX_ATTEMPTS && parsed === null; attempt++) {
      const response = await fetch(`${gatewayBaseUrl}/chat/completions`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
        body: JSON.stringify({
          model,
          messages: [{ role: "system", content: SYSTEM_PROMPT }, { role: "user", content: userMessage }],
          response_format: { type: "json_object" },
          temperature: 0.4,
        }),
        // Fail cleanly before the runtime's wall clock does.
        signal: AbortSignal.timeout(AI_TIMEOUT_MS),
      });
      if (!response.ok) {
        const text = await response.text();
        await logger.failure(`AI Gateway error (${response.status}): ${text}`);
        return json({ error: "AI Gateway error" }, 502);
      }
      const completion = await response.json();
      lastContent = completion.choices?.[0]?.message?.content ?? "";
      parsed = parseModelJson(lastContent);
    }
    if (parsed === null) {
      await logger.failure(`Model returned invalid JSON ${MAX_ATTEMPTS} times: ${lastContent.slice(0, 1500)}`);
      return json({ error: "Model returned invalid JSON" }, 502);
    }

    const tips: Tip[] = [];
    for (const t of parsed.tips ?? []) {
      const title = clip(t?.title, 60);
      if (!title) continue;
      const lift = Math.max(1, Math.min(40, Math.round(Number(t?.lift) || 1)));
      tips.push({ title, reason: clip(t?.reason, 120), lift });
      if (tips.length === MAX_TIPS) break;
    }
    const payload = {
      headline: clip(parsed.headline, 40),
      summary: clip(parsed.summary, 160),
      tips,
    };

    const { error: upsertErr } = await db.from("meal_score_tweaks").upsert({
      meal_id: mealId, party_id: partyId, payload, generated_at: new Date().toISOString(),
    });
    if (upsertErr) {
      await logger.failure(upsertErr.message);
      return json({ error: upsertErr.message }, 500);
    }

    await logger.success(JSON.stringify(payload));
    return json({ ...payload, cached: false });
  } catch (err: any) {
    await logger.failure(err.message);
    const timedOut = err?.name === "TimeoutError";
    return json({ error: timedOut ? "AI Gateway timed out" : err.message }, timedOut ? 504 : 500);
  }
});
