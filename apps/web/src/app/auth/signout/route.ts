import { createClient } from '@/utils/supabase/server'
import { revalidatePath } from 'next/cache'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  const supabase = await createClient()

  const { error } = await supabase.auth.signOut()
  if (error) {
    console.error('Error signing out:', error.message)
  }

  revalidatePath('/', 'layout')
  return NextResponse.redirect(new URL('/admin/login', req.url), { status: 302 })
}
