import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/** The kind of model a feature calls; each kind has its own default at /admin/ai-config. */
export type ModelKind = "text" | "image";

/**
 * The model for `featureId`, set at /admin/ai-config (public.ai_feature_configs).
 *
 * A feature row with a model wins; a feature row without one (or no row) uses the
 * `default-<kind>` row. There is no model in code: if neither is set, this throws so the
 * misconfiguration shows up in the logs instead of silently calling some other model.
 * Every feature id here must also be listed in apps/web/src/app/admin/ai-config/features.ts.
 */
export async function getFeatureModel(
  client: SupabaseClient | null,
  featureId: string,
  kind: ModelKind,
): Promise<string> {
  if (!client) {
    throw new Error(`Cannot read the AI model for ${featureId}: no Supabase service client`);
  }

  const defaultId = `default-${kind}`;
  const { data, error } = await client
    .from("ai_feature_configs")
    .select("feature_id, model_name")
    .in("feature_id", [featureId, defaultId]);

  if (error) {
    throw new Error(`Cannot read the AI model for ${featureId}: ${error.message}`);
  }

  const model = (id: string) => data?.find((row) => row.feature_id === id)?.model_name;
  const resolved = model(featureId) || model(defaultId);
  if (!resolved) {
    throw new Error(`No AI model set for ${featureId} and no ${kind} default; set one at /admin/ai-config`);
  }
  return resolved;
}
