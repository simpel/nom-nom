import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { createClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import GenerationLogsClient from '@/components/admin/GenerationLogsClient'

export default async function MealDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/admin/login')
  }

  const { id } = await params;
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  const { data: meal, error } = await adminSupabase
    .from('meals')
    .select(`
      *,
      dishes (id, name, cuisine),
      meal_ratings (
        reaction,
        rater_id,
        eater_id
      ),
      meal_parties (
        parties (id, name)
      )
    `)
    .eq('id', id)
    .single()

  if (error || !meal) {
    return <div className="p-8">Meal not found</div>
  }

  const raterIds = (meal.meal_ratings || []).map((r: any) => r.rater_id).filter(Boolean)
  const eaterIds = (meal.meal_ratings || []).map((r: any) => r.eater_id).filter(Boolean)

  const [{ data: raterProfiles }, { data: eaters }] = await Promise.all([
    raterIds.length
      ? adminSupabase.from('profiles').select('id, first_name, last_name, display_name').in('id', raterIds)
      : Promise.resolve({ data: [] as any[] }),
    eaterIds.length
      ? adminSupabase.from('eaters').select('id, name').in('id', eaterIds)
      : Promise.resolve({ data: [] as any[] }),
  ])

  const profileById = new Map((raterProfiles || []).map((p: any) => [p.id, p]))
  const eaterById = new Map((eaters || []).map((e: any) => [e.id, e]))

  const ratingsWithNames = (meal.meal_ratings || []).map((r: any) => {
    if (r.rater_id) {
      const profile = profileById.get(r.rater_id)
      const name = profile?.first_name ? `${profile.first_name} ${profile.last_name || ''}`.trim() : profile?.display_name
      return { reaction: r.reaction, name: name || 'Unknown' }
    }
    return { reaction: r.reaction, name: eaterById.get(r.eater_id)?.name || 'Unknown' }
  })

  const { data: logs } = await adminSupabase
    .from('generation_logs')
    .select('*')
    .eq('entity_id', id)
    .order('created_at', { ascending: false })

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-8">
      <div className="flex justify-between items-center bg-white p-6 rounded-lg shadow-sm border">
        <div>
          <h1 className="text-3xl font-bold">Meal: {meal.dishes?.name}</h1>
          <p className="text-gray-500 mt-1">
            Eaten on: {meal.eaten_on} | Recipe: <Link href={`/admin/recipes/${meal.dishes?.id}`} className="text-blue-600 hover:underline">{meal.dishes?.name}</Link>
          </p>
        </div>
        <Link href="/admin">
          <button className="px-4 py-2 border rounded-md hover:bg-gray-50 text-sm font-medium">
            Back to Admin
          </button>
        </Link>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Notes & Details</h2>
          <p className="text-gray-700 italic">{meal.notes || 'No notes.'}</p>
          <div className="pt-4 border-t text-sm">
            <p><span className="font-medium">Effort:</span> {meal.effort}</p>
            <p><span className="font-medium">Repeat Desire:</span> {meal.repeat_desire}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Ratings</h2>
          {ratingsWithNames.length > 0 ? (
            <div className="space-y-2">
              {ratingsWithNames.map((rating: any, i: number) => (
                <div key={i} className="flex justify-between p-2 border-b last:border-0 text-sm">
                  <span>{rating.name}</span>
                  <span className="font-bold">{rating.reaction}/5</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No ratings yet.</p>
          )}
        </div>
      </div>

      <div className="space-y-4">
        <h2 className="text-2xl font-semibold">Generation Logs</h2>
        <GenerationLogsClient logs={logs || []} />
      </div>
    </div>
  )
}
