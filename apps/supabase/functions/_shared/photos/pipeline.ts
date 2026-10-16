// Plumbing shared by generate-recipe-photo and generate-meal-photo: request
// authentication, the AI Gateway calls, and the image response.

import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { GenerationLogger } from "../generation-logger.ts";
import { imageSizeFor } from "./prompts.ts";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export interface GatewayConfig {
  baseUrl: string;
  apiKey: string;
}

/**
 * CORS preflight, method, webhook secret / user JWT and gateway key. Returns the
 * response to send when the request must stop here, otherwise the gateway config.
 */
export function authenticate(req: Request): Response | GatewayConfig {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  const expectedSecret = Deno.env.get("WEBHOOK_SECRET") || "local-development-webhook-secret";
  const receivedSecret = req.headers.get("x-webhook-secret");
  if (!receivedSecret && !req.headers.get("authorization")) {
    return jsonResponse({ error: "Missing authentication" }, 401);
  }
  if (receivedSecret && receivedSecret !== expectedSecret) {
    return jsonResponse({ error: "Invalid webhook secret" }, 403);
  }

  const apiKey =
    Deno.env.get("VERCEL_AI_GATEWAY") ||
    Deno.env.get("VERCEL_AI_GATEWAY_KEY") ||
    Deno.env.get("AI_GATEWAY_API_KEY") ||
    Deno.env.get("VERCEL_AI_GATEWAY_TOKEN");
  if (!apiKey) return jsonResponse({ error: "AI Gateway API key is not configured" }, 500);

  return { baseUrl: Deno.env.get("AI_GATEWAY_BASE_URL") || "https://ai-gateway.vercel.sh/v1", apiKey };
}

/** One JSON-mode chat completion; null when the call or the parse fails (callers keep their fallback). */
export async function chatJson<T>(
  gateway: GatewayConfig,
  model: string,
  system: string,
  user: string,
): Promise<T | null> {
  const res = await fetch(`${gateway.baseUrl}/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${gateway.apiKey}` },
    body: JSON.stringify({
      model,
      messages: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
      response_format: { type: "json_object" },
      temperature: 0.3,
    }),
  });
  if (!res.ok) return null;

  const completion = await res.json();
  let text: string | undefined = completion.choices?.[0]?.message?.content?.trim();
  if (!text) return null;
  if (text.startsWith("```json")) text = text.slice(7);
  if (text.startsWith("```")) text = text.slice(3);
  if (text.endsWith("```")) text = text.slice(0, -3);
  return JSON.parse(text.trim()) as T;
}

export interface GeneratedImage {
  bytes: Uint8Array;
  base64: string;
}

/** Renders `prompt` and records the outcome on `logger`. A Response means the request failed. */
export async function generateImage(
  gateway: GatewayConfig,
  logger: GenerationLogger,
  model: string,
  prompt: string,
): Promise<GeneratedImage | Response> {
  try {
    const res = await fetch(`${gateway.baseUrl}/images/generations`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${gateway.apiKey}` },
      body: JSON.stringify({ model, prompt, n: 1, size: imageSizeFor(model) }),
    });

    if (!res.ok) {
      const errorText = await res.text();
      console.error("AI Gateway image generation failed:", res.status, errorText);
      await logger.failure(`AI Gateway error (${res.status}): ${errorText}`);
      return jsonResponse({ error: `Image generation error (${res.status}): ${errorText}` }, 502);
    }

    const item = (await res.json()).data?.[0];
    if (!item) {
      await logger.failure("No image received from AI Gateway");
      return jsonResponse({ error: "No image received from AI Gateway" }, 502);
    }

    let bytes: Uint8Array;
    let base64: string;
    if (item.b64_json) {
      base64 = item.b64_json;
      bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    } else if (item.url) {
      bytes = new Uint8Array(await (await fetch(item.url)).arrayBuffer());
      // Spreading a ~1 MB image into String.fromCharCode overflows the stack.
      base64 = encodeBase64(bytes);
    } else {
      await logger.failure("Invalid image format in response");
      return jsonResponse({ error: "Invalid image format in response" }, 502);
    }

    await logger.success("Image generated successfully");
    return { bytes, base64 };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Failed to generate image:", err);
    await logger.failure(message);
    return jsonResponse({ error: `Internal error: ${message}` }, 500);
  }
}

/** True when the request carries the database trigger's webhook secret (checked by `authenticate`). */
export function isWebhookCall(req: Request): boolean {
  return Boolean(req.headers.get("x-webhook-secret"));
}

/**
 * A person asking for a photo: the JWT must be valid (resolved with getUser, never read from
 * the body), the row must belong to them and they must have Nom Nom Pro. Null when allowed,
 * otherwise the response to send.
 */
export async function authorizeUserPhoto(
  req: Request,
  admin: SupabaseClient | null,
  target: { table: "recipes" | "meals"; ownerColumn: "owner_id" | "created_by"; id: string | undefined },
): Promise<Response | null> {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!admin || !url || !anonKey) return jsonResponse({ error: "Server is not configured" }, 500);
  if (!target.id) return jsonResponse({ error: "An id is required" }, 400);

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return jsonResponse({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  // Postgres returns uuids lower case; iOS sends them upper case.
  const { data: row } = await admin
    .from(target.table).select(target.ownerColumn).eq("id", target.id.toLowerCase()).maybeSingle();
  if (!row) return jsonResponse({ error: "Not found" }, 404);
  if ((row as Record<string, unknown>)[target.ownerColumn] !== userId) {
    return jsonResponse({ error: "Only the owner can add photos" }, 403);
  }

  const { data: pro } = await admin.rpc("has_pro", { p_user_id: userId });
  if (pro !== true) return jsonResponse({ error: "Nom Nom Pro required" }, 402);
  return null;
}
