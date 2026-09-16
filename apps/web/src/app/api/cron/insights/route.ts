import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const maxDuration = 60; // 1 minute max duration for cron
export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
    // 1. Verify cron secret (if set)
    const authHeader = request.headers.get('authorization');
    const cronSecret = process.env.CRON_SECRET;
    
    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    
    if (!supabaseUrl || !supabaseServiceKey) {
        return NextResponse.json({ error: 'Missing Supabase credentials' }, { status: 500 });
    }

    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;
    
    if (!apiKey) {
        return NextResponse.json({ error: 'Missing AI Gateway credentials' }, { status: 500 });
    }

    const model = process.env.AI_GATEWAY_MODEL || 'openai/gpt-4o-mini';

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    try {
        // 2. Find parties that need insights regeneration.
        // We select parties where their updated_at is > party_insights.updated_at, or where party_insights doesn't exist.
        const { data: partiesToUpdate, error: partiesError } = await supabase
            .rpc('get_stale_party_insights');

        // Since we don't have this RPC in the migration, we can do a direct query:
        // Supabase doesn't easily allow cross-table comparison in standard REST API for this specific logic unless we do an inner join or fetch both.
        // Let's just fetch all parties and all insights, then filter. (OK for small scales, but we can do it better)
        const { data: allParties } = await supabase.from('parties').select('id, updated_at');
        const { data: allInsights } = await supabase.from('party_insights').select('party_id, updated_at');

        if (!allParties) {
            throw new Error('Could not fetch parties');
        }

        const insightsMap = new Map((allInsights || []).map(i => [i.party_id, i.updated_at]));
        
        const staleParties = allParties.filter(party => {
            const insightUpdated = insightsMap.get(party.id);
            if (!insightUpdated) return true;
            return new Date(party.updated_at) > new Date(insightUpdated);
        });

        if (staleParties.length === 0) {
            return NextResponse.json({ success: true, message: 'No parties to update', updated: 0 });
        }

        let updatedCount = 0;

        // 3. Process each stale party
        for (const party of staleParties) {
            // A. Fetch recent meals with scores and details
            // We need meals joined with dishes and meal_ratings
            const { data: mealData, error: mealError } = await supabase
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
                .limit(20);

            if (mealError || !mealData) {
                console.error(`Failed to fetch meals for party ${party.id}:`, mealError);
                continue;
            }

            // B. Aggregate Context for AI
            const recentMeals = mealData.map((row: any) => {
                const m = row.meals;
                const dish = m.dishes;
                const ratings = m.meal_ratings || [];
                
                // Reaction score mapping
                let totalScore = 0;
                let count = 0;
                for (const r of ratings) {
                    const react = r.reaction;
                    let norm = 0.6; // good
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
                    ingredients: dish?.ingredients?.map((i: any) => i.ingredient), // extract just names
                    instructions: dish?.instructions
                };
            }).filter(m => m.name != null); // filter out empty ones

            const cuisineFreq: Record<string, number> = {};
            for (const m of recentMeals) {
                if (m.cuisine) {
                    cuisineFreq[m.cuisine] = (cuisineFreq[m.cuisine] || 0) + 1;
                }
            }

            const aggregatedContext = {
                recent_meals: recentMeals,
                top_cuisines: cuisineFreq
            };

            // C. Call Vercel AI Gateway
            const prompt = `Analyze the following dinner party history (last 20 meals, top cuisines, and their average scores 0.0-1.0).
Produce a JSON response analyzing their preferences and suggesting new meals.
Output MUST match this JSON schema exactly:
{
  "summary_sentence": "A fun, one-sentence summary of the party's tastes.",
  "food_profile": "A short paragraph (2-3 sentences) analyzing their flavor preferences, noting specific ingredients or cooking methods they like or dislike based on scores.",
  "recommendations": [
    {
      "title": "Recipe Name",
      "description": "Short description of why it fits their profile",
      "cuisine": "Cuisine type"
    }
  ]
}
Data:
${JSON.stringify(aggregatedContext)}`;

            const aiResponse = await fetch(`${aiGatewayUrl}/chat/completions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${apiKey}`
                },
                body: JSON.stringify({
                    model: model,
                    messages: [{ role: 'user', content: prompt }],
                    response_format: { type: 'json_object' },
                    temperature: 0.7
                })
            });

            if (!aiResponse.ok) {
                console.error(`AI Gateway error for party ${party.id}:`, await aiResponse.text());
                continue;
            }

            const completion = await aiResponse.json();
            const content = completion.choices?.[0]?.message?.content;
            
            if (!content) continue;

            try {
                const parsed = JSON.parse(content);
                
                // Add dish_id using vector search
                for (const rec of parsed.recommendations) {
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
                            const { data: matchedDishes, error: matchError } = await supabase.rpc('match_dishes', {
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

                // D. Upsert back to database
                await supabase
                    .from('party_insights')
                    .upsert({
                        party_id: party.id,
                        summary_sentence: parsed.summary_sentence,
                        food_profile: parsed.food_profile,
                        recommendations: parsed.recommendations,
                        updated_at: new Date().toISOString()
                    }, { onConflict: 'party_id' });
                
                updatedCount++;
            } catch (e) {
                console.error(`Failed to parse AI response for party ${party.id}:`, e);
            }
        }

        return NextResponse.json({ success: true, updated: updatedCount });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
