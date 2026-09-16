'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from "recharts"
import { ChartConfig, ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import Link from 'next/link'
import GenerationLogsClient from '@/components/admin/GenerationLogsClient'

const chartConfig = {
  score: {
    label: "Score",
    color: "#2563eb",
  },
} satisfies ChartConfig

import { generatePartyInsightAction } from '../../actions'
import { toast } from 'sonner'

export default function PartyDetailClient({ party }: { party: any }) {
  const router = useRouter()

  const handleGenerate = () => {
    toast.promise(
      generatePartyInsightAction(party.id),
      {
        loading: 'Generating insights...',
        success: 'Insight generated successfully!',
        error: (err) => `Failed to generate: ${err.message}`
      }
    )
  }

  const { insight, chartData, members = [], advancedMetrics, insightNeedsRefresh, recipeSuggestions = [] } = party

  const effortLabels: Record<number, string> = { 0: 'Breeze', 1: 'Normal', 2: 'Project' }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white p-6 rounded-lg shadow-sm border">
        <div>
          <h1 className="text-3xl font-bold">{party.name}</h1>
          <p className="text-gray-500 mt-1">Users: {party.userCount} | Public: {party.is_public ? 'Yes' : 'No'}</p>
          {insightNeedsRefresh ? (
            <span className="inline-flex w-fit items-center rounded-full bg-amber-100 text-amber-700 px-2 py-0.5 mt-2 text-xs font-medium">
              Insights needs refresh — data changed since last run
            </span>
          ) : (
            <span className="inline-flex w-fit items-center rounded-full bg-green-100 text-green-700 px-2 py-0.5 mt-2 text-xs font-medium">
              Insights up to date
            </span>
          )}
        </div>
        <div className="flex gap-4">
          <button
            onClick={() => router.push('/admin')}
            className="px-4 py-2 border rounded-md hover:bg-gray-50 text-sm font-medium"
          >
            Back to Admin
          </button>
          <button
            onClick={handleGenerate}
            className="bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800 disabled:opacity-50 text-sm font-medium"
          >
            {insightNeedsRefresh ? 'Generate Insights' : 'Regenerate Insights'}
          </button>
        </div>
      </div>

      {/* Advanced Data-Driven Metrics */}
      {advancedMetrics && (
        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-6">
          <h2 className="text-2xl font-semibold border-b pb-4">Data-Driven Metrics</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Hit Rate & Health */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-800">Rotation & Health</h3>
              <div className="bg-gray-50 p-4 rounded-md border flex justify-between items-center">
                <div>
                  <p className="text-sm text-gray-500 uppercase tracking-wide font-semibold">Hit Rate</p>
                  <p className="text-2xl font-bold text-gray-800">{advancedMetrics.rotation.hitRate}%</p>
                  <p className="text-xs text-gray-400">{advancedMetrics.rotation.staples} staples found</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-500 uppercase tracking-wide font-semibold">Avg Health</p>
                  <p className="text-2xl font-bold text-gray-800">{advancedMetrics.health.avg || '--'}/100</p>
                  <p className="text-xs text-gray-400">{advancedMetrics.health.indulgent} indulgent meals</p>
                </div>
              </div>
            </div>

            {/* Effort vs Reward */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-800">Is it worth the effort?</h3>
              <div className="bg-gray-50 p-4 rounded-md border space-y-2">
                {advancedMetrics.effort.length === 0 ? (
                  <p className="text-sm text-gray-500">Not enough data.</p>
                ) : (
                  advancedMetrics.effort.map((e: any, i: number) => (
                    <div key={i} className="flex justify-between items-center text-sm">
                      <span className="font-medium text-gray-700">{e.label}</span>
                      <div className="flex items-center gap-2">
                        <div className="w-32 h-2 bg-gray-200 rounded-full overflow-hidden">
                          <div className="h-full bg-blue-500" style={{ width: `${e.avg}%` }} />
                        </div>
                        <span className="font-bold w-10 text-right">{e.avg}%</span>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Taste Match: how well each member's ratings track the dish consensus, and whether their ratings trend up or down */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-800">Taste Match</h3>
              <div className="bg-gray-50 p-4 rounded-md border space-y-3">
                {advancedMetrics.tasteStats.length === 0 ? (
                  <p className="text-sm text-gray-500">Not enough rated meals to calculate matches.</p>
                ) : (
                  advancedMetrics.tasteStats.map((s: any, i: number) => (
                    <div key={i} className="flex justify-between items-center">
                      <span className="text-sm font-medium">{s.member}</span>
                      <div className="flex items-center gap-2">
                        {s.trend && (
                          <span
                            className={`text-xs font-semibold px-1.5 py-0.5 rounded ${
                              s.trend === 'up' ? 'text-green-700 bg-green-100' :
                              s.trend === 'down' ? 'text-red-700 bg-red-100' :
                              'text-gray-500 bg-gray-200'
                            }`}
                            title={`Their own average rating is trending ${s.trend}`}
                          >
                            {s.trend === 'up' ? '↑' : s.trend === 'down' ? '↓' : '→'}
                          </span>
                        )}
                        <span className="text-sm font-bold text-green-600 bg-green-100 px-2 py-0.5 rounded-full">{s.score}% Match</span>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Ingredient Flavor Profile, grouped by category */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-800">Flavor Profile</h3>
              <div className="bg-gray-50 p-4 rounded-md border space-y-4">
                {advancedMetrics.ingredientsByCategory.length === 0 && (
                  <span className="text-xs text-gray-400">N/A</span>
                )}
                {advancedMetrics.ingredientsByCategory.map((group: any) => (
                  <div key={group.category}>
                    <p className="text-xs font-semibold text-gray-500 uppercase mb-1">{group.label}</p>
                    <div className="flex flex-wrap gap-1">
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
        </div>
      )}

      {/* Recipe Suggestions */}
      <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
        <h2 className="text-xl font-semibold">Top 5 Recipe Suggestions</h2>
        {recipeSuggestions.length === 0 ? (
          <p className="text-sm text-gray-500">
            Not enough rated meals yet to suggest new recipes for this party.
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {recipeSuggestions.map((dish: any) => (
              <Link key={dish.id} href={`/admin/recipes/${dish.id}`} className="block">
                <div className="border p-4 rounded-md hover:bg-gray-50 transition-colors h-full">
                  <p className="font-semibold">{dish.name}</p>
                  {dish.cuisine && <p className="text-sm text-gray-500">{dish.cuisine}</p>}
                  <div className="flex items-center gap-2 mt-2 text-xs text-gray-400">
                    {dish.effort !== null && dish.effort !== undefined && (
                      <span>{effortLabels[dish.effort] ?? dish.effort}</span>
                    )}
                    {dish.health_score !== null && dish.health_score !== undefined && (
                      <span>· {dish.health_score}/100 health</span>
                    )}
                  </div>
                  <span className="inline-flex items-center rounded-full bg-blue-100 text-blue-700 px-2 py-0.5 mt-2 text-xs font-medium">
                    {Math.round(dish.similarity * 100)}% match
                  </span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      {/* AI Generated Insights Section (Existing) */}
      {!insight ? (
        <div className="bg-white p-8 rounded-lg shadow-sm border text-center text-gray-500">
          No AI insights generated yet. Click Generate Insights to start.
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
                  {typeof insight.health_analysis === 'object' && insight.health_analysis.score !== undefined && (
                    <span className={`text-sm font-bold px-2 py-0.5 rounded-full ${insight.health_analysis.score >= 80 ? 'bg-green-100 text-green-700' : insight.health_analysis.score >= 50 ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'}`}>
                      {insight.health_analysis.score}/100
                    </span>
                  )}
                </div>
                <p className="text-gray-600 mb-3">
                  {typeof insight.health_analysis === 'string'
                    ? insight.health_analysis
                    : insight.health_analysis.summary}
                </p>
                {typeof insight.health_analysis === 'object' && insight.health_analysis.details && insight.health_analysis.details.length > 0 && (
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
              <h3 className="font-semibold text-gray-800 mb-3">AI Top Ingredients</h3>
              <div className="flex flex-wrap gap-2">
                {(insight.top_ingredients || []).map((ing: string, i: number) => (
                  <span key={i} className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-sm">
                    {ing}
                  </span>
                ))}
                {(!insight.top_ingredients || insight.top_ingredients.length === 0) && (
                  <span className="text-gray-400 text-sm">Not available</span>
                )}
              </div>
            </div>
            <div className="pt-4 border-t">
              <h3 className="font-semibold text-gray-800 mb-3">AI Ways of Cooking</h3>
              <div className="flex flex-wrap gap-2">
                {(insight.ways_of_cooking || []).map((method: string, i: number) => (
                  <span key={i} className="bg-amber-50 text-amber-700 px-3 py-1 rounded-full text-sm">
                    {method}
                  </span>
                ))}
                {(!insight.ways_of_cooking || insight.ways_of_cooking.length === 0) && (
                  <span className="text-gray-400 text-sm">Not available</span>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {chartData && chartData.length > 0 && (
        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Meal Score Over Time</h2>
          <div className="h-[300px] w-full">
            <ChartContainer config={chartConfig} className="h-full w-full">
              <BarChart accessibilityLayer data={chartData} margin={{ top: 20, left: 12, right: 12 }}>
                <CartesianGrid vertical={false} />
                <XAxis
                  dataKey="date"
                  tickLine={false}
                  tickMargin={10}
                  axisLine={false}
                />
                <YAxis
                  domain={[0, 100]}
                  tickLine={false}
                  axisLine={false}
                  tickFormatter={(value) => `${value}%`}
                />
                <ChartTooltip
                  cursor={false}
                  content={<ChartTooltipContent indicator="dashed" />}
                />
                <Bar dataKey="score" fill="var(--color-score)" radius={4} />
              </BarChart>
            </ChartContainer>
          </div>
        </div>
      )}

      {party.meals && party.meals.length > 0 && (
        <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <h2 className="text-xl font-semibold">Meals</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {party.meals.map((meal: any) => (
              <Link key={meal.id} href={`/admin/meals/${meal.id}`} className="block">
                <div className="border p-4 rounded-md hover:bg-gray-50 transition-colors">
                  <p className="font-semibold">{meal.dishes?.name}</p>
                  <p className="text-sm text-gray-500">
                    {new Date(meal.eaten_on).toLocaleDateString('en-US')}
                  </p>
                  <p className="text-xs text-gray-400 mt-2">
                    {meal.meal_ratings?.length || 0} rating(s)
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      <div className="space-y-4">
        <h2 className="text-2xl font-semibold">Generation Logs</h2>
        <GenerationLogsClient logs={party.logs || []} />
      </div>
    </div>
  )
}
