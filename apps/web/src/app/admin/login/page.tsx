'use client'

import { useState } from 'react'
import { createClient } from '@/utils/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<{ type: 'error' | 'success', text: string } | null>(null)

  const supabase = createClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setMessage(null)
    setLoading(true)

    try {
      const response = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (response.error) {
        setMessage({ type: 'error', text: response.error.message })
      } else {
        setMessage({ type: 'success', text: 'Login successful! Redirecting...' })
        window.location.href = '/admin'
      }
    } catch (e: any) {
      setMessage({ type: 'error', text: e.message || 'An unexpected error occurred.' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#F7F7F7] p-4">
      <main className="w-full max-w-sm flex flex-col items-center gap-6">

        {/* Brand Header */}
        <div className="flex flex-col items-center gap-4 text-center">
          <img
            src="/icon.png"
            alt="Nom Nom"
            className="w-20 h-20 rounded-2xl object-cover shadow-sm border border-black/5"
          />
          <h1 className="font-serif text-[2rem] leading-none tracking-tight text-slate-900">
            Admin Access
          </h1>
        </div>

        {/* Form Card */}
        <div className="w-full bg-white border border-slate-200 shadow-sm flex flex-col">
          <div className="p-6 pb-2">
            <p className="text-[15px] leading-relaxed text-slate-600 mb-4">
              Enter your email and password to log in.
            </p>
            {message && (
              <p className={`text-[15px] text-center font-medium mb-4 ${message.type === 'error' ? 'text-red-500' : 'text-green-600'}`}>
                {message.text}
              </p>
            )}
          </div>

          <form onSubmit={handleLogin} className="flex flex-col">
            <div className="flex flex-col gap-4 p-6 pt-0">
              <div className="flex flex-col gap-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  placeholder="app@nomnom.casa"
                  className="h-10 text-[15px]"
                />
              </div>
              
              <div className="flex flex-col gap-2">
                <Label htmlFor="password">Password</Label>
                <Input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="h-10 text-[15px]"
                />
              </div>
            </div>
            
            <div className="border-t border-slate-200 p-4">
              <Button
                type="submit"
                className="w-full h-[46px] rounded-none bg-[#1A1A1A] hover:bg-black text-white font-medium text-[15px] border-0"
                disabled={loading}
              >
                {loading ? 'Logging in...' : 'Log in'}
              </Button>
            </div>
          </form>
        </div>

      </main>
    </div>
  )
}
