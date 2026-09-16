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

    const { profile_id } = await request.json();

    if (!profile_id) {
        return NextResponse.json({ error: 'Missing profile_id' }, { status: 400 });
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;
    const model = process.env.AI_GATEWAY_MODEL || 'openai/gpt-4o-mini';

    try {
        const { data: profile, error: profileError } = await adminSupabase
            .from('profiles')
            .select('id, display_name, first_name')
            .eq('id', profile_id)
            .single();

        if (profileError || !profile) {
            return NextResponse.json({ error: 'Profile not found' }, { status: 404 });
        }

        const profileName = profile.display_name || profile.first_name || 'This user';

        // Meals this user logged themselves, plus meals they rated in any party —
        // both count as signal about what they eat and what they like.
        const { data: loggedMeals } = await adminSupabase
            .from('meals')
            .select(`
                eaten_on,
                dishes ( name, cuisine, tags, ingredients )
            `)
            .eq('created_by', profile_id)
            .order('eaten_on', { ascending: false })
            .limit(40);

        const { data: ratedMeals } = await adminSupabase
            .from('meal_ratings')
            .select(`
                reaction,
                meals ( eaten_on, dishes ( name, cuisine, tags, ingredients ) )
            `)
            .eq('rater_id', profile_id)
            .order('created_at', { ascending: false })
            .limit(40);

        const normalizeReaction = (react: number | null) => {
            if (react === -1) return 0.0;
            if (react === 1) return 0.2;
            if (react === 2) return 0.4;
            if (react === 3) return 0.6;
            if (react === 4) return 0.8;
            if (react === 5) return 1.0;
            return null;
        };

        const recentMeals = [
            ...(loggedMeals || []).map((row: any) => ({
                name: row.dishes?.name,
                cuisine: row.dishes?.cuisine,
                tags: row.dishes?.tags,
                ingredients: row.dishes?.ingredients?.map((i: any) => i.ingredient),
                user_score: null as number | null
            })),
            ...(ratedMeals || []).map((row: any) => ({
                name: row.meals?.dishes?.name,
                cuisine: row.meals?.dishes?.cuisine,
                tags: row.meals?.dishes?.tags,
                ingredients: row.meals?.dishes?.ingredients?.map((i: any) => i.ingredient),
                user_score: normalizeReaction(row.reaction)
            }))
        ].filter(m => m.name != null);

        if (recentMeals.length === 0) {
            return NextResponse.json({ error: 'Not enough meal history to generate an insight' }, { status: 400 });
        }

        const cuisineFreq: Record<string, number> = {};
        for (const m of recentMeals) {
            if (m.cuisine) {
                cuisineFreq[m.cuisine] = (cuisineFreq[m.cuisine] || 0) + 1;
            }
        }

        const aggregatedContext = {
            user_name: profileName,
            recent_meals: recentMeals,
            top_cuisines: cuisineFreq
        };

        const prompt = `Analyze the following individual user's cooking and eating history (meals they logged and/or rated, with a 0.0-1.0 score where available).
Produce a JSON response analyzing their personal food preferences and suggesting new meals for them.
Output MUST match this JSON schema exactly:
{
  "summary_sentence": "A fun, one-sentence summary of this person's tastes, formatted exactly like: '[Name] enjoys [flavor profiles] dishes with a preference for [cuisine/types]. Lately [dish A] and [dish B] have been favorites.'",
  "food_profile": "A short paragraph (2-3 sentences) analyzing their personal flavor preferences.",
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
                generation_type: 'profile_insight',
                entity_id: profile_id,
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
            if (logEntry) {
                await adminSupabase.from('generation_logs').update({
                    status: 'error',
                    error_message: errorText,
                    duration_ms: Date.now() - startTime
                }).eq('id', logEntry.id);
            }
            return NextResponse.json({ error: 'AI request failed' }, { status: 500 });
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
            return NextResponse.json({ error: 'Empty AI response' }, { status: 500 });
        }

        if (logEntry) {
            await adminSupabase.from('generation_logs').update({
                status: 'success',
                response: content,
                duration_ms: Date.now() - startTime
            }).eq('id', logEntry.id);
        }

        let parsed;
        try {
            parsed = JSON.parse(content);
        } catch (e) {
            return NextResponse.json({ error: 'Response is not valid JSON' }, { status: 500 });
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

        let validated;
        try {
            validated = InsightSchema.parse(parsed);
        } catch (e) {
            return NextResponse.json({ error: 'Invalid response format from AI' }, { status: 500 });
        }

        // Add dish_id to recommendations using vector search, same as party insights.
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
                        match_threshold: 0.2,
                        match_count: 1
                    });

                    if (!matchError && matchedDishes && matchedDishes.length > 0) {
                        (rec as any).dish_id = matchedDishes[0].id;
                    }
                }
            }
        }

        await adminSupabase
            .from('profile_insights')
            .upsert({
                profile_id: profile_id,
                summary_sentence: validated.summary_sentence,
                food_profile: validated.food_profile,
                recommendations: validated.recommendations,
                top_ingredients: validated.top_ingredients || [],
                ways_of_cooking: validated.ways_of_cooking || [],
                health_analysis: validated.health_analysis || null,
                updated_at: new Date().toISOString()
            }, { onConflict: 'profile_id' });

        return NextResponse.json({ success: true });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
