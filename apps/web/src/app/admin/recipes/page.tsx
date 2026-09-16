import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { createClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'
import RecipesListClient from './RecipesListClient'

export default async function RecipesListPage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/admin/login')
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  const { data: recipes, error } = await adminSupabase
    .from('dishes')
    .select('id, name, cuisine, tags, effort, serves, embedding, health_score, health_verdict, created_at, updated_at')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching recipes:', error)
  }

  const { data: meals } = await adminSupabase
    .from('meals')
    .select('dish_id')

  const mealCountMap = new Map<string, number>()
  if (meals) {
    meals.forEach(m => {
      mealCountMap.set(m.dish_id, (mealCountMap.get(m.dish_id) || 0) + 1)
    })
  }

  const combinedData = (recipes || []).map(r => ({
    id: r.id,
    name: r.name,
    cuisine: r.cuisine,
    tags: r.tags,
    effort: r.effort,
    serves: r.serves,
    hasEmbedding: r.embedding !== null,
    healthScore: r.health_score,
    healthVerdict: r.health_verdict,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
    mealCount: mealCountMap.get(r.id) || 0,
  }))

  return (
    <div className="min-h-screen bg-gray-50 p-8 text-black">
      <div className="max-w-7xl mx-auto">
        <header className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold">Recipes</h1>
            <p className="text-gray-500">{combinedData.length} recipe{combinedData.length === 1 ? '' : 's'}</p>
          </div>
          <a href="/admin">
            <button className="px-4 py-2 border rounded-md hover:bg-gray-50 text-sm font-medium bg-white">
              Back to Admin
            </button>
          </a>
        </header>

        <RecipesListClient initialData={combinedData} />
      </div>
    </div>
  )
}
