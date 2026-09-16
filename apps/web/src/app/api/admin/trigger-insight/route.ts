import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

export const maxDuration = 60; // 1 minute max duration

export async function POST(request: Request) {
    const supabaseServer = await createClient();
    const { data: { user } } = await supabaseServer.auth.getUser();

    if (!user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { party_id, all, force } = await request.json();

    // Setup Admin Supabase client (service role) to bypass RLS for data aggregation
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;
    const model = process.env.AI_GATEWAY_MODEL || 'openai/gpt-4o-mini';

    try {
        let partiesToProcess: any[] = [];
        
        if (all) {
            const { data } = await adminSupabase.from('parties').select('id, name, updated_at');
            if (data) partiesToProcess = data;
        } else if (party_id) {
            const { data } = await adminSupabase.from('parties').select('id, name, updated_at').eq('id', party_id).single();
            if (data) partiesToProcess = [data];
        } else {
            return NextResponse.json({ error: 'Missing party_id or all flag' }, { status: 400 });
        }

        // A party's insight is stale (and worth regenerating) only if something
        // that feeds the prompt — members, meals, or ratings — changed since the
        // insight was last generated. Those changes bump parties.updated_at via
        // the touch_party_* triggers (see 20260913203100_party_insights.sql), so
        // comparing it against party_insights.updated_at tells us if a run is needed.
        const { data: existingInsights } = await adminSupabase
            .from('party_insights')
            .select('party_id, updated_at, member_matches')
            .in('party_id', partiesToProcess.map(p => p.id));
        const insightByParty = new Map((existingInsights || []).map(i => [i.party_id, i]));

        let updatedCount = 0;
        let skippedCount = 0;

        for (const party of partiesToProcess) {
            const existingInsight = insightByParty.get(party.id);
            const isStale = !existingInsight || new Date(party.updated_at) > new Date(existingInsight.updated_at);

            if (!isStale && !force) {
                skippedCount++;
                continue;
            }

            // A. Fetch recent meals
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
                            tags,
                            ingredients,
                            instructions
                        ),
                        meal_ratings (
                            reaction
                        )
                    )
                `)
                .eq('party_id', party.id)
                .order('created_at', { ascending: false })
                .limit(40);

            if (mealError || !mealData) {
                console.error(`Failed to fetch meals for party ${party.id}:`, mealError);
                continue;
            }

            const recentMeals = mealData.map((row: any) => {
                const m = row.meals;
                const dish = m.dishes;
                const ratings = m.meal_ratings || [];
                
                let totalScore = 0;
                let count = 0;
                for (const r of ratings) {
                    const react = r.reaction;
                    let norm = 0.6; 
                    if (react === -1) norm = 0.0;
                    else if (react === 1) norm = 0.2;
                    else if (react === 2) norm = 0.4;
                    else if (react === 3) norm = 0.6;
                    else if (react === 4) norm = 0.8;
                    else if (react === 5) norm = 1.0;
                    totalScore += norm;
                    count++;
                }
                const avg_score = count > 0 ? (totalScore / count).toFixed(2) : null;

                return {
                    name: dish?.name,
                    cuisine: dish?.cuisine,
                    avg_score: avg_score ? parseFloat(avg_score) : null,
                    tags: dish?.tags,
                    ingredients: dish?.ingredients?.map((i: any) => i.ingredient),
                    instructions: dish?.instructions
                };
            }).filter(m => m.name != null);

            const cuisineFreq: Record<string, number> = {};
            for (const m of recentMeals) {
                if (m.cuisine) {
                    cuisineFreq[m.cuisine] = (cuisineFreq[m.cuisine] || 0) + 1;
                }
            }

            const { data: memberRows } = await adminSupabase
                .from('party_members')
                .select('user_id')
                .eq('party_id', party.id);
            const memberIds = memberRows?.map(m => m.user_id) || [];
            const { data: members } = memberIds.length > 0
                ? await adminSupabase.from('profiles').select('display_name').in('id', memberIds)
                : { data: [] };

            const aggregatedContext = {
                party_name: party.name,
                recent_meals: recentMeals,
                top_cuisines: cuisineFreq,
                members: members || []
            };

            const prompt = `Analyze the following dinner party history (recent meals, top cuisines, and their average scores 0.0-1.0).
Produce a JSON response analyzing their preferences and suggesting new meals.
Output MUST match this JSON schema exactly:
{
  "summary_sentence": "A fun, one-sentence summary of the party's tastes, formatted exactly like: '[Party Name] enjoys [flavor profiles] dishes with a preference for [cuisine/types] dishes. For the moment [dish A] and [dish B] seems to work very well.'",
  "food_profile": "A short paragraph (2-3 sentences) analyzing their flavor preferences.",
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
  }
}
Data:
${JSON.stringify(aggregatedContext)}`;

            const headers: Record<string, string> = {
                'Content-Type': 'application/json'
            };
            if (apiKey) {
                headers['Authorization'] = `Bearer ${apiKey}`;
            }

            const startTime = Date.now();
            const { data: logEntry } = await adminSupabase
                .from('generation_logs')
                .insert({
                    generation_type: 'party_insight',
                    entity_id: party.id,
                    prompt: prompt,
                    status: 'running',
                    model_used: model
                })
                .select('id')
                .single();

            const aiResponse = await fetch(`${aiGatewayUrl}/chat/completions`, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify({
                    model: model,
                    messages: [{ role: 'user', content: prompt }],
                    response_format: { type: 'json_object' },
                    temperature: 0.7
                })
            });

            if (!aiResponse.ok) {
                const errorText = await aiResponse.text();
                console.error(`AI error for party ${party.id}:`, errorText);
                if (logEntry) {
                    await adminSupabase.from('generation_logs').update({
                        status: 'error',
                        error_message: errorText,
                        duration_ms: Date.now() - startTime
                    }).eq('id', logEntry.id);
                }
                continue;
            }

            const completion = await aiResponse.json();
            const content = completion.choices?.[0]?.message?.content;
            
            if (!content) {
                if (logEntry) {
                    await adminSupabase.from('generation_logs').update({
                        status: 'error',
                        error_message: 'Empty response',
                        duration_ms: Date.now() - startTime
                    }).eq('id', logEntry.id);
                }
                continue;
            }

            if (logEntry) {
                await adminSupabase.from('generation_logs').update({
                    status: 'success',
                    response: content,
                    duration_ms: Date.now() - startTime
                }).eq('id', logEntry.id);
            }

            try {
                let parsed;
                try {
                    parsed = JSON.parse(content);
                } catch (e) {
                    throw new Error('Response is not valid JSON');
                }
                
                const InsightSchema = z.object({
                    summary_sentence: z.string(),
                    food_profile: z.string(),
                    recommendations: z.array(z.object({
                        title: z.string(),
                        description: z.string(),
                        cuisine: z.string().nullable().optional()
                    })),
                    top_ingredients: z.array(z.string()).optional(),
                    ways_of_cooking: z.array(z.string()).optional(),
                    health_analysis: z.object({
                        score: z.number(),
                        summary: z.string(),
                        details: z.array(z.string())
                    }).optional()
                });
                
                const validated = InsightSchema.parse(parsed);

                // Add dish_id to recommendations using vector search
                for (const rec of validated.recommendations) {
                    const input = `${rec.title} - ${rec.cuisine || ''} - ${rec.description || ''}`;
                    const recAiResponse = await fetch(`${aiGatewayUrl}/embeddings`, {
                        method: 'POST',
                        headers: headers,
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
                                match_threshold: 0.2, // loose threshold just to grab the closest
                                match_count: 1
                            });

                            if (!matchError && matchedDishes && matchedDishes.length > 0) {
                                (rec as any).dish_id = matchedDishes[0].id;
                            }
                        }
                    }
                }

                await adminSupabase
                    .from('party_insights')
                    .upsert({
                        party_id: party.id,
                        summary_sentence: validated.summary_sentence,
                        food_profile: validated.food_profile,
                        recommendations: validated.recommendations,
                        top_ingredients: validated.top_ingredients || [],
                        ways_of_cooking: validated.ways_of_cooking || [],
                        health_analysis: validated.health_analysis || null,
                        member_matches: existingInsight?.member_matches || [],
                        updated_at: new Date().toISOString()
                    }, { onConflict: 'party_id' });
                updatedCount++;
            } catch (e) {
                console.error(`Parse failed:`, e);
            }
        }

        return NextResponse.json({ success: true, updated: updatedCount, skipped: skippedCount });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
