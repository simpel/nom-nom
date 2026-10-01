import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * Fetches the configured AI model for a given feature from the ai_feature_configs table.
 * Falls back to the defaultModel (or AI_GATEWAY_MODEL env var) if not configured or if DB fails.
 */
export async function getFeatureModel(
  client: SupabaseClient | null,
  featureId: string,
  defaultModel: string = "google/gemini-2.5-flash"
): Promise<string> {
  const envDefault = Deno.env.get("AI_GATEWAY_MODEL") || defaultModel;

  if (!client) {
    return envDefault;
  }

  try {
    const { data, error } = await client
      .from("ai_feature_configs")
      .select("model_name")
      .eq("feature_id", featureId)
      .single();

    if (error || !data?.model_name) {
      if (error && error.code !== 'PGRST116') { // Ignore "no rows returned" error
        console.error(`Error fetching AI config for ${featureId}:`, error);
      }
      return envDefault;
    }

    return data.model_name;
  } catch (err) {
    console.error(`Exception fetching AI config for ${featureId}:`, err);
    return envDefault;
  }
}
