'use client'

import { useMemo, useState } from 'react'
import { backfillDishEmbeddingsAction, backfillHealthScoresAction } from '../actions'
import { toast } from 'sonner'

type RecipeData = {
  id: string
  name: string
  cuisine: string | null
  tags: string[] | null
  effort: string | null
  serves: number | null
  hasEmbedding: boolean
  healthScore: number | null
  healthVerdict: string | null
  createdAt: string
  updatedAt: string
  mealCount: number
}

type Filter = 'all' | 'needs_embedding' | 'needs_health'

export default function RecipesListClient({ initialData }: { initialData: RecipeData[] }) {
  const [recipes] = useState<RecipeData[]>(initialData)
  const [filter, setFilter] = useState<Filter>('all')
  const [query, setQuery] = useState('')

  const needsEmbeddingCount = recipes.filter(r => !r.hasEmbedding).length
  const needsHealthCount = recipes.filter(r => r.healthScore === null).length

  const handleBackfillEmbeddings = () => {
    toast.promise(
      backfillDishEmbeddingsAction(),
      {
        loading: 'Backfilling embeddings...',
        success: (res) => res.message || `Updated ${res.updated} dish(es)`,
        error: (err) => `Failed to backfill embeddings: ${err.message}`
      }
    )
  }

  const handleGenerateHealthScores = () => {
    toast.promise(
      backfillHealthScoresAction(),
      {
        loading: 'Generating health scores...',
        success: (res) => res.message || `Scored ${res.updated} dish(es)${res.failed ? `, ${res.failed} skipped` : ''}`,
        error: (err) => `Failed to generate health scores: ${err.message}`
      }
    )
  }

  const filtered = useMemo(() => {
    return recipes.filter(r => {
      if (filter === 'needs_embedding' && r.hasEmbedding) return false
      if (filter === 'needs_health' && r.healthScore !== null) return false
      if (query && !r.name.toLowerCase().includes(query.toLowerCase())) return false
      return true
    })
  }, [recipes, filter, query])

  return (
    <div className="bg-white rounded-xl shadow-sm border p-6">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-6">
        <div className="flex gap-2 flex-wrap">
          <FilterButton active={filter === 'all'} onClick={() => setFilter('all')}>
            All ({recipes.length})
          </FilterButton>
          <FilterButton active={filter === 'needs_embedding'} onClick={() => setFilter('needs_embedding')}>
            Needs embedding ({needsEmbeddingCount})
          </FilterButton>
          <FilterButton active={filter === 'needs_health'} onClick={() => setFilter('needs_health')}>
            Needs health score ({needsHealthCount})
          </FilterButton>
        </div>
        <div className="flex gap-2 items-center">
          <input
            type="text"
            placeholder="Search recipes..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="border rounded-md px-3 py-2 text-sm w-56"
          />
          <button
            onClick={handleBackfillEmbeddings}
            disabled={needsEmbeddingCount === 0}
            className="bg-black text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-800 disabled:opacity-50 whitespace-nowrap"
          >
            Backfill Embeddings
          </button>
          <button
            onClick={handleGenerateHealthScores}
            disabled={needsHealthCount === 0}
            className="bg-black text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-800 disabled:opacity-50 whitespace-nowrap"
          >
            Generate Health Scores
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b bg-gray-50 text-sm">
              <th className="p-4 font-semibold text-gray-700">Name</th>
              <th className="p-4 font-semibold text-gray-700">Cuisine</th>
              <th className="p-4 font-semibold text-gray-700">Meals</th>
              <th className="p-4 font-semibold text-gray-700">Embedding</th>
              <th className="p-4 font-semibold text-gray-700">Health Score</th>
              <th className="p-4 font-semibold text-gray-700">Verdict</th>
              <th className="p-4 font-semibold text-gray-700">Updated</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(r => (
              <tr key={r.id} className="border-b hover:bg-gray-50 transition-colors">
                <td className="p-4">
                  <a href={`/admin/recipes/${r.id}`} className="font-medium text-blue-600 hover:underline">{r.name}</a>
                  <p className="text-xs text-gray-500 font-mono mt-1">{r.id.split('-')[0]}...</p>
                </td>
                <td className="p-4 text-sm text-gray-700">{r.cuisine || '—'}</td>
                <td className="p-4 font-medium text-gray-700">{r.mealCount}</td>
                <td className="p-4">
                  {r.hasEmbedding ? (
                    <span className="inline-flex w-fit items-center rounded-full bg-green-100 text-green-700 px-2 py-0.5 text-xs font-medium">
                      Ready
                    </span>
                  ) : (
                    <span className="inline-flex w-fit items-center rounded-full bg-amber-100 text-amber-700 px-2 py-0.5 text-xs font-medium">
                      Needs backfill
                    </span>
                  )}
                </td>
                <td className="p-4 text-sm text-gray-700">
                  {r.healthScore ?? <span className="text-gray-400 italic">—</span>}
                </td>
                <td className="p-4 text-sm text-gray-700">{r.healthVerdict || '—'}</td>
                <td className="p-4 text-xs text-gray-500" suppressHydrationWarning>
                  {new Date(r.updatedAt).toLocaleDateString()}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={7} className="p-8 text-center text-gray-500">
                  No recipes match.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function FilterButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`px-3 py-1.5 rounded-md text-sm font-medium border ${
        active ? 'bg-black text-white border-black' : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
      }`}
    >
      {children}
    </button>
  )
}
