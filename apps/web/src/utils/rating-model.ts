import { createClient as createSupabaseClient } from '@supabase/supabase-js'

// The rating model as the admin sees it: taxonomy terms carry traits, traits decide
// which "what stood out" tags a meal offers, and each tag names the verdicts that offer
// it. Source of truth: migration 20261004140000_rating_traits_and_score.sql.

export const TRAITS = [
  { id: 'crust', label: 'Crust', description: 'A crust, crisp coating or crisp edges' },
  { id: 'saucy', label: 'Saucy', description: 'Built around a sauce, broth or liquid' },
  { id: 'raw', label: 'Raw', description: 'Mostly raw or cured, not cooked' },
  { id: 'meat_fish', label: 'Meat & fish', description: 'Centred on a piece of meat or fish' },
  { id: 'starch', label: 'Starch', description: 'Centred on pasta, rice, noodles or dough' },
  { id: 'smoky', label: 'Smoky', description: 'Smoked or chargrilled flavour' },
] as const

// Not stored on terms: how a tag with no trait, or the cooked trait, reaches a dish.
export const ANY_TRAIT = { id: 'any', label: 'Any dish', description: 'Tags with no trait: offered on every dish' }
export const COOKED_TRAIT = { id: 'cooked', label: 'Any cooked dish', description: 'Every dish whose terms do not carry raw' }

export const VERDICTS = [
  { value: 5, label: 'Amazing', score: 100 },
  { value: 4, label: 'Great', score: 80 },
  { value: 3, label: 'Good', score: 60 },
  { value: 2, label: 'Meh', score: 40 },
  { value: 1, label: 'Bad', score: 20 },
  { value: -1, label: "Can't eat", score: 0 },
] as const

export const TRAIT_DIMENSIONS = ['dish_kind', 'cooking_method'] as const

export const DIMENSION_LABELS: Record<string, string> = {
  dish_kind: 'Dish kind',
  cooking_method: 'Cooking method',
  cuisine: 'Cuisine',
}

export type Term = {
  id: string
  dimension: string
  slug: string
  name: string
  aliases: string[]
  rating_traits: string[]
  created_at: string
}

export type RatingTag = {
  id: string
  label: string
  is_positive: boolean
  scored: boolean
  verdicts: number[]
  trait: string | null
  tag_group: string
  sort: number
}

export type RatingModel = {
  terms: Term[]
  tags: RatingTag[]
  /** term id → dishes using it as dish kind, cooking method or cuisine */
  dishCounts: Map<string, number>
  /** tag id → ratings that chose it */
  tagUsage: Map<string, number>
}

function adminClient() {
  return createSupabaseClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)
}

export async function loadRatingModel(): Promise<RatingModel> {
  const db = adminClient()
  const [termsRes, tagsRes, dishesRes, ratingsRes] = await Promise.all([
    db.from('taxonomy_terms')
      .select('id, dimension, slug, name, aliases, rating_traits, created_at')
      .order('dimension').order('name'),
    db.from('rating_tags').select('*').order('sort'),
    db.from('dishes').select('dish_kind_id, cooking_method_id, cuisine_id'),
    db.from('meal_ratings').select('tags'),
  ])
  for (const res of [termsRes, tagsRes, dishesRes, ratingsRes]) {
    if (res.error) console.error('loadRatingModel:', res.error)
  }

  const dishCounts = new Map<string, number>()
  for (const d of dishesRes.data ?? []) {
    for (const id of [d.dish_kind_id, d.cooking_method_id, d.cuisine_id]) {
      if (id) dishCounts.set(id, (dishCounts.get(id) ?? 0) + 1)
    }
  }
  const tagUsage = new Map<string, number>()
  for (const r of ratingsRes.data ?? []) {
    for (const t of (r.tags as string[] | null) ?? []) tagUsage.set(t, (tagUsage.get(t) ?? 0) + 1)
  }

  return {
    terms: (termsRes.data ?? []) as Term[],
    tags: (tagsRes.data ?? []) as RatingTag[],
    dishCounts,
    tagUsage,
  }
}

export async function loadTermDishes(termId: string) {
  const { data } = await adminClient()
    .from('dishes')
    .select('id, name')
    .or(`dish_kind_id.eq.${termId},cooking_method_id.eq.${termId},cuisine_id.eq.${termId}`)
    .order('name')
  return (data ?? []) as { id: string; name: string }[]
}

/** The trait node a tag hangs off: its trait, or Any dish when it has none. */
export function tagTraitId(tag: RatingTag) {
  return tag.trait ?? ANY_TRAIT.id
}

export function traitInfo(id: string) {
  if (id === ANY_TRAIT.id) return ANY_TRAIT
  if (id === COOKED_TRAIT.id) return COOKED_TRAIT
  return TRAITS.find(t => t.id === id) ?? null
}

/** Does a dish with these traits offer this tag (for some verdict)? Mirrors the app. */
export function tagFitsTraits(tag: RatingTag, traits: string[]) {
  if (tag.trait === null) return true
  if (tag.trait === COOKED_TRAIT.id) return !traits.includes('raw')
  return traits.includes(tag.trait)
}

/** Trait-carrying terms (dish kinds, cooking methods). */
export function traitTerms(terms: Term[]) {
  return terms.filter(t => (TRAIT_DIMENSIONS as readonly string[]).includes(t.dimension))
}

/** Terms whose traits make this tag fit (only the ones that name the trait). */
export function termsOfferingTag(tag: RatingTag, terms: Term[]) {
  if (tag.trait === null || tag.trait === COOKED_TRAIT.id) return []
  return traitTerms(terms).filter(t => t.rating_traits.includes(tag.trait!))
}

export function verdictLabel(value: number) {
  return VERDICTS.find(v => v.value === value)?.label ?? String(value)
}
