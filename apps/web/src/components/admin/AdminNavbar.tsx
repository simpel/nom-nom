'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from 'cn'

const links = [
  { href: '/admin', label: 'Dashboard' },
  { href: '/admin/users', label: 'Users' },
  { href: '/admin/recipes', label: 'Recipes' },
]

export default function AdminNavbar({ email }: { email: string | null }) {
  const pathname = usePathname()

  if (pathname === '/admin/login') {
    return null
  }

  return (
    <nav className="bg-white border-b sticky top-0 z-10">
      <div className="max-w-6xl mx-auto px-8 h-14 flex items-center justify-between">
        <div className="flex items-center gap-6">
          <Link href="/admin" className="font-bold text-black">
            Nom Nom Admin
          </Link>
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={cn(
                'text-sm font-medium',
                pathname === link.href
                  ? 'text-black'
                  : 'text-gray-500 hover:text-black'
              )}
            >
              {link.label}
            </Link>
          ))}
        </div>
        <div className="flex items-center gap-4">
          {email && <span className="text-sm text-gray-500">{email}</span>}
          <form action="/auth/signout" method="POST">
            <button className="text-sm bg-gray-200 hover:bg-gray-300 px-4 py-2 rounded-md font-medium">
              Sign out
            </button>
          </form>
        </div>
      </div>
    </nav>
  )
}
