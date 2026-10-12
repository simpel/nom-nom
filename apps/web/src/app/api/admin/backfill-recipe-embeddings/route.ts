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

    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;

    try {
        const { data: recipes, error } = await adminSupabase
            .from('recipes')
            .select('id, name, cuisine, tags, ingredients, instructions')
            .is('embedding', null)
            .limit(100);

        if (error || !recipes) {
            return NextResponse.json({ error: 'Failed to fetch recipes' }, { status: 500 });
        }

        if (recipes.length === 0) {
            return NextResponse.json({ success: true, message: 'All recipes have embeddings' });
        }

        let updated = 0;

        for (const recipe of recipes) {
            let inputStr = `${recipe.name}`;
            if (recipe.cuisine) inputStr += `\nCuisine: ${recipe.cuisine}`;
            if (recipe.tags && recipe.tags.length > 0) inputStr += `\nTags: ${recipe.tags.join(", ")}`;
            
            if (recipe.ingredients && Array.isArray(recipe.ingredients)) {
                const ingList = recipe.ingredients.map((i: any) => i.ingredient).filter(Boolean);
                if (ingList.length > 0) inputStr += `\nIngredients: ${ingList.join(", ")}`;
            }
            
            if (recipe.instructions && recipe.instructions.length > 0) {
                inputStr += `\nInstructions: ${recipe.instructions.join(" ")}`;
            }

            const aiResponse = await fetch(`${aiGatewayUrl}/embeddings`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${apiKey}`
                },
                body: JSON.stringify({
                    model: 'text-embedding-3-small',
                    input: inputStr
                })
            });

            if (!aiResponse.ok) {
                console.error(`AI Error for recipe ${recipe.id}:`, await aiResponse.text());
                continue;
            }

            const completion = await aiResponse.json();
            const embedding = completion.data?.[0]?.embedding;

            if (embedding) {
                await adminSupabase
                    .from('recipes')
                    .update({ embedding })
                    .eq('id', recipe.id);
                updated++;
            }
        }

        return NextResponse.json({ success: true, updated });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
