import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { generatePartyInsightsForParty, processStalePartyInsights } from '@/utils/party-insights';

export const maxDuration = 60; // 1 minute max duration

export async function POST(request: Request) {
    const supabaseServer = await createClient();
    const { data: { user } } = await supabaseServer.auth.getUser();

    if (!user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { party_id, all, force } = await request.json();

    try {
        if (all) {
            const result = await processStalePartyInsights({ force: !!force, batchLimit: 10 });
            return NextResponse.json({ success: true, ...result });
        } else if (party_id) {
            const result = await generatePartyInsightsForParty(party_id, { force: !!force });
            if (!result.success) {
                return NextResponse.json({ error: result.error || 'Generation failed' }, { status: 500 });
            }
            return NextResponse.json({ success: true, skipped: result.skipped || false });
        } else {
            return NextResponse.json({ error: 'Missing party_id or all flag' }, { status: 400 });
        }
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
