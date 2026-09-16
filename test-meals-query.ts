import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const adminSupabase = createClient(supabaseUrl, supabaseServiceKey)

async function test() {
  const { data: meal, error } = await adminSupabase
    .from('meals')
    .select(`
      *,
      dishes (id, name, cuisine),
      meal_ratings (
        reaction,
        profiles (first_name, last_name, handle)
      ),
      meal_parties (
        parties (id, name)
      )
    `)
    .eq('id', 'ba000000-0000-0000-0000-000000000026')
    .single()

  console.log("Meal:", JSON.stringify(meal, null, 2))
  console.log("Error:", error)
}
test()
