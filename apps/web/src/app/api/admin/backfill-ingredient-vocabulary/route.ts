import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';
import { flattenIngredients } from '@/lib/ingredients';

export const maxDuration = 300;

export async function POST(request: Request) {
    const supabaseServer = await createClient();
    const { data: { user } } = await supabaseServer.auth.getUser();

    if (!user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const webhookSecret = process.env.WEBHOOK_SECRET;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    if (!webhookSecret) {
        return NextResponse.json({ error: 'WEBHOOK_SECRET is not configured (must match the Supabase vault secret of the same name)' }, { status: 500 });
    }

    const body = await request.json().catch(() => ({}));
    const recipeId: string | undefined = body.recipe_id;

    try {
        let query = adminSupabase.from('recipes').select('id, ingredient_groups');
        if (recipeId) query = query.eq('id', recipeId);

        const { data: recipes, error } = await query;

        if (error || !recipes) {
            return NextResponse.json({ error: 'Failed to fetch recipes' }, { status: 500 });
        }

        const withIngredients = recipes.filter(
            (d) => flattenIngredients(d.ingredient_groups).length > 0
        );

        if (withIngredients.length === 0) {
            return NextResponse.json({
                success: true,
                updated: 0,
                message: recipeId ? 'Recipe not found or has no ingredients' : 'No recipes with ingredients',
            });
        }

        // Skip recipes already resolved, unless a specific recipe was requested (force re-run).
        let pending = withIngredients;
        if (!recipeId) {
            const { data: done, error: doneError } = await adminSupabase
                .from('recipe_ingredients_canonical')
                .select('recipe_id');

            if (doneError) {
                return NextResponse.json({ error: 'Failed to fetch existing canonical rows' }, { status: 500 });
            }

            const doneIds = new Set((done || []).map((r) => r.recipe_id));
            pending = withIngredients.filter((d) => !doneIds.has(d.id)).slice(0, 50);
        }

        if (pending.length === 0) {
            return NextResponse.json({ success: true, updated: 0, message: 'All recipes already canonicalized' });
        }

        let updated = 0;
        let failed = 0;
        let lastError: string | null = null;

        for (const recipe of pending) {
            const { error: invokeError } = await adminSupabase.functions.invoke('canonicalize-ingredients', {
                headers: { 'x-webhook-secret': webhookSecret },
                body: {
                    type: 'UPDATE',
                    table: 'recipes',
                    record: recipe,
                    old_record: null,
                },
            });

            if (invokeError) {
                console.error(`Canonicalization error for recipe ${recipe.id}:`, invokeError);
                failed++;
                lastError = `${recipe.id}: ${invokeError.message || 'edge function call failed'}`;
                continue;
            }

            updated++;
        }

        return NextResponse.json({ success: true, updated, failed, error: updated === 0 ? lastError : undefined });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
