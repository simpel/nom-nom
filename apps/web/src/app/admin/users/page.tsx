import { createClient } from '@/utils/supabase/server'
import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { redirect } from 'next/navigation'
import UsersListClient from './UsersListClient'

async function fetchAllAuthEmails(adminSupabase: any) {
  const emailById = new Map<string, string>()
  let page = 1
  const perPage = 1000

  // Bounded loop: stop once a page comes back short (last page) or after a
  // sane cap, so a runaway user count can't turn this into an infinite fetch.
  for (let i = 0; i < 20; i++) {
    const { data, error } = await adminSupabase.auth.admin.listUsers({ page, perPage })
    if (error || !data) break

    for (const u of data.users) {
      if (u.email) emailById.set(u.id, u.email)
    }

    if (data.users.length < perPage) break
    page++
  }

  return emailById
}

export default async function UsersListPage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/admin/login')
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  const [{ data: profiles, error: profilesError }, emailById, { data: meals }, { data: partyMembers }] =
    await Promise.all([
      adminSupabase
        .from('profiles')
        .select('id, display_name, first_name, last_name, avatar_emoji, photo_path, created_at, subscription_status, subscription_expires_at, onboarding_completed_at')
        .order('created_at', { ascending: false }),
      fetchAllAuthEmails(adminSupabase),
      adminSupabase.from('meals').select('created_by, eaten_on'),
      adminSupabase.from('party_members').select('party_id, user_id')
    ])

  if (profilesError) {
    console.error('Error fetching profiles:', profilesError)
  }

  const mealStatsByUser = new Map<string, { count: number; lastEatenOn: string | null }>()
  for (const m of meals || []) {
    const existing = mealStatsByUser.get(m.created_by) || { count: 0, lastEatenOn: null }
    existing.count += 1
    if (!existing.lastEatenOn || m.eaten_on > existing.lastEatenOn) {
      existing.lastEatenOn = m.eaten_on
    }
    mealStatsByUser.set(m.created_by, existing)
  }

  const partyIdsByUser = new Map<string, Set<string>>()
  for (const pm of partyMembers || []) {
    const set = partyIdsByUser.get(pm.user_id) || new Set<string>()
    set.add(pm.party_id)
    partyIdsByUser.set(pm.user_id, set)
  }

  const now = Date.now()
  const users = (profiles || []).map(p => {
    const mealStats = mealStatsByUser.get(p.id) || { count: 0, lastEatenOn: null }
    const isPro = (p.subscription_status === 'active' || p.subscription_status === 'canceled')
      && !!p.subscription_expires_at
      && new Date(p.subscription_expires_at).getTime() > now

    return {
      id: p.id,
      name: p.display_name || [p.first_name, p.last_name].filter(Boolean).join(' ') || 'Unnamed',
      email: emailById.get(p.id) || null,
      avatarEmoji: p.avatar_emoji,
      photoPath: p.photo_path,
      createdAt: p.created_at,
      onboardingCompletedAt: p.onboarding_completed_at,
      subscriptionStatus: p.subscription_status,
      subscriptionExpiresAt: p.subscription_expires_at,
      isPro,
      mealCount: mealStats.count,
      lastMealDate: mealStats.lastEatenOn,
      partyCount: partyIdsByUser.get(p.id)?.size || 0
    }
  })

  return (
    <div className="min-h-screen bg-gray-50 p-8 text-black">
      <div className="max-w-7xl mx-auto">
        <header className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold">Users</h1>
            <p className="text-gray-500">{users.length} user{users.length === 1 ? '' : 's'}</p>
          </div>
          <a href="/admin">
            <button className="px-4 py-2 border rounded-md hover:bg-gray-50 text-sm font-medium bg-white">
              Back to Admin
            </button>
          </a>
        </header>

        <UsersListClient initialData={users} />
      </div>
    </div>
  )
}
