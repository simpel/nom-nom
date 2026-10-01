import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { generatePartyInsightsForParty } from '@/utils/party-insights';

export const maxDuration = 60; // 1 minute max duration

export async function POST(request: Request) {
    const supabaseServer = await createClient();
    const { data: { user } } = await supabaseServer.auth.getUser();

    if (!user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { party_id } = await request.json();

    if (!party_id) {
        return NextResponse.json({ error: 'Missing party_id' }, { status: 400 });
    }

    try {
        const result = await generatePartyInsightsForParty(party_id, { force: true });
        if (!result.success) {
            return NextResponse.json({ error: result.error || 'Generation failed' }, { status: 500 });
        }
        return NextResponse.json({ success: true });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
