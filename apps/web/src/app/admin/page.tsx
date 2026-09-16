import { createClient } from '@/utils/supabase/server'
import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { redirect } from 'next/navigation'
import AdminDashboardClient from './AdminDashboardClient'

export default async function AdminPage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/admin/login')
  }

  // Use Service Role to bypass RLS for admin dashboard
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  // Fetch all parties
  const { data: parties, error: partiesError } = await adminSupabase
    .from('parties')
    .select('id, name, is_public, created_at, updated_at')
    .order('created_at', { ascending: false })
  
  if (partiesError) {
    console.error('Error fetching parties:', partiesError)
  }

  // Fetch all insights
  const { data: insights } = await adminSupabase
    .from('party_insights')
    .select('party_id, summary_sentence, updated_at')

  // Count meals for each party
  // We can do this efficiently using RPC or aggregating locally since it's just 10 parties
  // Actually, we can fetch meal_parties and group by party_id
  const { data: mealParties } = await adminSupabase
    .from('meal_parties')
    .select('party_id, meal_id')
  
  const mealCountMap = new Map<string, number>()
  if (mealParties) {
    mealParties.forEach(mp => {
      mealCountMap.set(mp.party_id, (mealCountMap.get(mp.party_id) || 0) + 1)
    })
  }

  // Count users for each party
  const { data: partyMembers, error: membersError } = await adminSupabase
    .from('party_members')
    .select('party_id, user_id')
  
  if (membersError) {
    console.error('Error fetching members:', membersError)
  }

  const memberCountMap = new Map<string, number>()
  if (partyMembers) {
    partyMembers.forEach(pm => {
      memberCountMap.set(pm.party_id, (memberCountMap.get(pm.party_id) || 0) + 1)
    })
  }

  // Prepare combined data
  const combinedData = (parties || []).map(p => {
    const insight = insights?.find(i => i.party_id === p.id)
    return {
      ...p,
      mealCount: mealCountMap.get(p.id) || 0,
      userCount: memberCountMap.get(p.id) || 0,
      insightSummary: insight?.summary_sentence,
      insightUpdatedAt: insight?.updated_at
    }
  })

  return (
    <div className="min-h-screen bg-gray-50 p-8 text-black">
      <div className="max-w-6xl mx-auto">
        <header className="mb-8">
          <h1 className="text-3xl font-bold">Admin Dashboard</h1>
        </header>
        
        <AdminDashboardClient initialData={combinedData} />
      </div>
    </div>
  )
}
