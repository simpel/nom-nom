import Link from 'next/link'
import { redirect } from 'next/navigation'
import { createClient } from '@/utils/supabase/server'
import { verdictLabel, type RatingTag } from '@/utils/rating-model'

export const modelHref = {
  overview: '/admin/rating-model',
  trait: (id: string) => `/admin/rating-model/traits/${id}`,
  term: (id: string) => `/admin/rating-model/terms/${id}`,
  tag: (id: string) => `/admin/rating-model/tags/${id}`,
  dish: (id: string) => `/admin/recipes/${id}`,
}

export async function requireAdmin() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/admin/login')
}

export function ModelPage({
  eyebrow,
  title,
  subtitle,
  back = { href: modelHref.overview, label: 'Rating model' },
  children,
}: {
  eyebrow: string
  title: string
  subtitle?: React.ReactNode
  back?: { href: string; label: string } | null
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-gray-50 p-8 text-black">
      <div className="mx-auto flex max-w-7xl flex-col gap-8">
        <header className="flex items-start justify-between gap-4">
          <div>
            <div className="text-xs font-semibold uppercase tracking-wider text-gray-500">{eyebrow}</div>
            <h1 className="text-3xl font-bold">{title}</h1>
            {subtitle && <p className="mt-1 text-gray-500">{subtitle}</p>}
          </div>
          {back && (
            <Link href={back.href} className="rounded-md border bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50">
              {back.label}
            </Link>
          )}
        </header>
        {children}
      </div>
    </div>
  )
}

export function Panel({ title, trailing, children }: { title: string; trailing?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="rounded-xl border bg-white p-6 shadow-sm">
      <div className="mb-4 flex items-baseline justify-between gap-4">
        <h2 className="text-lg font-semibold">{title}</h2>
        {trailing && <span className="text-sm text-gray-500">{trailing}</span>}
      </div>
      {children}
    </section>
  )
}

export function Chip({ href, children, tone = 'gray' }: { href?: string; children: React.ReactNode; tone?: 'gray' | 'indigo' | 'emerald' | 'amber' }) {
  const tones = {
    gray: 'bg-gray-100 text-gray-700',
    indigo: 'bg-indigo-50 text-indigo-700',
    emerald: 'bg-emerald-50 text-emerald-700',
    amber: 'bg-amber-50 text-amber-800',
  }
  const cls = `inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${tones[tone]}`
  return href ? <Link href={href} className={`${cls} hover:underline`}>{children}</Link> : <span className={cls}>{children}</span>
}

export function TagChip({ tag }: { tag: RatingTag }) {
  return (
    <Chip href={modelHref.tag(tag.id)} tone={!tag.scored ? 'gray' : tag.is_positive ? 'emerald' : 'amber'}>
      {tag.label}
    </Chip>
  )
}

export function VerdictList({ verdicts }: { verdicts: number[] }) {
  return (
    <span className="flex flex-wrap gap-1">
      {[...verdicts].sort((a, b) => b - a).map(v => <Chip key={v}>{verdictLabel(v)}</Chip>)}
    </span>
  )
}
