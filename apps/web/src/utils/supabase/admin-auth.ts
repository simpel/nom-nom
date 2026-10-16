import { NextResponse } from 'next/server'
import { redirect } from 'next/navigation'
import type { User } from '@supabase/supabase-js'
import { createClient } from '@/utils/supabase/server'

/**
 * The signed-in user if they are in public.admins (checked by public.is_admin()
 * under their own session), else null. Never trust the layout alone: pages,
 * route handlers and server actions each call one of the helpers below.
 */
export async function getAdminUser(): Promise<User | null> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data: isAdmin } = await supabase.rpc('is_admin')
  return isAdmin === true ? user : null
}

/** For pages: send everyone who is not an admin to the login page. */
export async function requireAdmin(): Promise<User> {
  const user = await getAdminUser()
  if (!user) redirect('/admin/login')
  return user
}

/** For route handlers: a 403 response to return, or null for an admin. */
export async function adminGuard(): Promise<NextResponse | null> {
  const user = await getAdminUser()
  return user ? null : NextResponse.json({ error: 'Forbidden' }, { status: 403 })
}
