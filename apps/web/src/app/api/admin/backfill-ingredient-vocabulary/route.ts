import { NextResponse } from 'next/server';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';

export const maxDuration = 300;

export async function POST(request: Request) {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const webhookSecret = process.env.WEBHOOK_SECRET;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    if (!webhookSecret) {
        return NextResponse.json({ error: 'WEBHOOK_SECRET is not configured (must match the Supabase vault secret of the same name)' }, { status: 500 });
    }

    const body = await request.json().catch(() => ({}));
    const dishId: string | undefined = body.dish_id;

    try {
        let query = adminSupabase.from('dishes').select('id, ingredients');
        if (dishId) query = query.eq('id', dishId);

        const { data: dishes, error } = await query;

        if (error || !dishes) {
            return NextResponse.json({ error: 'Failed to fetch dishes' }, { status: 500 });
        }

        const withIngredients = dishes.filter(
            (d) => Array.isArray(d.ingredients) && d.ingredients.length > 0
        );

        if (withIngredients.length === 0) {
            return NextResponse.json({
                success: true,
                updated: 0,
                message: dishId ? 'Dish not found or has no ingredients' : 'No dishes with ingredients',
            });
        }

        // Skip dishes already resolved, unless a specific dish was requested (force re-run).
        let pending = withIngredients;
        if (!dishId) {
            const { data: done, error: doneError } = await adminSupabase
                .from('dish_ingredients_canonical')
                .select('dish_id');

            if (doneError) {
                return NextResponse.json({ error: 'Failed to fetch existing canonical rows' }, { status: 500 });
            }

            const doneIds = new Set((done || []).map((r) => r.dish_id));
            pending = withIngredients.filter((d) => !doneIds.has(d.id)).slice(0, 50);
        }

        if (pending.length === 0) {
            return NextResponse.json({ success: true, updated: 0, message: 'All dishes already canonicalized' });
        }

        let updated = 0;
        let failed = 0;
        let lastError: string | null = null;

        for (const dish of pending) {
            const { error: invokeError } = await adminSupabase.functions.invoke('canonicalize-ingredients', {
                headers: { 'x-webhook-secret': webhookSecret },
                body: {
                    type: 'UPDATE',
                    table: 'dishes',
                    record: dish,
                    old_record: null,
                },
            });

            if (invokeError) {
                console.error(`Canonicalization error for dish ${dish.id}:`, invokeError);
                failed++;
                lastError = `${dish.id}: ${invokeError.message || 'edge function call failed'}`;
                continue;
            }

            updated++;
        }

        return NextResponse.json({ success: true, updated, failed, error: updated === 0 ? lastError : undefined });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
