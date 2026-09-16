'use server'

import { revalidatePath } from 'next/cache'
import { headers } from 'next/headers'

export async function generatePartyInsightAction(partyId: string) {
  const host = (await headers()).get('host') || 'localhost:3000'
  const protocol = host.includes('localhost') ? 'http' : 'https'
  const baseUrl = `${protocol}://${host}`

  // Forward cookies from headers
  const cookieHeader = (await headers()).get('cookie')

  const res = await fetch(`${baseUrl}/api/admin/trigger-insight`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    // A single explicit click always regenerates, even if nothing changed.
    body: JSON.stringify({ party_id: partyId, force: true })
  })

  if (!res.ok) {
    const errorData = await res.text().catch(() => '')
    throw new Error(`Failed to generate insight: ${errorData}`)
  }

  // Revalidate the paths so it autoupdates without router.refresh()
  revalidatePath('/admin')
  revalidatePath(`/admin/parties/${partyId}`)

  return { success: true }
}

export async function generateAllPartiesInsightAction() {
  const host = (await headers()).get('host') || 'localhost:3000'
  const protocol = host.includes('localhost') ? 'http' : 'https'
  const baseUrl = `${protocol}://${host}`

  // Forward cookies from headers
  const cookieHeader = (await headers()).get('cookie')

  const res = await fetch(`${baseUrl}/api/admin/trigger-insight`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    // No force: parties whose insight is already newer than their last data
    // change are skipped instead of re-running the (paid) AI prompt.
    body: JSON.stringify({ all: true })
  })

  if (!res.ok) {
    const errorData = await res.text().catch(() => '')
    throw new Error(`Failed to generate insights: ${errorData}`)
  }

  const data = await res.json().catch(() => ({}))

  // Revalidate the admin dashboard
  revalidatePath('/admin')

  return { success: true, updated: data.updated ?? 0, skipped: data.skipped ?? 0 }
}

export async function generateProfileInsightAction(profileId: string) {
  const host = (await headers()).get('host') || 'localhost:3000'
  const protocol = host.includes('localhost') ? 'http' : 'https'
  const baseUrl = `${protocol}://${host}`

  const cookieHeader = (await headers()).get('cookie')

  const res = await fetch(`${baseUrl}/api/admin/trigger-profile-insight`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    body: JSON.stringify({ profile_id: profileId })
  })

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}))
    throw new Error(errorData.error || 'Failed to generate insight')
  }

  revalidatePath('/admin/users')
  revalidatePath(`/admin/users/${profileId}`)

  return { success: true }
}

export async function backfillDishEmbeddingsAction() {
  const host = (await headers()).get('host') || 'localhost:3000'
  const protocol = host.includes('localhost') ? 'http' : 'https'
  const baseUrl = `${protocol}://${host}`

  const cookieHeader = (await headers()).get('cookie')

  const res = await fetch(`${baseUrl}/api/admin/backfill-dish-embeddings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    body: JSON.stringify({})
  })

  if (!res.ok) {
    const errorData = await res.text().catch(() => '')
    throw new Error(`Failed to backfill embeddings: ${errorData}`)
  }

  const data = await res.json().catch(() => ({}))

  return { success: true, updated: data.updated ?? 0, message: data.message }
}

export async function backfillHealthScoresAction() {
  const host = (await headers()).get('host') || 'localhost:3000'
  const protocol = host.includes('localhost') ? 'http' : 'https'
  const baseUrl = `${protocol}://${host}`

  const cookieHeader = (await headers()).get('cookie')

  const res = await fetch(`${baseUrl}/api/admin/generate-health-score`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    body: JSON.stringify({})
  })

  if (!res.ok) {
    const errorData = await res.text().catch(() => '')
    throw new Error(`Failed to generate health scores: ${errorData}`)
  }

  const data = await res.json().catch(() => ({}))

  revalidatePath('/admin/recipes')

  return { success: true, updated: data.updated ?? 0, failed: data.failed ?? 0, message: data.message }
}

export async function generateRecipeHealthScoreAction(recipeId: string) {
  const host = (await headers()).get('host') || 'localhost:3000'
  const protocol = host.includes('localhost') ? 'http' : 'https'
  const baseUrl = `${protocol}://${host}`

  const cookieHeader = (await headers()).get('cookie')

  const res = await fetch(`${baseUrl}/api/admin/generate-health-score`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    body: JSON.stringify({ recipe_id: recipeId })
  })

  if (!res.ok) {
    const errorData = await res.text().catch(() => '')
    throw new Error(`Failed to generate health score: ${errorData}`)
  }

  const data = await res.json().catch(() => ({}))

  if (!data.updated) {
    throw new Error(data.error || data.message || 'Health score generation failed')
  }

  revalidatePath(`/admin/recipes/${recipeId}`)
  revalidatePath('/admin/recipes')

  return { success: true }
}
