import { NextResponse } from 'next/server';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';

export const maxDuration = 300;

export async function POST(request: Request) {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    const body = await request.json().catch(() => ({}));
    const recipeId: string | undefined = body.recipe_id;

    try {
        let query = adminSupabase
            .from('dishes')
            .select('id, name, ingredients, instructions');

        if (recipeId) {
            query = query.eq('id', recipeId);
        } else {
            query = query.is('health_score', null).limit(50);
        }

        const { data: dishes, error } = await query;

        if (error || !dishes) {
            return NextResponse.json({ error: 'Failed to fetch dishes' }, { status: 500 });
        }

        if (dishes.length === 0) {
            return NextResponse.json({
                success: true,
                updated: 0,
                message: recipeId ? 'Recipe not found' : 'All dishes have a health score',
            });
        }

        let updated = 0;
        let failed = 0;
        let lastError: string | null = null;

        for (const dish of dishes) {
            if (!dish.ingredients || !Array.isArray(dish.ingredients) || dish.ingredients.length === 0) {
                failed++;
                lastError = `${dish.name}: no ingredients to analyze`;
                continue;
            }

            const { error: invokeError } = await adminSupabase.functions.invoke('analyze-recipe-health', {
                body: {
                    recipe_id: dish.id,
                    name: dish.name,
                    ingredients: dish.ingredients,
                    instructions: dish.instructions || [],
                },
            });

            if (invokeError) {
                console.error(`Health score error for dish ${dish.id}:`, invokeError);
                failed++;
                lastError = `${dish.name}: ${invokeError.message || 'edge function call failed'}`;
                continue;
            }

            updated++;
        }

        return NextResponse.json({ success: true, updated, failed, error: updated === 0 ? lastError : undefined });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
