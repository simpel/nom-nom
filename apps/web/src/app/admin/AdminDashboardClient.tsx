'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { generatePartyInsightAction, generateAllPartiesInsightAction, backfillDishEmbeddingsAction } from './actions'
import { toast } from 'sonner'

type PartyData = {
  id: string
  name: string
  is_public: boolean
  created_at: string
  updated_at: string
  mealCount: number
  userCount: number
  insightSummary?: string
  insightUpdatedAt?: string
}

export default function AdminDashboardClient({ initialData }: { initialData: PartyData[] }) {
  const [parties, setParties] = useState<PartyData[]>(initialData)
  const router = useRouter()

  const handleTrigger = (partyId: string) => {
    toast.promise(
      generatePartyInsightAction(partyId),
      {
        loading: 'Generating insights...',
        success: 'Insight generated successfully!',
        error: (err) => `Failed to generate: ${err.message}`
      }
    )
  }

  const handleTriggerAll = () => {
    toast.promise(
      generateAllPartiesInsightAction(),
      {
        loading: 'Checking for parties that need a refresh...',
        success: (res) => `Refreshed ${res.updated} ${res.updated === 1 ? 'party' : 'parties'} (${res.skipped} already up to date, skipped)`,
        error: (err) => `Failed to trigger all: ${err.message}`
      }
    )
  }

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

  const needsRefresh = (p: PartyData) =>
    !p.insightUpdatedAt || new Date(p.updated_at) > new Date(p.insightUpdatedAt)

  return (
    <div className="bg-white rounded-xl shadow-sm border p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold">Party Insights</h2>
        <div className="flex gap-2">
          <button
            onClick={handleBackfillEmbeddings}
            className="bg-gray-100 text-gray-800 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-200 disabled:opacity-50"
          >
            Backfill Dish Embeddings
          </button>
          <button
            onClick={handleTriggerAll}
            className="bg-black text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-800 disabled:opacity-50"
          >
            Refresh Stale Insights
          </button>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b bg-gray-50 text-sm">
              <th className="p-4 font-semibold text-gray-700">Party Name</th>
              <th className="p-4 font-semibold text-gray-700">Meals</th>
              <th className="p-4 font-semibold text-gray-700">Users</th>
              <th className="p-4 font-semibold text-gray-700 w-1/2">Insight Summary</th>
              <th className="p-4 font-semibold text-gray-700">Last Updated</th>
              <th className="p-4 font-semibold text-gray-700 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {parties.map(p => (
              <tr key={p.id} className="border-b hover:bg-gray-50 transition-colors">
                <td className="p-4">
                  <a href={`/admin/parties/${p.id}`} className="font-medium text-blue-600 hover:underline">{p.name}</a>
                  <p className="text-xs text-gray-500 font-mono mt-1">{p.id.split('-')[0]}...</p>
                </td>
                <td className="p-4 font-medium text-gray-700">
                  {p.mealCount}
                </td>
                <td className="p-4 font-medium text-gray-700">
                  {p.userCount}
                </td>
                <td className="p-4">
                  {p.insightSummary ? (
                    <span className="text-sm text-gray-700">{p.insightSummary}</span>
                  ) : (
                    <span className="text-sm text-gray-400 italic">No insights yet</span>
                  )}
                </td>
                <td className="p-4">
                  <div className="flex flex-col gap-1 text-xs">
                    <span className={needsRefresh(p) ? 'text-amber-600 font-medium' : 'text-gray-500'} suppressHydrationWarning>
                      Data: {new Date(p.updated_at).toLocaleDateString()}
                    </span>
                    <span className="text-gray-500" suppressHydrationWarning>
                      Insight: {p.insightUpdatedAt ? new Date(p.insightUpdatedAt).toLocaleDateString() : 'Never'}
                    </span>
                    {needsRefresh(p) ? (
                      <span className="inline-flex w-fit items-center rounded-full bg-amber-100 text-amber-700 px-2 py-0.5 font-medium">
                        Needs refresh
                      </span>
                    ) : (
                      <span className="inline-flex w-fit items-center rounded-full bg-green-100 text-green-700 px-2 py-0.5 font-medium">
                        Up to date
                      </span>
                    )}
                  </div>
                </td>
                <td className="p-4 text-right">
                  <button
                    onClick={() => handleTrigger(p.id)}
                    className="border border-gray-300 px-3 py-1.5 rounded-md text-sm font-medium hover:bg-gray-100 disabled:opacity-50"
                  >
                    {needsRefresh(p) ? 'Generate' : 'Regenerate'}
                  </button>
                </td>
              </tr>
            ))}
            {parties.length === 0 && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-gray-500">
                  No dinner parties found. Run the seed script!
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
