require('dotenv').config({ path: 'apps/web/.env.local' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  const { data, error } = await supabase
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
    .single();
  console.log("Data:", data);
  console.log("Error:", error);
}

test();
