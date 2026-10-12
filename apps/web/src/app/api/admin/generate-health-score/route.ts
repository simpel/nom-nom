import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';

export const maxDuration = 300;

export async function POST(request: Request) {
    const supabaseServer = await createClient();
    const { data: { user } } = await supabaseServer.auth.getUser();

    if (!user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    const body = await request.json().catch(() => ({}));
    const recipeId: string | undefined = body.recipe_id;
    // 'missing_taxonomy' re-runs the analysis for recipes that lack recipe kind / cooking
    // method links (e.g. seeded or pre-taxonomy recipes that already have a health score).
    const missingTaxonomy = body.mode === 'missing_taxonomy';

    try {
        let query = adminSupabase
            .from('recipes')
            .select('id, name, ingredients, instructions');

        if (recipeId) {
            query = query.eq('id', recipeId);
        } else if (missingTaxonomy) {
            query = query.or('recipe_kind_id.is.null,cooking_method_id.is.null').limit(50);
        } else {
            query = query.is('health_score', null).limit(50);
        }

        const { data: recipes, error } = await query;

        if (error || !recipes) {
            return NextResponse.json({ error: 'Failed to fetch recipes' }, { status: 500 });
        }

        if (recipes.length === 0) {
            return NextResponse.json({
                success: true,
                updated: 0,
                message: recipeId
                    ? 'Recipe not found'
                    : missingTaxonomy
                        ? 'All recipes are linked to taxonomy terms'
                        : 'All recipes have a health score',
            });
        }

        let updated = 0;
        let failed = 0;
        let lastError: string | null = null;

        for (const recipe of recipes) {
            if (!recipe.ingredients || !Array.isArray(recipe.ingredients) || recipe.ingredients.length === 0) {
                failed++;
                lastError = `${recipe.name}: no ingredients to analyze`;
                continue;
            }

            const { error: invokeError } = await adminSupabase.functions.invoke('analyze-recipe-health', {
                body: {
                    recipe_id: recipe.id,
                    name: recipe.name,
                    ingredients: recipe.ingredients,
                    instructions: recipe.instructions || [],
                },
            });

            if (invokeError) {
                console.error(`Health score error for recipe ${recipe.id}:`, invokeError);
                failed++;
                lastError = `${recipe.name}: ${invokeError.message || 'edge function call failed'}`;
                continue;
            }

            updated++;
        }

        return NextResponse.json({ success: true, updated, failed, error: updated === 0 ? lastError : undefined });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
