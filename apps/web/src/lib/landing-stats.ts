import { createClient } from '@supabase/supabase-js';

export interface LandingStats {
  meals: number;
  parties: number;
  ratings: number;
}

/**
 * Public counts for the landing page. Counts only, never rows: the service
 * role bypasses RLS, so nothing else may be selected here. Returns null when
 * the backend is unreachable so the page can drop the stats instead of
 * showing zeros.
 */
export async function getLandingStats(): Promise<LandingStats | null> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;

  const supabase = createClient(url, key, { auth: { persistSession: false } });
  const count = (table: 'meals' | 'parties' | 'meal_ratings') =>
    supabase.from(table).select('*', { count: 'exact', head: true });

  const [meals, parties, ratings] = await Promise.all([
    count('meals'),
    count('parties'),
    count('meal_ratings'),
  ]);

  if (meals.error || parties.error || ratings.error) return null;
  return {
    meals: meals.count ?? 0,
    parties: parties.count ?? 0,
    ratings: ratings.count ?? 0,
  };
}
