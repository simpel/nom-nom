import { NextResponse } from 'next/server';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';

export const maxDuration = 300;

export async function POST(request: Request) {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);

    const aiGatewayUrl = process.env.AI_GATEWAY_BASE_URL || 'https://ai-gateway.vercel.sh/v1';
    const apiKey = process.env.VERCEL_AI_GATEWAY || process.env.VERCEL_AI_GATEWAY_KEY;

    try {
        const { data: dishes, error } = await adminSupabase
            .from('dishes')
            .select('id, name, cuisine, tags, ingredients, instructions')
            .is('embedding', null)
            .limit(100);

        if (error || !dishes) {
            return NextResponse.json({ error: 'Failed to fetch dishes' }, { status: 500 });
        }

        if (dishes.length === 0) {
            return NextResponse.json({ success: true, message: 'All dishes have embeddings' });
        }

        let updated = 0;

        for (const dish of dishes) {
            let inputStr = `${dish.name}`;
            if (dish.cuisine) inputStr += `\nCuisine: ${dish.cuisine}`;
            if (dish.tags && dish.tags.length > 0) inputStr += `\nTags: ${dish.tags.join(", ")}`;
            
            if (dish.ingredients && Array.isArray(dish.ingredients)) {
                const ingList = dish.ingredients.map((i: any) => i.ingredient).filter(Boolean);
                if (ingList.length > 0) inputStr += `\nIngredients: ${ingList.join(", ")}`;
            }
            
            if (dish.instructions && dish.instructions.length > 0) {
                inputStr += `\nInstructions: ${dish.instructions.join(" ")}`;
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
                console.error(`AI Error for dish ${dish.id}:`, await aiResponse.text());
                continue;
            }

            const completion = await aiResponse.json();
            const embedding = completion.data?.[0]?.embedding;

            if (embedding) {
                await adminSupabase
                    .from('dishes')
                    .update({ embedding })
                    .eq('id', dish.id);
                updated++;
            }
        }

        return NextResponse.json({ success: true, updated });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
