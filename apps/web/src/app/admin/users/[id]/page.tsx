import { createClient } from '@/utils/supabase/server'
import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { redirect } from 'next/navigation'
import UserDetailClient from './UserDetailClient'

const DAY_MS = 1000 * 60 * 60 * 24

function normalizeReaction(react: number | null | undefined) {
  if (react === -1) return 0.0
  if (react === 1) return 0.2
  if (react === 2) return 0.4
  if (react === 3) return 0.6
  if (react === 4) return 0.8
  if (react === 5) return 1.0
  return null
}

export default async function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/admin/login')
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  const { id } = await params

  const { data: profile, error: profileError } = await adminSupabase
    .from('profiles')
    .select('*')
    .eq('id', id)
    .single()

  if (profileError || !profile) {
    return <div className="p-8">User not found</div>
  }

  const { data: authUser } = await adminSupabase.auth.admin.getUserById(id)

  const { data: loggedMeals } = await adminSupabase
    .from('meals')
    .select('id, eaten_on, dishes ( name, cuisine, effort, health_score )')
    .eq('created_by', id)
    .order('eaten_on', { ascending: false })

  const { data: myRatings } = await adminSupabase
    .from('meal_ratings')
    .select('meal_id, reaction, created_at, meals ( eaten_on, dishes ( name, cuisine, effort, ingredients, health_score ) )')
    .eq('rater_id', id)
    .order('created_at', { ascending: false })

  const ratedMealIds = [...new Set((myRatings || []).map(r => r.meal_id))]

  const { data: allRatingsOnThoseMeals } = ratedMealIds.length > 0
    ? await adminSupabase
        .from('meal_ratings')
        .select('meal_id, reaction')
        .in('meal_id', ratedMealIds)
    : { data: [] }

  const { data: partyMemberships } = await adminSupabase
    .from('party_members')
    .select('party_id, joined_at, parties ( id, name, is_public )')
    .eq('user_id', id)

  const { data: favorites } = await adminSupabase
    .from('recipe_favorites')
    .select('recipe_id, dishes ( id, name, cuisine )')
    .eq('user_id', id)

  const { data: insight } = await adminSupabase
    .from('profile_insights')
    .select('*')
    .eq('profile_id', id)
    .single()

  const { data: logs } = await adminSupabase
    .from('generation_logs')
    .select('*')
    .eq('entity_id', id)
    .eq('generation_type', 'profile_insight')
    .order('created_at', { ascending: false })

  // --- Engagement & retention ---
  const mealCount = loggedMeals?.length || 0
  const eatenDates = (loggedMeals || []).map(m => m.eaten_on).sort()
  const firstMealDate = eatenDates[0] || null
  const lastMealDate = eatenDates[eatenDates.length - 1] || null
  const daysSinceLastMeal = lastMealDate ? Math.floor((Date.now() - new Date(lastMealDate).getTime()) / DAY_MS) : null
  const weeksActive = firstMealDate && lastMealDate
    ? Math.max(1, (new Date(lastMealDate).getTime() - new Date(firstMealDate).getTime()) / (DAY_MS * 7))
    : null
  const mealsPerWeek = weeksActive && mealCount > 0 ? Math.round((mealCount / weeksActive) * 10) / 10 : null

  const isOnboarded = !!profile.onboarding_completed_at
  const isAtRisk = isOnboarded && (daysSinceLastMeal === null || daysSinceLastMeal > 30)
  const engagement = {
    mealCount,
    firstMealDate,
    lastMealDate,
    daysSinceLastMeal,
    mealsPerWeek,
    isOnboarded,
    isAtRisk,
    healthScores: (loggedMeals || []).map(m => (m as any).dishes?.health_score).filter((s: any) => s != null)
  }

  // --- Taste profile & pickiness ---
  const consensusByMeal = new Map<string, number[]>()
  for (const r of allRatingsOnThoseMeals || []) {
    const norm = normalizeReaction(r.reaction)
    if (norm === null) continue
    const arr = consensusByMeal.get(r.meal_id) || []
    arr.push(norm)
    consensusByMeal.set(r.meal_id, arr)
  }

  const cuisineStats: Record<string, number[]> = {}
  const effortStats: Record<number, number[]> = {}
  const matchDiffs: number[] = []

  for (const r of myRatings || []) {
    const userScore = normalizeReaction(r.reaction)
    if (userScore === null) continue
    const dish = (r as any).meals?.dishes
    if (!dish) continue

    if (dish.cuisine) {
      const key = dish.cuisine.trim()
      if (!cuisineStats[key]) cuisineStats[key] = []
      cuisineStats[key].push(userScore)
    }
    if (dish.effort !== null && dish.effort !== undefined) {
      if (!effortStats[dish.effort]) effortStats[dish.effort] = []
      effortStats[dish.effort].push(userScore)
    }

    const consensus = consensusByMeal.get(r.meal_id)
    if (consensus && consensus.length > 0) {
      const avg = consensus.reduce((a, b) => a + b, 0) / consensus.length
      matchDiffs.push(Math.abs(userScore - avg))
    }
  }

  const cuisineMetrics = Object.entries(cuisineStats)
    .map(([name, scores]) => ({
      name,
      avg: Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 100),
      count: scores.length
    }))
    .sort((a, b) => b.count - a.count)

  // Ingredient flavor profile: server-aggregated over canonicalized ingredients
  // (see get_flavor_profile / dish_ingredients_canonical) instead of raw-text stats.
  const { data: flavorProfile } = await adminSupabase
    .rpc('get_flavor_profile', { p_scope: 'person', p_id: id })

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

  const effortLabels: Record<number, string> = { 0: 'Breeze (0-15m)', 1: 'Normal (15-30m)', 2: 'Project (30m+)' }
  const effortMetrics = Object.entries(effortStats).map(([effort, scores]) => ({
    label: effortLabels[Number(effort)] ?? effort,
    avg: Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 100),
    count: scores.length
  }))

  const pickiness = matchDiffs.length >= 3
    ? {
        matchScore: Math.round((1 - matchDiffs.reduce((a, b) => a + b, 0) / matchDiffs.length) * 100),
        ratedMeals: matchDiffs.length
      }
    : null

  const tasteProfile = {
    cuisines: cuisineMetrics,
    ingredientsByCategory,
    effort: effortMetrics,
    pickiness
  }

  // --- Subscription / misc ---
  const isPro = (profile.subscription_status === 'active' || profile.subscription_status === 'canceled')
    && !!profile.subscription_expires_at
    && new Date(profile.subscription_expires_at).getTime() > Date.now()

  const parties = (partyMemberships || []).map((pm: any) => ({
    id: pm.parties?.id,
    name: pm.parties?.name,
    isPublic: pm.parties?.is_public,
    joinedAt: pm.joined_at
  })).filter((p: any) => p.id)

  const insightNeedsRefresh = !insight || (lastMealDate && new Date(lastMealDate) > new Date(insight.updated_at))

  const combinedUser = {
    ...profile,
    email: authUser?.user?.email || null,
    isPro,
    engagement,
    tasteProfile,
    parties,
    favorites: (favorites || []).map((f: any) => f.dishes).filter(Boolean),
    insight,
    insightNeedsRefresh,
    logs: logs || []
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8 text-black">
      <div className="max-w-6xl mx-auto">
        <UserDetailClient user={combinedUser} />
      </div>
    </div>
  )
}
