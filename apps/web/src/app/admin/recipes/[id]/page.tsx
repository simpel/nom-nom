import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import { createClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import GenerationLogsClient from '@/components/admin/GenerationLogsClient'
import GenerateHealthScoreButton from '@/components/admin/GenerateHealthScoreButton'

export default async function RecipeDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/admin/login')
  }

  const { id } = await params;
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
  const adminSupabase = createSupabaseClient(supabaseUrl, supabaseServiceKey)

  const { data: recipe, error } = await adminSupabase
    .from('dishes')
    .select('*')
    .eq('id', id)
    .single()

  if (error || !recipe) {
    return <div className="p-8">Recipe not found</div>
  }

  const healthBreakdown = recipe.health_breakdown as {
    positives?: string[]
    considerations?: string[]
    cooking_impact?: string
    macros?: { calories?: number; protein_g?: number; carbs_g?: number; fat_g?: number }
  } | null

  const { data: logs } = await adminSupabase
    .from('generation_logs')
    .select('*')
    .eq('entity_id', id)
    .order('created_at', { ascending: false })

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-8">
      <div className="flex justify-between items-center bg-white p-6 rounded-lg shadow-sm border">
        <div>
          <h1 className="text-3xl font-bold">{recipe.name}</h1>
          <p className="text-gray-500 mt-1">
            Cuisine: {recipe.cuisine || 'Unknown'}
          </p>
        </div>
        <div className="flex gap-2">
          <GenerateHealthScoreButton recipeId={id} />
          <Link href="/admin">
            <button className="px-4 py-2 border rounded-md hover:bg-gray-50 text-sm font-medium">
              Back to Admin
            </button>
          </Link>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Health Score</h2>
          {recipe.health_score != null && (
            <div className="flex items-center gap-2">
              <span className="text-2xl font-bold">{recipe.health_score}<span className="text-sm font-normal text-gray-400">/100</span></span>
              <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-50 text-green-800 border border-green-100">
                {recipe.health_verdict || 'N/A'}
              </span>
            </div>
          )}
        </div>

        {recipe.health_score == null ? (
          <p className="text-sm text-gray-400 italic">No health score generated yet.</p>
        ) : (
          <div className="space-y-4 text-sm">
            {recipe.health_rationale && (
              <p className="text-gray-700">{recipe.health_rationale}</p>
            )}

            {healthBreakdown?.macros && (
              <div className="grid grid-cols-4 gap-3">
                {healthBreakdown.macros.calories != null && (
                  <div className="p-3 bg-gray-50 rounded border text-center">
                    <p className="text-lg font-semibold">{healthBreakdown.macros.calories}</p>
                    <p className="text-xs text-gray-500">Calories</p>
                  </div>
                )}
                {healthBreakdown.macros.protein_g != null && (
                  <div className="p-3 bg-gray-50 rounded border text-center">
                    <p className="text-lg font-semibold">{healthBreakdown.macros.protein_g}g</p>
                    <p className="text-xs text-gray-500">Protein</p>
                  </div>
                )}
                {healthBreakdown.macros.carbs_g != null && (
                  <div className="p-3 bg-gray-50 rounded border text-center">
                    <p className="text-lg font-semibold">{healthBreakdown.macros.carbs_g}g</p>
                    <p className="text-xs text-gray-500">Carbs</p>
                  </div>
                )}
                {healthBreakdown.macros.fat_g != null && (
                  <div className="p-3 bg-gray-50 rounded border text-center">
                    <p className="text-lg font-semibold">{healthBreakdown.macros.fat_g}g</p>
                    <p className="text-xs text-gray-500">Fat</p>
                  </div>
                )}
              </div>
            )}

            {healthBreakdown?.positives && healthBreakdown.positives.length > 0 && (
              <div>
                <p className="font-medium text-green-800 mb-1">Positives</p>
                <ul className="list-disc list-inside space-y-1 text-gray-700">
                  {healthBreakdown.positives.map((p, i) => <li key={i}>{p}</li>)}
                </ul>
              </div>
            )}

            {healthBreakdown?.considerations && healthBreakdown.considerations.length > 0 && (
              <div>
                <p className="font-medium text-amber-800 mb-1">Considerations</p>
                <ul className="list-disc list-inside space-y-1 text-gray-700">
                  {healthBreakdown.considerations.map((c, i) => <li key={i}>{c}</li>)}
                </ul>
              </div>
            )}

            {healthBreakdown?.cooking_impact && (
              <div>
                <p className="font-medium text-gray-800 mb-1">Cooking Technique</p>
                <p className="text-gray-700">{healthBreakdown.cooking_impact}</p>
              </div>
            )}
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Details</h2>
          <div className="text-sm space-y-2">
            <p><span className="font-medium">Tags:</span> {recipe.tags?.join(', ')}</p>
            <p><span className="font-medium">Effort:</span> {recipe.effort}</p>
            <p><span className="font-medium">Serves:</span> {recipe.serves}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Ingredients</h2>
          {recipe.ingredients && recipe.ingredients.length > 0 ? (
            <ul className="text-sm space-y-1 list-disc list-inside">
              {recipe.ingredients.map((ing: { quantity?: string; measurement?: string; ingredient: string }, i: number) => (
                <li key={i}>
                  {[ing.quantity, ing.measurement].filter(Boolean).join(' ')} {ing.ingredient}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-gray-400 italic">No ingredients saved.</p>
          )}

          <h2 className="text-xl font-semibold pt-2">Instructions</h2>
          {recipe.instructions && recipe.instructions.length > 0 ? (
            <ol className="text-sm space-y-1 list-decimal list-inside">
              {recipe.instructions.map((step: string, i: number) => (
                <li key={i}>{step}</li>
              ))}
            </ol>
          ) : (
            <p className="text-sm text-gray-400 italic">No instructions saved.</p>
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
