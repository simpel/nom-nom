// Fans a `notifications` row out to the user's Apple devices.
//
// Wiring: a Database Webhook on INSERT into public.notifications calls this
// function. Supabase itself does not talk to APNs — it gives you the webhook and
// the runtime, and you call the push service. So this signs an APNs JWT and posts
// to Apple directly, which needs a paid Apple Developer account:
//
//   supabase secrets set APNS_KEY_ID=…            # the .p8 key's Key ID
//   supabase secrets set APNS_TEAM_ID=…           # your Apple team
//   supabase secrets set APNS_BUNDLE_ID=se.joelsanden.nomnom
//   supabase secrets set APNS_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"
//
// Until those exist the function is a deliberate no-op: it returns 200 with
// skipped:"apns-not-configured" so the in-app inbox keeps working on its own and
// the webhook doesn't retry forever.

import { createClient } from "jsr:@supabase/supabase-js@2";

interface NotificationRow {
  id: string;
  user_id: string;
  meal_id: string | null;
  kind: string;
  title: string;
  body: string;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: NotificationRow;
  schema: string;
}

const APNS_HOSTS = {
  sandbox: "https://api.sandbox.push.apple.com",
  production: "https://api.push.apple.com",
} as const;

function pemToPkcs8(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

function base64url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/// APNs wants an ES256 JWT signed with the .p8 key, valid at most an hour.
async function apnsToken(keyId: string, teamId: string, privateKeyPem: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(privateKeyPem),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const encoder = new TextEncoder();
  const header = base64url(encoder.encode(JSON.stringify({ alg: "ES256", kid: keyId })));
  const claims = base64url(encoder.encode(JSON.stringify({
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
  })));

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: { name: "SHA-256" } },
    key,
    encoder.encode(`${header}.${claims}`),
  );

  return `${header}.${claims}.${base64url(new Uint8Array(signature))}`;
}

Deno.serve(async (req) => {
  // The webhook authenticates with a secret header; deploy with verify_jwt = false.
  const expected = Deno.env.get("WEBHOOK_SECRET");
  if (expected && req.headers.get("x-webhook-secret") !== expected) {
    return new Response("forbidden", { status: 403 });
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return Response.json({ error: "bad payload" }, { status: 400 });
  }

  if (payload.type !== "INSERT" || payload.table !== "notifications") {
    return Response.json({ skipped: "not-a-new-notification" });
  }

  const keyId = Deno.env.get("APNS_KEY_ID");
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const bundleId = Deno.env.get("APNS_BUNDLE_ID");
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY");

  if (!keyId || !teamId || !bundleId || !privateKey) {
    // Expected until there's an Apple Developer account. Not an error.
    console.log("APNs not configured; in-app inbox will carry this notification.");
    return Response.json({ skipped: "apns-not-configured" });
  }

  // Service role: we need to read another user's device tokens, which RLS
  // rightly forbids to everyone else.
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Check user notification preferences in profile
  const { data: profile } = await admin
    .from("profiles")
    .select("notify_push_party_invite, notify_push_meal_invite")
    .eq("id", payload.record.user_id)
    .single();

  if (profile) {
    const kind = payload.record.kind;
    if (kind === "party_invite" && profile.notify_push_party_invite === false) {
      console.log("Push notification skipped: user disabled party invite push notifications.");
      return Response.json({ skipped: "push-notifications-disabled" });
    }
    if ((kind === "rating_request" || kind === "meal_invite") && profile.notify_push_meal_invite === false) {
      console.log("Push notification skipped: user disabled meal push notifications.");
      return Response.json({ skipped: "push-notifications-disabled" });
    }
  }

  const { data: tokens, error } = await admin
    .from("device_tokens")
    .select("apns_token, environment")
    .eq("user_id", payload.record.user_id);

  if (error) {
    console.error("could not load device tokens", error);
    return Response.json({ error: error.message }, { status: 500 });
  }
  if (!tokens?.length) {
    return Response.json({ skipped: "no-devices" });
  }

  const jwt = await apnsToken(keyId, teamId, privateKey);

  const results = await Promise.all(tokens.map(async (device) => {
    const host = APNS_HOSTS[device.environment as keyof typeof APNS_HOSTS] ?? APNS_HOSTS.sandbox;
    const response = await fetch(`${host}/3/device/${device.apns_token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
      },
      body: JSON.stringify({
        aps: {
          alert: { title: payload.record.title, body: payload.record.body },
          sound: "default",
          "thread-id": payload.record.meal_id ?? undefined,
        },
        mealId: payload.record.meal_id,
        kind: payload.record.kind,
      }),
    });

    // 410 Gone means the token is dead — clean it up rather than retrying forever.
    if (response.status === 410) {
      await admin.from("device_tokens").delete().eq("apns_token", device.apns_token);
    }
    return { token: device.apns_token.slice(0, 8), status: response.status };
  }));

  return Response.json({ sent: results });
});
