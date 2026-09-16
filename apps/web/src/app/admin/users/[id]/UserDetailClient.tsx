'use client'

import { useRouter } from 'next/navigation'
import Link from 'next/link'
import GenerationLogsClient from '@/components/admin/GenerationLogsClient'
import { generateProfileInsightAction } from '../../actions'
import { toast } from 'sonner'

export default function UserDetailClient({ user }: { user: any }) {
  const router = useRouter()

  const handleGenerate = () => {
    toast.promise(
      generateProfileInsightAction(user.id),
      {
        loading: 'Generating insight...',
        success: 'Insight generated successfully!',
        error: (err) => `Failed to generate: ${err.message}`
      }
    )
  }

  const { engagement, tasteProfile, parties = [], favorites = [], insight, insightNeedsRefresh } = user

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white p-6 rounded-lg shadow-sm border">
        <div>
          <h1 className="text-3xl font-bold">
            {user.avatar_emoji ? `${user.avatar_emoji} ` : ''}{user.display_name || [user.first_name, user.last_name].filter(Boolean).join(' ') || 'Unnamed'}
          </h1>
          <p className="text-gray-500 mt-1">{user.email || 'No email on file'}</p>
          <div className="flex items-center gap-2 mt-2">
            {user.isPro ? (
              <span className="inline-flex w-fit items-center rounded-full bg-purple-100 text-purple-700 px-2 py-0.5 text-xs font-medium">
                Pro {user.subscription_expires_at && `· renews/expires ${new Date(user.subscription_expires_at).toLocaleDateString()}`}
              </span>
            ) : (
              <span className="inline-flex w-fit items-center rounded-full bg-gray-100 text-gray-600 px-2 py-0.5 text-xs font-medium">
                Free
              </span>
            )}
            {engagement.isAtRisk && (
              <span className="inline-flex w-fit items-center rounded-full bg-amber-100 text-amber-700 px-2 py-0.5 text-xs font-medium">
                At risk — inactive {engagement.daysSinceLastMeal ?? '∞'}d
              </span>
            )}
            <span className="text-xs text-gray-400" suppressHydrationWarning>
              Joined {new Date(user.created_at).toLocaleDateString()}
            </span>
          </div>
        </div>
        <div className="flex gap-4">
          <button
            onClick={() => router.push('/admin/users')}
            className="px-4 py-2 border rounded-md hover:bg-gray-50 text-sm font-medium"
          >
            Back to Users
          </button>
          <button
            onClick={handleGenerate}
            className="bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800 disabled:opacity-50 text-sm font-medium"
          >
            {insightNeedsRefresh ? 'Generate Insight' : 'Regenerate Insight'}
          </button>
        </div>
      </div>

      {/* Engagement & Retention */}
      <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
        <h2 className="text-xl font-semibold">Engagement & Retention</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Stat label="Meals logged" value={engagement.mealCount} />
          <Stat label="Meals / week" value={engagement.mealsPerWeek ?? '—'} />
          <Stat
            label="Last active"
            value={engagement.lastMealDate ? new Date(engagement.lastMealDate).toLocaleDateString() : 'Never'}
          />
          <Stat label="Parties joined" value={parties.length} />
        </div>
        {!engagement.isOnboarded && (
          <p className="text-sm text-amber-600 bg-amber-50 border border-amber-200 rounded-md p-3">
            Onboarding not completed yet.
          </p>
        )}
        {engagement.isOnboarded && engagement.mealCount === 0 && (
          <p className="text-sm text-amber-600 bg-amber-50 border border-amber-200 rounded-md p-3">
            Onboarded but has never logged a meal.
          </p>
        )}
      </div>

      {/* Taste Profile & Pickiness */}
      <div className="bg-white p-6 rounded-lg shadow-sm border space-y-6">
        <h2 className="text-xl font-semibold">Taste Profile & Pickiness</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-3">
            <h3 className="text-sm font-semibold text-gray-500 uppercase">Pickiness</h3>
            {tasteProfile.pickiness ? (
              <div className="bg-gray-50 p-4 rounded-md border flex justify-between items-center">
                <div>
                  <p className="text-2xl font-bold text-gray-800">{tasteProfile.pickiness.matchScore}%</p>
                  <p className="text-xs text-gray-400">
                    match with group consensus across {tasteProfile.pickiness.ratedMeals} rated meals
                  </p>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500">Not enough rated meals to calculate.</p>
            )}

            <h3 className="text-sm font-semibold text-gray-500 uppercase pt-2">Effort tolerance</h3>
            {tasteProfile.effort.length === 0 ? (
              <p className="text-sm text-gray-500">Not enough data.</p>
            ) : (
              <div className="bg-gray-50 p-4 rounded-md border space-y-2">
                {tasteProfile.effort.map((e: any, i: number) => (
                  <div key={i} className="flex justify-between items-center text-sm">
                    <span className="font-medium text-gray-700">{e.label}</span>
                    <div className="flex items-center gap-2">
                      <div className="w-32 h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div className="h-full bg-blue-500" style={{ width: `${e.avg}%` }} />
                      </div>
                      <span className="font-bold w-10 text-right">{e.avg}%</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="space-y-3">
            <h3 className="text-sm font-semibold text-gray-500 uppercase">Top cuisines</h3>
            <div className="flex flex-wrap gap-2">
              {tasteProfile.cuisines.slice(0, 6).map((c: any, i: number) => (
                <span key={i} className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-sm">
                  {c.name} ({c.avg}%, {c.count})
                </span>
              ))}
              {tasteProfile.cuisines.length === 0 && <span className="text-gray-400 text-sm">Not enough data</span>}
            </div>

            <h3 className="text-sm font-semibold text-gray-500 uppercase pt-2">Flavor profile</h3>
            {tasteProfile.ingredientsByCategory.length === 0 && (
              <span className="text-xs text-gray-400">N/A</span>
            )}
            {tasteProfile.ingredientsByCategory.map((group: any) => (
              <div key={group.category} className="space-y-1">
                <p className="text-xs font-semibold text-gray-400 uppercase">{group.label}</p>
                <div className="flex flex-wrap gap-2">
                  {group.entries.map((entry: any) => (
                    <span
                      key={entry.canonical_ingredient_id}
                      className={`text-xs px-2 py-1 rounded ${
                        entry.sentiment === 'loved' ? 'bg-green-100 text-green-800' :
                        entry.sentiment === 'polarizing' ? 'bg-orange-100 text-orange-800' :
                        entry.sentiment === 'disliked' ? 'bg-red-100 text-red-800' :
                        'bg-gray-200 text-gray-700'
                      }`}
                      title={`${entry.sample_size} ratings`}
                    >
                      {entry.canonical_name} ({entry.loved_pct}%)
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* AI Generated Insight */}
      {!insight ? (
        <div className="bg-white p-8 rounded-lg shadow-sm border text-center text-gray-500">
          No AI insight generated yet. Click Generate Insight to start.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
            <h2 className="text-xl font-semibold">AI Generated Summary</h2>
            <p className="text-gray-800 italic text-lg">{insight.summary_sentence}</p>
            <div className="pt-4 border-t">
              <h3 className="font-medium text-gray-700 mb-2">Food Profile</h3>
              <p className="text-gray-600">{insight.food_profile}</p>
            </div>
            {insight.health_analysis && (
              <div className="pt-4 border-t">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-medium text-gray-700">Health Analysis</h3>
                  <span className={`text-sm font-bold px-2 py-0.5 rounded-full ${insight.health_analysis.score >= 80 ? 'bg-green-100 text-green-700' : insight.health_analysis.score >= 50 ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'}`}>
                    {insight.health_analysis.score}/100
                  </span>
                </div>
                <p className="text-gray-600 mb-3">{insight.health_analysis.summary}</p>
                {insight.health_analysis.details?.length > 0 && (
                  <ul className="list-disc pl-5 text-sm text-gray-600 space-y-1">
                    {insight.health_analysis.details.map((detail: string, i: number) => (
                      <li key={i}>{detail}</li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border space-y-6">
            <div>
              <h3 className="font-semibold text-gray-800 mb-3">Recommended Recipes</h3>
              <div className="space-y-2">
                {(insight.recommendations || []).map((rec: any, i: number) => (
                  <div key={i} className="border rounded-md p-3">
                    {rec.dish_id ? (
                      <Link href={`/admin/recipes/${rec.dish_id}`} className="font-medium text-blue-600 hover:underline">
                        {rec.title}
                      </Link>
                    ) : (
                      <p className="font-medium">{rec.title}</p>
                    )}
                    <p className="text-sm text-gray-500">{rec.description}</p>
                  </div>
                ))}
                {(!insight.recommendations || insight.recommendations.length === 0) && (
                  <span className="text-gray-400 text-sm">Not available</span>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Parties */}
      <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
        <h2 className="text-xl font-semibold">Parties</h2>
        {parties.length === 0 ? (
          <p className="text-sm text-gray-500">Not a member of any party.</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {parties.map((p: any) => (
              <Link key={p.id} href={`/admin/parties/${p.id}`} className="block">
                <div className="border p-4 rounded-md hover:bg-gray-50 transition-colors">
                  <p className="font-semibold">{p.name}</p>
                  <p className="text-xs text-gray-400 mt-1" suppressHydrationWarning>
                    Joined {new Date(p.joinedAt).toLocaleDateString()}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      {/* Favorites */}
      {favorites.length > 0 && (
        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Favorited Recipes</h2>
          <div className="flex flex-wrap gap-2">
            {favorites.map((f: any) => (
              <Link key={f.id} href={`/admin/recipes/${f.id}`} className="bg-gray-50 border px-3 py-1 rounded-full text-sm hover:bg-gray-100">
                {f.name}
              </Link>
            ))}
          </div>
        </div>
      )}

      <div className="space-y-4">
        <h2 className="text-2xl font-semibold">Generation Logs</h2>
        <GenerationLogsClient logs={user.logs || []} />
      </div>
    </div>
  )
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="bg-gray-50 p-4 rounded-md border">
      <p className="text-xs text-gray-500 uppercase tracking-wide font-semibold">{label}</p>
      <p className="text-2xl font-bold text-gray-800">{value}</p>
    </div>
  )
}
