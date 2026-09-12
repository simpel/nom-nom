// Fans a `notifications` row out to the user's Apple devices and, optionally, their inbox.
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
// Email delivery reuses RESEND_API_KEY / SENDER_EMAIL (already set for
// send-invite-email). Invite kinds (party_invite, rating_request) are NOT
// emailed here — send-invite-email owns that path, including the not-yet-a-user
// case. This function only emails the events that have no other channel:
// rating_received, party_joined, party_followed, recipe_liked.
//
// Until the APNs secrets exist the push half is a deliberate no-op: it returns
// 200 with skipped:"apns-not-configured" so the in-app inbox keeps working and
// the webhook doesn't retry forever.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { Resend } from "npm:resend@4.1.2";

interface NotificationRow {
  id: string;
  user_id: string;
  meal_id: string | null;
  party_id: string | null;
  dish_id: string | null;
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

// kind -> the profile column that switches this event off entirely.
const KIND_PREF: Record<string, string> = {
  rating_request: "notify_meal_invite",
  rating_received: "notify_meal_rating",
  party_invite: "notify_party_invite",
  party_joined: "notify_party_activity",
  party_followed: "notify_party_activity",
  recipe_liked: "notify_recipe_like",
};

// Kinds this function is allowed to email. Invite kinds are excluded — they go
// out through send-invite-email so they aren't sent twice.
const EMAIL_KINDS = new Set([
  "rating_received",
  "party_joined",
  "party_followed",
  "recipe_liked",
]);

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

function deepLink(record: NotificationRow): string {
  // https://www.nomnom.casa/invite universal-links into the app when it's
  // installed and falls back to the web landing page when it isn't — unlike
  // a bare nomnom:// scheme link, which does nothing without the app.
  if (record.meal_id) return `https://www.nomnom.casa/invite?meal_id=${record.meal_id}`;
  if (record.party_id) return `https://www.nomnom.casa/invite?party_id=${record.party_id}`;
  // recipe_liked carries only a dish_id, which has no deep-link target today.
  return "https://www.nomnom.casa";
}

function buildEmailHtml(title: string, body: string, actionUrl: string): string {
  return `
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background-color:#0d0e12;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <div style="width:100%;background-color:#0d0e12;padding:40px 0 60px 0;">
    <div style="max-width:520px;margin:0 auto;background-color:#16181f;border:1px solid #272a38;border-radius:20px;overflow:hidden;">
      <div style="background:linear-gradient(135deg,#f97316 0%,#ea580c 100%);padding:28px 32px;text-align:center;">
        <div style="display:inline-block;background:rgba(255,255,255,0.2);border-radius:50%;width:48px;height:48px;line-height:48px;font-size:18px;font-weight:800;color:#ffffff;margin-bottom:8px;">NN</div>
        <h1 style="font-size:22px;font-weight:800;color:#ffffff;margin:0;">Nom Nom</h1>
      </div>
      <div style="padding:32px;color:#cbd5e1;font-size:16px;line-height:1.6;">
        <h2 style="font-size:20px;font-weight:700;color:#ffffff;margin:0 0 10px 0;text-align:center;">${title}</h2>
        <p style="text-align:center;font-size:16px;color:#94a3b8;margin:0 0 26px 0;">${body}</p>
        <div style="text-align:center;">
          <a href="${actionUrl}" target="_blank" style="display:inline-block;background:linear-gradient(135deg,#f97316 0%,#ea580c 100%);color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;padding:14px 32px;border-radius:14px;">Open Nom Nom</a>
        </div>
      </div>
      <div style="background-color:#0f1117;padding:20px 32px;font-size:12px;color:#64748b;text-align:center;border-top:1px solid #232736;">
        You're receiving this because email notifications are on in Nom Nom. Turn them off any time in Settings.
      </div>
    </div>
  </div>
</body>
</html>`.trim();
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

  const record = payload.record;
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // One profile read covers every gate.
  const { data: profile } = await admin
    .from("profiles")
    .select(
      "notify_meal_invite, notify_meal_rating, notify_party_invite, notify_party_activity, notify_recipe_like, notify_via_push, notify_via_email",
    )
    .eq("id", record.user_id)
    .single();

  const prefCol = KIND_PREF[record.kind];
  if (prefCol && profile && profile[prefCol as keyof typeof profile] === false) {
    return Response.json({ skipped: "event-disabled" });
  }

  const wantsPush = !profile || profile.notify_via_push !== false;
  const wantsEmail = !!profile && profile.notify_via_email === true && EMAIL_KINDS.has(record.kind);

  const result: Record<string, unknown> = {};

  // ---- Email -------------------------------------------------------------
  if (wantsEmail) {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const senderEmail = Deno.env.get("SENDER_EMAIL") || "Nom Nom <me@joelsanden.se>";
    if (!resendApiKey) {
      result.email = "skipped:resend-not-configured";
    } else {
      const { data: userData } = await admin.auth.admin.getUserById(record.user_id);
      const to = userData?.user?.email;
      if (!to) {
        result.email = "skipped:no-address";
      } else {
        try {
          const resend = new Resend(resendApiKey);
          const { error } = await resend.emails.send({
            from: senderEmail,
            to: [to],
            subject: `${record.title} · Nom Nom`,
            html: buildEmailHtml(record.title, record.body, deepLink(record)),
          });
          result.email = error ? `error:${error.message}` : "sent";
        } catch (err) {
          result.email = `error:${(err as Error).message}`;
        }
      }
    }
  }

  // ---- Push -------------------------------------------------------------
  if (!wantsPush) {
    result.push = "skipped:push-disabled";
    return Response.json(result);
  }

  const keyId = Deno.env.get("APNS_KEY_ID");
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const bundleId = Deno.env.get("APNS_BUNDLE_ID");
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY");

  if (!keyId || !teamId || !bundleId || !privateKey) {
    // Expected until there's an Apple Developer account. Not an error.
    result.push = "skipped:apns-not-configured";
    return Response.json(result);
  }

  const { data: tokens, error: tokensError } = await admin
    .from("device_tokens")
    .select("apns_token, environment")
    .eq("user_id", record.user_id);

  if (tokensError) {
    console.error("could not load device tokens", tokensError);
    return Response.json({ ...result, error: tokensError.message }, { status: 500 });
  }
  if (!tokens?.length) {
    result.push = "skipped:no-devices";
    return Response.json(result);
  }

  const jwt = await apnsToken(keyId, teamId, privateKey);

  const sent = await Promise.all(tokens.map(async (device) => {
    const host = APNS_HOSTS[device.environment as keyof typeof APNS_HOSTS] ?? APNS_HOSTS.sandbox;
    const response = await fetch(`${host}/3/device/${device.apns_token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        // Store and retry for a day, then give up — an invite or rating nudge
        // that's a week stale is noise, not news.
        "apns-expiration": String(Math.floor(Date.now() / 1000) + 86_400),
      },
      body: JSON.stringify({
        aps: {
          alert: { title: record.title, body: record.body },
          sound: "default",
          "thread-id": record.meal_id ?? record.party_id ?? record.dish_id ?? undefined,
        },
        kind: record.kind,
        mealId: record.meal_id,
        partyId: record.party_id,
        dishId: record.dish_id,
      }),
    });

    // APNs puts the failure detail in the body as {"reason":"…"}; surface it so
    // a 4xx is diagnosable without guessing.
    let reason: string | undefined;
    if (!response.ok) {
      reason = (await response.text()).trim() || undefined;
      console.error("APNs rejected", { status: response.status, reason, host });
    }

    // 410 Gone means the token is dead — clean it up rather than retrying forever.
    if (response.status === 410) {
      await admin.from("device_tokens").delete().eq("apns_token", device.apns_token);
    }
    return { token: device.apns_token.slice(0, 8), status: response.status, reason };
  }));

  result.push = sent;
  return Response.json(result);
});
