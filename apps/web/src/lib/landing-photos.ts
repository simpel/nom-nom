import { createClient } from "@supabase/supabase-js";

export type Verdict = "meh" | "good" | "great" | "amazing";

export interface PileCard {
  src: string;
  alt: string;
  /** Absent when nobody has rated the meal yet: the photo shows without a badge. */
  verdict?: Verdict;
  label?: string;
}

const PILE_SIZE = 7;
/** Signed links outlive the hourly page revalidation by a wide margin. */
const SIGNED_URL_SECONDS = 60 * 60 * 24;

/** Cuisine photos that fill the pile when the database has too few meals. */
const CUISINES: PileCard[] = [
  {
    src: "/landing/swedish.jpg",
    alt: "Swedish dinner",
    verdict: "good",
    label: "Good",
  },
  {
    src: "/landing/mexican.jpg",
    alt: "Mexican dinner",
    verdict: "great",
    label: "Great",
  },
  {
    src: "/landing/thai.jpg",
    alt: "Thai dinner",
    verdict: "great",
    label: "Great",
  },
  {
    src: "/landing/italian.jpg",
    alt: "Italian dinner",
    verdict: "amazing",
    label: "Amazing",
  },
];

/** The four cuisines repeated up to a full pile. */
const FALLBACK: PileCard[] = Array.from(
  { length: PILE_SIZE },
  (_, i) => CUISINES[i % CUISINES.length],
);

const LABELS: Record<Verdict, string> = {
  meh: "Meh",
  good: "Good",
  great: "Great",
  amazing: "Amazing",
};

/**
 * meal_ratings.reaction is the taste scale: -1 Can't eat, 1 Bad, 2 Meh, 3 Good,
 * 4 Great, 5 Amazing. The rounded mean picks the word; the pile only shows
 * dinners worth showing off, so anything below Meh reads as Meh.
 */
function verdictFor(reactions: number[]): Verdict | undefined {
  if (reactions.length === 0) return undefined;
  const mean =
    reactions.reduce((sum, value) => sum + value, 0) / reactions.length;
  const step = Math.round(mean);
  if (step >= 5) return "amazing";
  if (step === 4) return "great";
  if (step === 3) return "good";
  return "meh";
}

/**
 * The newest AI-generated meal photos, each with the verdict the household gave
 * it. Reads generation_logs (so only generated photos qualify, never ones a
 * person took), then the meal's first photo path and its ratings. Falls back to
 * the bundled cuisine photos for any slot it cannot fill.
 */
export async function getLatestMealPhotos(): Promise<PileCard[]> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return FALLBACK;

  try {
    const supabase = createClient(url, key, {
      auth: { persistSession: false },
    });

    const { data: logs } = await supabase
      .from("generation_logs")
      .select("entity_id")
      .eq("generation_type", "meal_photo")
      .eq("status", "success")
      .order("created_at", { ascending: false })
      .limit(30);
    const mealIds = [
      ...new Set((logs ?? []).map((log) => log.entity_id as string)),
    ];
    if (mealIds.length === 0) return FALLBACK;

    const [{ data: meals }, { data: ratings }] = await Promise.all([
      supabase.from("meals").select("id, photo_paths").in("id", mealIds),
      supabase
        .from("meal_ratings")
        .select("meal_id, reaction")
        .in("meal_id", mealIds),
    ]);

    const pathByMeal = new Map<string, string>();
    for (const meal of meals ?? []) {
      const path = (meal.photo_paths as string[] | null)?.[0];
      if (path) pathByMeal.set(meal.id as string, path);
    }
    const picked = mealIds
      .filter((id) => pathByMeal.has(id))
      .slice(0, PILE_SIZE);
    if (picked.length === 0) return FALLBACK;

    const { data: signed } = await supabase.storage
      .from("meal-photos")
      .createSignedUrls(
        picked.map((id) => pathByMeal.get(id)!),
        SIGNED_URL_SECONDS,
      );

    const cards: PileCard[] = [];
    picked.forEach((mealId, index) => {
      const signedUrl = signed?.[index]?.signedUrl;
      if (!signedUrl) return;
      const reactions = (ratings ?? [])
        .filter((rating) => rating.meal_id === mealId)
        .map((rating) => rating.reaction as number);
      const verdict = verdictFor(reactions);
      cards.push({
        src: signedUrl,
        alt: "A recent dinner",
        verdict,
        label: verdict ? LABELS[verdict] : undefined,
      });
    });

    // Oldest first, so the newest card lands on top of the pile.
    cards.reverse();
    return [...FALLBACK.slice(0, PILE_SIZE - cards.length), ...cards];
  } catch {
    return FALLBACK;
  }
}
