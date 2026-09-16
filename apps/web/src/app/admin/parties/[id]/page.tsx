import { createClient } from '@/utils/supabase/server'
import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { redirect } from 'next/navigation'
import PartyDetailClient from './PartyDetailClient'

export default async function PartyDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/admin/login')
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  const { id } = await params;

  const { data: party, error: partyError } = await adminSupabase
    .from('parties')
    .select('*')
    .eq('id', id)
    .single()
  
  if (partyError || !party) {
    return <div className="p-8">Party not found</div>
  }

  const { data: membersData } = await adminSupabase
    .from('party_members')
    .select('user_id')
    .eq('party_id', id)

  const memberIds = membersData?.map(m => m.user_id) || [];

  const { data: membersResult } = memberIds.length > 0
    ? await adminSupabase
        .from('profiles')
        .select('id, display_name')
        .in('id', memberIds)
    : { data: [] };

  const members = membersResult || [];

  const { data: insight } = await adminSupabase
    .from('party_insights')
    .select('*')
    .eq('party_id', id)
    .single()

  const { data: mealsData } = await adminSupabase
    .from('meal_parties')
    .select(`
      meal_id,
      meals (
        id,
        eaten_on,
        effort,
        repeat_desire,
        dishes (
          id,
          name,
          cuisine,
          ingredients,
          effort,
          health_score
        ),
        meal_ratings (
          reaction,
          rater_id,
          eater_id
        )
      )
    `)
    .eq('party_id', id)
    .order('created_at', { ascending: false })

  const meals = mealsData?.map(md => md.meals).filter(Boolean) || [];

  // --- Calculate Advanced Metrics ---
  
  // Helpers
  const normalizeScore = (react: number) => {
    if (react === -1) return 0.0;
    if (react === 1) return 0.2;
    if (react === 2) return 0.4;
    if (react === 3) return 0.6;
    if (react === 4) return 0.8;
    if (react === 5) return 1.0;
    return 0.6;
  }

  // 1. Effort vs Reward
  const effortStats: any = {
    0: { score: 0, count: 0, label: '0–15m' },
    1: { score: 0, count: 0, label: '15–30m' },
    2: { score: 0, count: 0, label: '30–60m' },
    3: { score: 0, count: 0, label: '60m+' }
  }
  
  // 2. Member Taste Stats (own rating vs. that meal's consensus average, in chronological order)
  const memberRatings: Record<string, Record<string, number>> = {}; // mealId -> { memberId: score }
  const memberTasteStats: Record<string, { eaten_on: string, userScore: number, mealAvgScore: number }[]> = {};

  // 4. Cuisine Stats
  const cuisineStats: Record<string, { count: number, scores: number[] }> = {};
  
  // 5. Rotation Hit Rate
  let rotationCount = 0;
  let stapleCount = 0;
  
  // 6. Health Balance
  const healthScores: number[] = [];

  const chartData = [...meals].reverse().map((m: any) => {
    let mealTotalScore = 0;
    let mealRatingCount = 0;
    
    // Member match gathering
    const mRatings: Record<string, number> = {};
    
    for (const r of (m.meal_ratings || [])) {
        const norm = normalizeScore(r.reaction);
        mealTotalScore += norm;
        mealRatingCount++;
        
        const rater = r.rater_id || r.eater_id;
        if (rater) {
          mRatings[rater] = norm;
        }
    }
    
    if (mealRatingCount > 0) {
      memberRatings[m.id] = mRatings;
    }
    
    const avgScore = mealRatingCount > 0 ? (mealTotalScore / mealRatingCount) : null;

    if (avgScore !== null) {
      // Taste stats: each rater's score vs. this meal's consensus average
      for (const raterId in mRatings) {
        if (!memberTasteStats[raterId]) memberTasteStats[raterId] = [];
        memberTasteStats[raterId].push({ eaten_on: m.eaten_on, userScore: mRatings[raterId], mealAvgScore: avgScore });
      }

      // 1. Effort
      const effort = m.effort ?? m.dishes?.effort;
      if (effort !== null && effort !== undefined && effortStats[effort]) {
        effortStats[effort].score += avgScore;
        effortStats[effort].count += 1;
      }
      
      // 4. Cuisine
      const cuisine = m.dishes?.cuisine?.trim();
      if (cuisine) {
        if (!cuisineStats[cuisine]) cuisineStats[cuisine] = { count: 0, scores: [] };
        cuisineStats[cuisine].count += 1;
        cuisineStats[cuisine].scores.push(avgScore);
      }
    }
    
    // 5. Rotation
    if (m.repeat_desire !== null && m.repeat_desire !== undefined) {
      rotationCount++;
      if (m.repeat_desire === 2) stapleCount++; // 2 = staple
    }
    
    // 6. Health
    if (m.dishes?.health_score) {
      healthScores.push(m.dishes.health_score);
    }
    
    return {
      date: new Date(m.eaten_on).toLocaleDateString(),
      score: avgScore !== null ? avgScore * 100 : 0
    }
  }).filter(Boolean) || []

  // Compile Effort
  const effortMetrics = Object.values(effortStats).map((e: any) => ({
    label: e.label,
    avg: e.count > 0 ? Math.round((e.score / e.count) * 100) : null,
    count: e.count
  })).filter(e => e.count > 0);

  // Compile Taste Stats: per-member match (own rating vs. dish consensus) and trend (own avg, early vs. late)
  const TREND_THRESHOLD = 0.05; // normalized-score delta (out of 1.0) to call it up/down vs flat
  const tasteStats = [];
  for (const member of members) {
    const ratings = memberTasteStats[member.id] || [];
    if (ratings.length < 3) continue; // not enough rated meals to mean anything

    const avgDiff = ratings.reduce((sum, r) => sum + Math.abs(r.userScore - r.mealAvgScore), 0) / ratings.length;
    const matchScore = Math.round((1.0 - avgDiff) * 100);

    let trend: 'up' | 'down' | 'flat' | null = null;
    let trendDelta: number | null = null;
    if (ratings.length >= 4) {
      // ratings are already in chronological order (meals were processed oldest-first)
      const half = Math.floor(ratings.length / 2);
      const earlyAvg = ratings.slice(0, half).reduce((a, r) => a + r.userScore, 0) / half;
      const lateAvg = ratings.slice(-half).reduce((a, r) => a + r.userScore, 0) / half;
      const delta = lateAvg - earlyAvg;
      trend = delta > TREND_THRESHOLD ? 'up' : delta < -TREND_THRESHOLD ? 'down' : 'flat';
      trendDelta = Math.round(delta * 100);
    }

    tasteStats.push({
      member: member.display_name,
      score: matchScore,
      ratedMeals: ratings.length,
      trend,
      trendDelta
    });
  }

  // Ingredient flavor profile: server-aggregated over canonicalized ingredients
  // (see get_flavor_profile / dish_ingredients_canonical) instead of raw-text stats.
  const { data: flavorProfile } = await adminSupabase
    .rpc('get_flavor_profile', { p_scope: 'party', p_id: id })

  const CATEGORY_LABELS: Record<string, string> = {
    spice: 'Spices', herb: 'Herbs', protein: 'Proteins', produce: 'Produce',
    dairy: 'Dairy', grain: 'Grains', condiment: 'Condiments', other: 'Other',
  }

  const byCategory: Record<string, any[]> = {}
  for (const entry of flavorProfile || []) {
    if (!byCategory[entry.category]) byCategory[entry.category] = []
    byCategory[entry.category].push(entry)
  }
  const ingredientsByCategory = Object.entries(byCategory)
    .map(([category, entries]) => ({
      category,
      label: CATEGORY_LABELS[category] || category,
      entries: entries.sort((a, b) => b.loved_pct - a.loved_pct),
    }))
    .sort((a, b) => b.entries.length - a.entries.length)

  // Compile Cuisine
  const cuisineMetrics = Object.entries(cuisineStats).map(([name, data]) => {
    const avg = data.scores.length > 0 ? data.scores.reduce((a,b)=>a+b,0)/data.scores.length : 0;
    return {
      name,
      count: data.count,
      avg: Math.round(avg * 100)
    }
  }).sort((a,b) => b.count - a.count);

  // Compile Health
  const avgHealth = healthScores.length > 0 ? Math.round(healthScores.reduce((a,b)=>a+b,0)/healthScores.length) : null;
  const indulgentCount = healthScores.filter(s => s < 40).length;
  const healthyCount = healthScores.filter(s => s >= 70).length;

  const advancedMetrics = {
    effort: effortMetrics,
    tasteStats: tasteStats.sort((a,b)=>b.score-a.score),
    ingredientsByCategory,
    cuisines: cuisineMetrics,
    rotation: {
      total: rotationCount,
      staples: stapleCount,
      hitRate: rotationCount > 0 ? Math.round((stapleCount / rotationCount) * 100) : 0
    },
    health: {
      avg: avgHealth,
      indulgent: indulgentCount,
      healthy: healthyCount,
      total: healthScores.length
    }
  };

  const { data: recipeSuggestions } = await adminSupabase
    .rpc('suggest_recipes_for_party', { p_party_id: id, p_match_count: 5 })

  const { data: logs } = await adminSupabase
    .from('generation_logs')
    .select('*')
    .eq('entity_id', id)
    .order('created_at', { ascending: false })

  // Same staleness check the trigger-insight route uses to decide whether a
  // run is needed: has a member/meal/rating change (which bumps parties.updated_at)
  // happened since the insight was last generated?
  const insightNeedsRefresh = !insight || new Date(party.updated_at) > new Date(insight.updated_at)

  const combinedParty = {
    ...party,
    userCount: members?.length || 0,
    insight,
    insightNeedsRefresh,
    members,
    meals,
    chartData,
    logs: logs || [],
    advancedMetrics,
    recipeSuggestions: recipeSuggestions || []
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8 text-black">
      <div className="max-w-6xl mx-auto">
        <PartyDetailClient party={combinedParty} />
      </div>
    </div>
  )
}
