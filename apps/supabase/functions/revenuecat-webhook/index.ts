import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// RevenueCat webhook: mirrors the subscription state onto `profiles` so server-side Pro
// checks (RLS, Edge Functions) agree with the SDK entitlement the app reads on device.
// https://www.revenuecat.com/docs/integrations/webhooks

interface RevenueCatEvent {
  type: string;
  app_user_id?: string;
  expiration_at_ms?: number | null;
  environment?: string;
}

type SubscriptionStatus = "active" | "canceled" | "expired";

// Event types that grant or extend access.
const GRANTING = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
]);

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Compares through a hash so the length and content of the secret never short-circuit.
async function safeEqual(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const [ha, hb] = await Promise.all([
    crypto.subtle.digest("SHA-256", enc.encode(a)),
    crypto.subtle.digest("SHA-256", enc.encode(b)),
  ]);
  const va = new Uint8Array(ha);
  const vb = new Uint8Array(hb);
  let diff = 0;
  for (let i = 0; i < va.length; i++) diff |= va[i] ^ vb[i];
  return diff === 0;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
    status,
  });
}

/// The status an event moves a profile to, or nil for events that must not change it.
function statusFor(event: RevenueCatEvent, now: number): SubscriptionStatus | null {
  const expired = event.expiration_at_ms != null && event.expiration_at_ms <= now;
  if (event.type === "EXPIRATION") return "expired";
  if (event.type === "CANCELLATION") return expired ? "expired" : "canceled";
  if (GRANTING.has(event.type)) return expired ? "expired" : "active";
  // BILLING_ISSUE (grace period), SUBSCRIPTION_PAUSED, TRANSFER, TEST and anything new:
  // acknowledged, never acted on.
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // RevenueCat sends the value set under Integrations > Webhooks > Authorization header.
  const expected = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  if (!expected) {
    console.error("REVENUECAT_WEBHOOK_AUTH is not set; rejecting every call");
    return new Response("Unauthorized", { status: 401 });
  }
  const received = req.headers.get("authorization") ?? "";
  if (!(await safeEqual(received, expected))) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const event = (await req.json())?.event as RevenueCatEvent | undefined;
    if (!event?.type) {
      return json({ error: "Missing event" }, 400);
    }

    // Sandbox and TestFlight purchases must not grant production Pro. Opt in per project
    // (e.g. a staging Supabase) with REVENUECAT_ACCEPT_SANDBOX=true.
    if (
      event.environment === "SANDBOX" &&
      Deno.env.get("REVENUECAT_ACCEPT_SANDBOX") !== "true"
    ) {
      return json({ ignored: "sandbox" });
    }

    // The app logs in with the Supabase user id. Anything else ($RCAnonymousID:…, an
    // email) has no profile; acknowledge it so RevenueCat doesn't retry.
    const userId = event.app_user_id;
    if (!userId || !UUID.test(userId)) {
      return json({ ignored: "non-uuid app_user_id" });
    }

    const status = statusFor(event, Date.now());
    if (!status) {
      return json({ ignored: event.type });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data, error } = await supabaseAdmin
      .from("profiles")
      .update({
        subscription_status: status,
        subscription_expires_at: event.expiration_at_ms != null
          ? new Date(event.expiration_at_ms).toISOString()
          : null,
        revenuecat_app_user_id: userId,
      })
      .eq("id", userId)
      .select("id");

    if (error) {
      console.error("Supabase update error:", error);
      return json({ error: error.message }, 500);
    }
    if (!data?.length) {
      console.warn(`No profile for app_user_id ${userId}; ${event.type} dropped`);
      return json({ ignored: "no profile" });
    }

    return json({ success: true, status });
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response("Internal Server Error", { status: 500 });
  }
});
