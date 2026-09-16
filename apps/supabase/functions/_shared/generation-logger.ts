import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// Keep in sync with the public.generation_type enum
// (apps/supabase/migrations/20260914160000_generation_logs.sql and later additions).
export type GenerationType =
  | "party_insight"
  | "member_match"
  | "recipe_health"
  | "dish_photo"
  | "recipe_parse"
  | "dish_embed"
  | "ingredient_canonicalize";

export interface StartLogOptions {
  type: GenerationType;
  entityId: string;
  targetId?: string | null;
  prompt?: string | null;
  model?: string | null;
}

const NIL_UUID = "00000000-0000-0000-0000-000000000000";

/**
 * Uniform "running -> success/error" logger for public.generation_logs,
 * used by every edge function that calls out to the AI Gateway.
 *
 * Usage:
 *   const logger = GenerationLogger.fromEnv();
 *   await logger.start({ type: "dish_embed", entityId: dish.id, prompt, model });
 *   try {
 *     ... do the work ...
 *     await logger.success(responseSummary);
 *   } catch (err) {
 *     await logger.failure(err.message);
 *   }
 *
 * If SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY aren't set, every call is a no-op
 * so functions can log unconditionally without extra guard clauses.
 */
export class GenerationLogger {
  readonly client: SupabaseClient | null;
  private logId: string | null = null;
  private startedAt = 0;

  constructor(client: SupabaseClient | null) {
    this.client = client;
  }

  static fromEnv(): GenerationLogger {
    const url = Deno.env.get("SUPABASE_URL");
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    return new GenerationLogger(url && key ? createClient(url, key) : null);
  }

  async start(opts: StartLogOptions): Promise<GenerationLogger> {
    this.startedAt = Date.now();
    if (!this.client) return this;

    const { data, error } = await this.client
      .from("generation_logs")
      .insert({
        generation_type: opts.type,
        entity_id: opts.entityId || NIL_UUID,
        target_id: opts.targetId ?? null,
        prompt: opts.prompt ?? null,
        status: "running",
        model_used: opts.model ?? null,
      })
      .select("id")
      .single();

    if (error) {
      console.error("GenerationLogger: failed to write 'running' log entry:", error);
    }
    this.logId = data?.id ?? null;
    return this;
  }

  async success(response?: string | null): Promise<void> {
    await this.finish({ status: "success", response: response ?? null });
  }

  async failure(message: string): Promise<void> {
    await this.finish({ status: "error", error_message: message });
  }

  private async finish(fields: Record<string, unknown>): Promise<void> {
    if (!this.client || !this.logId) return;
    const { error } = await this.client
      .from("generation_logs")
      .update({ ...fields, duration_ms: Date.now() - this.startedAt })
      .eq("id", this.logId);

    if (error) {
      console.error("GenerationLogger: failed to finalize log entry:", error);
    }
  }
}
