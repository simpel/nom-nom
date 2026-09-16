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

    const { party_id, profile_id, profile_name } = await request.json();

    if (!party_id || !profile_id || !profile_name) {
        return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;
    const model = process.env.AI_GATEWAY_MODEL || 'openai/gpt-4o-mini';

    try {
        const { data: mealData, error: mealError } = await adminSupabase
            .from('meal_parties')
            .select(`
                meal_id,
                meals (
                    dishes (
                        name,
                        cuisine,
                        tags,
                        ingredients
                    ),
                    meal_ratings (
                        rater_id,
                        reaction
                    )
                )
            `)
            .eq('party_id', party_id)
            .order('created_at', { ascending: false })
            .limit(40);

        if (mealError || !mealData) {
            return NextResponse.json({ error: 'Failed to fetch meals' }, { status: 500 });
        }

        const recentMeals = mealData.map((row: any) => {
            const m = row.meals;
            if (!m) return null;
            const dish = m.dishes;
            const ratings = m.meal_ratings || [];
            
            // Find this specific member's rating for this meal
            const memberRating = ratings.find((r: any) => r.rater_id === profile_id);
            let ratingValue = 'Not rated';
            if (memberRating) {
                const react = memberRating.reaction;
                if (react === -1) ratingValue = 'Disliked (0.0)';
                else if (react === 1) ratingValue = 'Okay (0.2)';
                else if (react === 2) ratingValue = 'Good (0.4)';
                else if (react === 3) ratingValue = 'Very Good (0.6)';
                else if (react === 4) ratingValue = 'Great (0.8)';
                else if (react === 5) ratingValue = 'Loved it (1.0)';
            }

            return {
                name: dish?.name,
                cuisine: dish?.cuisine,
                tags: dish?.tags,
                member_rating: ratingValue
            };
        }).filter(m => m != null && m.name != null);

        const prompt = `Analyze the following dinner party history to determine how well the meals match a specific member named "${profile_name}".
Look at the meals served and specifically how this member rated them (if they rated them).
Produce a JSON response with a match score (0-100) and a short reason explaining why the food matches or doesn't match this member's taste.
Output MUST match this JSON schema exactly:
{
  "match_score": 85,
  "reason": "Why the food matches this member based on their ratings and the dishes served."
}
Data:
${JSON.stringify({ recent_meals: recentMeals })}`;

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
                generation_type: 'member_match',
                entity_id: party_id,
                target_id: profile_id,
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
                    error_message: 'Empty AI response',
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
            return NextResponse.json({ error: 'Invalid JSON response from AI' }, { status: 500 });
        }

        const MatchSchema = z.object({
            match_score: z.number().min(0).max(100),
            reason: z.string()
        });

        let validated;
        try {
            validated = MatchSchema.parse(parsed);
        } catch (e) {
            return NextResponse.json({ error: 'Invalid response format from AI' }, { status: 500 });
        }
        
        // Fetch existing insights to append/update the member match
        const { data: insightData } = await adminSupabase
            .from('party_insights')
            .select('member_matches')
            .eq('party_id', party_id)
            .single();
            
        let existingMatches = insightData?.member_matches || [];
        
        // Filter out any existing match for this member
        existingMatches = existingMatches.filter((m: any) => m.profile_name !== profile_name && m.profile_id !== profile_id);
        
        // Add new match
        existingMatches.push({
            profile_id: profile_id,
            profile_name: profile_name,
            match_score: validated.match_score,
            reason: validated.reason
        });

        await adminSupabase
            .from('party_insights')
            .update({ member_matches: existingMatches })
            .eq('party_id', party_id);

        return NextResponse.json({ success: true });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
