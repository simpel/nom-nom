import { NextResponse } from 'next/server';
import { processStalePartyInsights } from '@/utils/party-insights';

export const maxDuration = 60; // 1 minute max duration for cron
export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
    // 1. Verify cron secret strictly
    const authHeader = request.headers.get('authorization');
    const cronSecret = process.env.CRON_SECRET;

    if (!cronSecret || authHeader !== `Bearer ${cronSecret}`) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const result = await processStalePartyInsights({ batchLimit: 5 });
        return NextResponse.json({ success: true, ...result });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
