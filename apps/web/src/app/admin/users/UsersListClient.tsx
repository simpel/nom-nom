'use client'

import { useMemo, useState } from 'react'

type UserRow = {
  id: string
  name: string
  email: string | null
  avatarEmoji: string | null
  photoPath: string | null
  createdAt: string
  onboardingCompletedAt: string | null
  subscriptionStatus: string | null
  subscriptionExpiresAt: string | null
  isPro: boolean
  mealCount: number
  lastMealDate: string | null
  partyCount: number
}

type SubscriptionFilter = 'all' | 'pro' | 'free'
type SortKey = 'recent' | 'most_active' | 'least_active' | 'newest'

const DAY_MS = 1000 * 60 * 60 * 24

function daysSince(dateStr: string | null): number | null {
  if (!dateStr) return null
  return Math.floor((Date.now() - new Date(dateStr).getTime()) / DAY_MS)
}

export default function UsersListClient({ initialData }: { initialData: UserRow[] }) {
  const [users] = useState<UserRow[]>(initialData)
  const [query, setQuery] = useState('')
  const [subFilter, setSubFilter] = useState<SubscriptionFilter>('all')
  const [sort, setSort] = useState<SortKey>('recent')

  const proCount = users.filter(u => u.isPro).length
  const freeCount = users.length - proCount

  const filtered = useMemo(() => {
    let rows = users.filter(u => {
      if (subFilter === 'pro' && !u.isPro) return false
      if (subFilter === 'free' && u.isPro) return false
      if (query) {
        const q = query.toLowerCase()
        const matchesName = u.name.toLowerCase().includes(q)
        const matchesEmail = u.email?.toLowerCase().includes(q)
        if (!matchesName && !matchesEmail) return false
      }
      return true
    })

    rows = [...rows].sort((a, b) => {
      if (sort === 'newest') return b.createdAt.localeCompare(a.createdAt)
      if (sort === 'most_active') return b.mealCount - a.mealCount
      if (sort === 'least_active') return a.mealCount - b.mealCount
      // 'recent': most recently active first, users who never logged a meal last
      if (!a.lastMealDate && !b.lastMealDate) return 0
      if (!a.lastMealDate) return 1
      if (!b.lastMealDate) return -1
      return b.lastMealDate.localeCompare(a.lastMealDate)
    })

    return rows
  }, [users, query, subFilter, sort])

  return (
    <div className="bg-white rounded-xl shadow-sm border p-6">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-6">
        <div className="flex gap-2 flex-wrap">
          <FilterButton active={subFilter === 'all'} onClick={() => setSubFilter('all')}>
            All ({users.length})
          </FilterButton>
          <FilterButton active={subFilter === 'pro'} onClick={() => setSubFilter('pro')}>
            Pro ({proCount})
          </FilterButton>
          <FilterButton active={subFilter === 'free'} onClick={() => setSubFilter('free')}>
            Free ({freeCount})
          </FilterButton>
        </div>
        <div className="flex gap-2 items-center">
          <input
            type="text"
            placeholder="Search name or email..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="border rounded-md px-3 py-2 text-sm w-64"
          />
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value as SortKey)}
            className="border rounded-md px-3 py-2 text-sm"
          >
            <option value="recent">Most recently active</option>
            <option value="most_active">Most meals logged</option>
            <option value="least_active">Fewest meals logged</option>
            <option value="newest">Newest accounts</option>
          </select>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b bg-gray-50 text-sm">
              <th className="p-4 font-semibold text-gray-700">User</th>
              <th className="p-4 font-semibold text-gray-700">Subscription</th>
              <th className="p-4 font-semibold text-gray-700">Parties</th>
              <th className="p-4 font-semibold text-gray-700">Meals logged</th>
              <th className="p-4 font-semibold text-gray-700">Last active</th>
              <th className="p-4 font-semibold text-gray-700">Joined</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(u => {
              const inactiveDays = daysSince(u.lastMealDate)
              const isAtRisk = u.onboardingCompletedAt && (inactiveDays === null || inactiveDays > 30)
              return (
                <tr key={u.id} className="border-b hover:bg-gray-50 transition-colors">
                  <td className="p-4">
                    <a href={`/admin/users/${u.id}`} className="font-medium text-blue-600 hover:underline">
                      {u.avatarEmoji ? `${u.avatarEmoji} ` : ''}{u.name}
                    </a>
                    <p className="text-xs text-gray-500 mt-1">{u.email || '—'}</p>
                  </td>
                  <td className="p-4">
                    {u.isPro ? (
                      <span className="inline-flex w-fit items-center rounded-full bg-purple-100 text-purple-700 px-2 py-0.5 text-xs font-medium">
                        Pro
                      </span>
                    ) : (
                      <span className="inline-flex w-fit items-center rounded-full bg-gray-100 text-gray-600 px-2 py-0.5 text-xs font-medium">
                        Free
                      </span>
                    )}
                  </td>
                  <td className="p-4 font-medium text-gray-700">{u.partyCount}</td>
                  <td className="p-4 font-medium text-gray-700">{u.mealCount}</td>
                  <td className="p-4 text-sm">
                    {u.lastMealDate ? (
                      <span className={isAtRisk ? 'text-amber-600 font-medium' : 'text-gray-700'} suppressHydrationWarning>
                        {new Date(u.lastMealDate).toLocaleDateString()}
                        {isAtRisk && ` (${inactiveDays}d ago)`}
                      </span>
                    ) : (
                      <span className="text-gray-400 italic">Never</span>
                    )}
                  </td>
                  <td className="p-4 text-xs text-gray-500" suppressHydrationWarning>
                    {new Date(u.createdAt).toLocaleDateString()}
                  </td>
                </tr>
              )
            })}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={6} className="p-8 text-center text-gray-500">
                  No users match.
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
