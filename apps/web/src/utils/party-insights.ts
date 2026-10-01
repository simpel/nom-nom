import { createClient as createSupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

const InsightSchema = z.object({
    summary_sentence: z.string(),
    recommendations: z.array(z.object({
        title: z.string(),
        description: z.string(),
        cuisine: z.string().nullable().optional(),
        dish_id: z.string().uuid().nullable().optional()
    })),
    top_ingredients: z.array(z.string()).optional().default([]),
    ways_of_cooking: z.array(z.string()).optional().default([]),
    health_analysis: z.object({
        score: z.number(),
        summary: z.string(),
        details: z.array(z.string())
    }).optional().nullable(),
    member_matches: z.array(z.object({
        member_id: z.string().optional().nullable(),
        member_name: z.string(),
        explanation: z.string()
    })).optional().default([])
});

export type GeneratedPartyInsight = z.infer<typeof InsightSchema>;

function getAdminSupabase() {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    return createSupabaseClient(supabaseUrl, supabaseServiceKey);
}

function normalizeReaction(react: number): number {
    if (react === -1) return 0.0;
    if (react === 1) return 0.2;
    if (react === 2) return 0.4;
    if (react === 3) return 0.6;
    if (react === 4) return 0.8;
    if (react === 5) return 1.0;
    return 0.6;
}

const PARTY_INSIGHT_SYSTEM_PROMPT = `Analyze the following dinner party history (recent meals, top cuisines, average scores 0.0-1.0, and member ratings).
Produce a JSON response analyzing their preferences, explaining individual member taste matches/mismatches with the food served, and suggesting new meals.
IMPORTANT: In the 'summary_sentence', you MUST use markdown to color-code the text:
Wrap positive things (foods, cuisines, or flavors they enjoy) in **double asterisks** (e.g. **Mexican food**, **spicy flavors**).
Wrap negative things (foods, cuisines, or flavors they dislike or avoid) in ~~double tildes~~ (e.g. ~~seafood~~, ~~mushrooms~~).
Output MUST match this JSON schema exactly:
{
  "summary_sentence": "A VERY CONCISE, one-sentence summary of the party's tastes (MAX 25 WORDS). Format like: '[Party Name] enjoys [flavor] dishes with a preference for [cuisine].'",
  "recommendations": [
    {
      "title": "Recipe Name",
      "description": "Short description of why it fits their profile",
      "cuisine": "Cuisine type"
    }
  ],
  "top_ingredients": ["ingredient 1", "ingredient 2"],
  "ways_of_cooking": ["Grilling", "Baking"],
  "health_analysis": {
    "score": 85,
    "summary": "A brief summary of how healthy their recent meals are.",
    "details": ["High protein from frequent chicken", "Low carb options in recent weeks"]
  },
  "member_matches": [
    {
      "member_id": "member_id",
      "member_name": "Member Name",
      "explanation": "1 concise sentence explaining how this member's taste aligns with or deviates from the food served to the party (e.g. 'Anna loves pasta nights but consistently rates the party's heavier BBQ and spicy dishes lower than the group.')"
    }
  ]
}`;

export async function generatePartyInsightsForParty(
    partyId: string,
    options: { force?: boolean } = {}
): Promise<{ success: boolean; skipped?: boolean; error?: string }> {
    const adminSupabase = getAdminSupabase();
    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;
    const model = process.env.AI_GATEWAY_MODEL || 'google/gemini-2.5-flash';

    if (!apiKey) {
        return { success: false, error: 'Missing VERCEL_AI_GATEWAY credentials' };
    }

    const { data: party, error: partyError } = await adminSupabase
        .from('parties')
        .select('id, name, updated_at')
        .eq('id', partyId)
        .single();

    if (partyError || !party) {
        return { success: false, error: partyError?.message || 'Party not found' };
    }

    const { data: existingInsight } = await adminSupabase
        .from('party_insights')
        .select('party_id, updated_at')
        .eq('party_id', party.id)
        .single();

    const isStale = !existingInsight || new Date(party.updated_at) > new Date(existingInsight.updated_at);
    if (!isStale && !options.force) {
        return { success: true, skipped: true };
    }

    // 1. Fetch recent meals for this party
    const { data: mealData, error: mealError } = await adminSupabase
        .from('meal_parties')
        .select(`
            meal_id,
            meals (
                eaten_on,
                notes,
                dishes (
                    name,
                    cuisine,
                    ingredients
                ),
                meal_ratings (
                    rater_id,
                    eater_id,
                    reaction
                )
            )
        `)
        .eq('party_id', party.id)
        .order('created_at', { ascending: false })
        .limit(30);

    if (mealError || !mealData) {
        return { success: false, error: mealError?.message || 'Failed to fetch party meals' };
    }

    // 2. Fetch party members
    const { data: memberRows } = await adminSupabase
        .from('party_members')
        .select('user_id')
        .eq('party_id', party.id);
    const memberIds = memberRows?.map(m => m.user_id) || [];
    const { data: profiles } = memberIds.length > 0
        ? await adminSupabase.from('profiles').select('id, display_name').in('id', memberIds)
        : { data: [] };
    const profileMap = new Map((profiles || []).map(p => [p.id, p.display_name]));

    // 3. Compile context (excluding raw instructions to minimize token usage)
    const recentMeals = mealData.map((row: any) => {
        const m = row.meals;
        if (!m) return null;
        const dish = m.dishes;
        const ratings = m.meal_ratings || [];

        let totalScore = 0;
        let count = 0;
        const memberRatings: Record<string, number> = {};

        for (const r of ratings) {
            const norm = normalizeReaction(r.reaction);
            totalScore += norm;
            count++;

            const raterId = r.rater_id || r.eater_id;
            if (raterId && profileMap.has(raterId)) {
                memberRatings[profileMap.get(raterId)!] = norm;
            }
        }
        const avgScore = count > 0 ? parseFloat((totalScore / count).toFixed(2)) : null;

        return {
            name: dish?.name,
            cuisine: dish?.cuisine,
            avg_score: avgScore,
            ingredients: Array.isArray(dish?.ingredients) ? dish.ingredients.map((i: any) => i.ingredient || i) : [],
            member_ratings: memberRatings
        };
    }).filter(m => m != null && m.name != null);

    const cuisineFreq: Record<string, number> = {};
    for (const m of recentMeals) {
        if (m?.cuisine) {
            cuisineFreq[m.cuisine] = (cuisineFreq[m.cuisine] || 0) + 1;
        }
    }

    const membersList = (profiles || []).map(p => ({ id: p.id, name: p.display_name }));

    const aggregatedContext = {
        party_name: party.name,
        recent_meals: recentMeals,
        top_cuisines: cuisineFreq,
        members: membersList
    };

    const userMessage = `Data:\n${JSON.stringify(aggregatedContext)}`;

    const startTime = Date.now();
    const { data: logEntry } = await adminSupabase
        .from('generation_logs')
        .insert({
            generation_type: 'party_insight',
            entity_id: party.id,
            prompt: userMessage,
            status: 'running',
            model_used: model
        })
        .select('id')
        .single();

    try {
        const aiResponse = await fetch(`${aiGatewayUrl}/chat/completions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`
            },
            body: JSON.stringify({
                model: model,
                messages: [
                    { role: 'system', content: PARTY_INSIGHT_SYSTEM_PROMPT },
                    { role: 'user', content: userMessage }
                ],
                response_format: { type: 'json_object' },
                temperature: 0.5
            })
        });

        if (!aiResponse.ok) {
            const errorText = await aiResponse.text();
            if (logEntry) {
                await adminSupabase.from('generation_logs').update({
                    status: 'error',
                    error_message: errorText,
                    duration_ms: Date.now() - startTime
                }).eq('id', logEntry.id);
            }
            return { success: false, error: `AI request failed: ${errorText}` };
        }

        const completion = await aiResponse.json();
        const content = completion.choices?.[0]?.message?.content;

        if (!content) {
            if (logEntry) {
                await adminSupabase.from('generation_logs').update({
                    status: 'error',
                    error_message: 'Empty AI response',
                    duration_ms: Date.now() - startTime
                }).eq('id', logEntry.id);
            }
            return { success: false, error: 'Empty AI response' };
        }

        if (logEntry) {
            await adminSupabase.from('generation_logs').update({
                status: 'success',
                response: content,
                duration_ms: Date.now() - startTime
            }).eq('id', logEntry.id);
        }

        const parsed = JSON.parse(content);
        const validated = InsightSchema.parse(parsed);

        // Vector search to link recommendations to existing dishes
        for (const rec of validated.recommendations) {
            try {
                const input = `${rec.title} - ${rec.cuisine || ''} - ${rec.description || ''}`;
                const recAiResponse = await fetch(`${aiGatewayUrl}/embeddings`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${apiKey}`
                    },
                    body: JSON.stringify({
                        model: 'text-embedding-3-small',
                        input: input
                    })
                });

                if (recAiResponse.ok) {
                    const recCompletion = await recAiResponse.json();
                    const queryEmbedding = recCompletion.data?.[0]?.embedding;
                    if (queryEmbedding) {
                        const { data: matchedDishes, error: matchError } = await adminSupabase.rpc('match_dishes', {
                            query_embedding: queryEmbedding,
                            match_threshold: 0.2,
                            match_count: 1
                        });
                        if (!matchError && matchedDishes && matchedDishes.length > 0) {
                            rec.dish_id = matchedDishes[0].id;
                        }
                    }
                }
            } catch (embedError) {
                console.warn('Recommendation embedding match failed:', embedError);
            }
        }

        // Full upsert to party_insights preserving all columns
        await adminSupabase
            .from('party_insights')
            .upsert({
                party_id: party.id,
                summary_sentence: validated.summary_sentence,
                recommendations: validated.recommendations,
                top_ingredients: validated.top_ingredients || [],
                ways_of_cooking: validated.ways_of_cooking || [],
                health_analysis: validated.health_analysis || null,
                member_matches: validated.member_matches || [],
                updated_at: new Date().toISOString()
            }, { onConflict: 'party_id' });

        return { success: true };
    } catch (err: any) {
        if (logEntry) {
            await adminSupabase.from('generation_logs').update({
                status: 'error',
                error_message: err.message,
                duration_ms: Date.now() - startTime
            }).eq('id', logEntry.id);
        }
        return { success: false, error: err.message };
    }
}

export async function processStalePartyInsights(
    options: { batchLimit?: number; force?: boolean } = {}
): Promise<{ updated: number; skipped: number; errors: number }> {
    const adminSupabase = getAdminSupabase();
    const limit = options.batchLimit || 5;

    const { data: allParties } = await adminSupabase.from('parties').select('id, updated_at');
    const { data: allInsights } = await adminSupabase.from('party_insights').select('party_id, updated_at');

    if (!allParties) {
        return { updated: 0, skipped: 0, errors: 1 };
    }

    const insightsMap = new Map((allInsights || []).map(i => [i.party_id, i.updated_at]));
    const staleParties = allParties.filter(party => {
        const insightUpdated = insightsMap.get(party.id);
        if (!insightUpdated) return true;
        return new Date(party.updated_at) > new Date(insightUpdated);
    });

    const batch = staleParties.slice(0, limit);
    let updated = 0;
    let skipped = 0;
    let errors = 0;

    for (const party of batch) {
        const res = await generatePartyInsightsForParty(party.id, { force: options.force });
        if (res.success) {
            if (res.skipped) skipped++;
            else updated++;
        } else {
            errors++;
            console.error(`Failed to generate insights for party ${party.id}:`, res.error);
        }
    }

    return { updated, skipped, errors };
}
