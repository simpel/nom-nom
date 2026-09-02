// Sends a transactional invite email via Resend to join a dinner party or rate a meal.
//
// When called by a signed-in member, this function:
// 1. Verifies the caller's JWT.
// 2. Looks up the party or meal/dish name and inviter's name.
// 3. Checks if the invited email already has an account or is a new user.
// 4. Sends a branded email with a clear Call To Action (CTA) button via Resend.
//
// Environment variables required:
//   RESEND_API_KEY: Your Resend API key (from https://resend.com/api-keys)
//   SENDER_EMAIL: Sender email address (defaults to "Nom Nom <me@joelsanden.se>")
//   APP_URL: App deep link or web landing URL (defaults to "nomnom://invite")
//
// Deploy with:
//   supabase functions deploy send-invite-email

import { createClient } from "jsr:@supabase/supabase-js@2";
import { Resend } from "npm:resend@4.1.2";

interface RequestBody {
  party_id?: string;
  meal_id?: string;
  invitee_email: string;
}

function buildEmailHtml(params: {
  inviterName: string;
  itemName: string;
  itemLabel: string;
  description: string;
  isExistingUser: boolean;
  inviteeEmail: string;
  actionUrl: string;
  ctaText: string;
}): string {
  const {
    inviterName,
    itemName,
    itemLabel,
    description,
    isExistingUser,
    inviteeEmail,
    actionUrl,
    ctaText,
  } = params;

  return `
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>You're invited to Nom Nom</title>
  <!--[if mso]>
  <style>
    * { font-family: sans-serif !important; }
  </style>
  <![endif]-->
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #0d0e12;
      color: #f1f5f9;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
      -webkit-text-size-adjust: 100%;
    }
    table {
      border-collapse: collapse;
      mso-table-lspace: 0pt;
      mso-table-rspace: 0pt;
    }
    td {
      padding: 0;
    }
    img {
      border: 0;
      height: auto;
      line-height: 100%;
      outline: none;
      text-decoration: none;
    }
    .wrapper {
      width: 100%;
      table-layout: fixed;
      background-color: #0d0e12;
      padding: 40px 0 60px 0;
    }
    .container {
      max-width: 560px;
      margin: 0 auto;
      background-color: #16181f;
      border: 1px solid #272a38;
      border-radius: 20px;
      overflow: hidden;
      box-shadow: 0 12px 30px rgba(0, 0, 0, 0.45);
    }
    .header {
      background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
      padding: 36px 32px 32px 32px;
      text-align: center;
    }
    .logo-badge {
      display: inline-block;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      width: 56px;
      height: 56px;
      line-height: 56px;
      font-size: 30px;
      margin-bottom: 12px;
    }
    .brand-title {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #ffffff;
      margin: 0;
    }
    .brand-subtitle {
      font-size: 13px;
      color: rgba(255, 255, 255, 0.85);
      margin: 4px 0 0 0;
      font-weight: 500;
    }
    .content {
      padding: 36px 32px 28px 32px;
      color: #cbd5e1;
      font-size: 16px;
      line-height: 1.6;
    }
    .headline {
      font-size: 22px;
      font-weight: 700;
      color: #ffffff;
      margin: 0 0 14px 0;
      line-height: 1.3;
      text-align: center;
    }
    .lead-text {
      text-align: center;
      font-size: 16px;
      color: #94a3b8;
      margin: 0 0 24px 0;
      line-height: 1.5;
    }
    .item-card {
      background-color: #1e2230;
      border: 1px solid #33384c;
      border-radius: 14px;
      padding: 22px 20px;
      margin: 0 0 28px 0;
      text-align: center;
    }
    .item-badge {
      display: inline-block;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1.2px;
      color: #f97316;
      background: rgba(249, 115, 22, 0.12);
      padding: 4px 12px;
      border-radius: 100px;
      margin-bottom: 10px;
    }
    .item-name {
      font-size: 22px;
      font-weight: 800;
      color: #ffffff;
      margin: 0;
      letter-spacing: -0.3px;
    }
    .cta-container {
      text-align: center;
      margin: 28px 0 32px 0;
    }
    .cta-button {
      display: inline-block;
      background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
      color: #ffffff !important;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      font-size: 17px;
      font-weight: 700;
      text-decoration: none;
      padding: 16px 36px;
      border-radius: 14px;
      box-shadow: 0 6px 20px rgba(249, 115, 22, 0.4);
      letter-spacing: -0.2px;
    }
    .helper-box {
      background-color: #12141a;
      border: 1px solid #232736;
      border-radius: 12px;
      padding: 18px 20px;
      margin-top: 24px;
      font-size: 14px;
      color: #94a3b8;
      line-height: 1.5;
    }
    .helper-title {
      font-size: 13px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      color: #cbd5e1;
      margin: 0 0 6px 0;
    }
    .footer {
      background-color: #0f1117;
      padding: 24px 32px;
      font-size: 12px;
      color: #64748b;
      text-align: center;
      border-top: 1px solid #232736;
    }
    .footer a {
      color: #94a3b8;
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      
      <!-- Header -->
      <div class="header">
        <div class="logo-badge">🍽️</div>
        <h1 class="brand-title">Nom Nom</h1>
        <p class="brand-subtitle">Share good food with the people you care about</p>
      </div>

      <!-- Content -->
      <div class="content">
        <h2 class="headline">You're invited!</h2>
        <p class="lead-text">${description}</p>

        <!-- Highlight Card -->
        <div class="item-card">
          <div class="item-badge">${itemLabel}</div>
          <div class="item-name">${itemName}</div>
        </div>

        <!-- Primary CTA Button -->
        <div class="cta-container">
          <a href="${actionUrl}" class="cta-button" target="_blank">
            ${ctaText}
          </a>
        </div>

        <!-- Instructions & Fallback -->
        <div class="helper-box">
          <div class="helper-title">How to get started</div>
          ${
            isExistingUser
              ? `Tap the button above to open <strong>Nom Nom</strong> on your device, or open the app anytime to accept your invitation in your party / inbox settings.`
              : `1. Tap the button above to open or install <strong>Nom Nom</strong> on your phone.<br>2. Sign in with your email (<strong>${inviteeEmail}</strong>).<br>3. Your invitation will be ready as soon as you sign in!`
          }
        </div>
      </div>

      <!-- Footer -->
      <div class="footer">
        Sent by <strong>${inviterName}</strong> via Nom Nom.<br>
        If you weren't expecting this invitation, you can safely ignore this email.
      </div>

    </div>
  </div>
</body>
</html>
  `.trim();
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "use POST" }, { status: 405 });
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return Response.json({ error: "not signed in" }, { status: 401 });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "bad json body" }, { status: 400 });
  }

  const { party_id, meal_id, invitee_email } = body;
  if ((!party_id && !meal_id) || !invitee_email) {
    return Response.json({ error: "party_id or meal_id and invitee_email are required" }, { status: 400 });
  }

  const email = invitee_email.trim().toLowerCase();
  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const senderEmail = Deno.env.get("SENDER_EMAIL") || "Nom Nom <me@joelsanden.se>";
  const appUrl = Deno.env.get("APP_URL") || "nomnom://invite";

  if (!resendApiKey) {
    console.error("Missing RESEND_API_KEY environment variable in Edge Function secrets.");
    return Response.json(
      { error: "RESEND_API_KEY not configured. Please set it using: supabase secrets set RESEND_API_KEY=..." },
      { status: 500 }
    );
  }

  // Resolve caller by token
  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: { user }, error: whoError } = await caller.auth.getUser();
  if (whoError || !user) {
    return Response.json({ error: "not signed in" }, { status: 401 });
  }

  const admin = createClient(url, serviceKey);

  // Fetch caller profile
  const { data: profile } = await admin
    .from("profiles")
    .select("first_name, last_name, display_name")
    .eq("id", user.id)
    .single();

  const inviterName = profile?.first_name
    ? `${profile.first_name} ${profile.last_name || ""}`.trim()
    : (profile?.display_name || "Someone");

  let subject: string;
  let itemName: string;
  let itemLabel: string;
  let description: string;
  let ctaText: string;
  let actionUrl: string;

  if (meal_id) {
    const { data: meal } = await admin
      .from("meals")
      .select("id, dish_id, dishes(name)")
      .eq("id", meal_id)
      .single();

    const dishName = (meal?.dishes as any)?.name || "a delicious meal";
    itemName = dishName;
    itemLabel = "Meal to Rate";
    subject = `${inviterName} invited you to rate ${dishName} on Nom Nom`;
    description = `<strong>${inviterName}</strong> cooked / shared <strong>${dishName}</strong> and invited you to rate it on <strong>Nom Nom</strong>.`;
    ctaText = "Rate Meal";
    actionUrl = `nomnom://rate-meal?id=${meal_id}`;
  } else {
    const { data: party } = await admin
      .from("parties")
      .select("name")
      .eq("id", party_id)
      .single();

    const partyName = party?.name || "a dinner party";
    itemName = partyName;
    itemLabel = "Dinner Party / Household";
    subject = `${inviterName} invited you to join ${partyName} on Nom Nom`;
    description = `<strong>${inviterName}</strong> has invited you to join <strong>${partyName}</strong> on <strong>Nom Nom</strong> to share meal logs and rate food together.`;
    ctaText = "Join Dinner Party";
    actionUrl = party_id ? `nomnom://invite?party_id=${party_id}` : (appUrl || "nomnom://invite");
  }

  console.log(`Sending Resend invite email to ${email} for "${itemName}" from ${inviterName}`);

  // Check if user already exists in auth.users
  const { data: existingUserList } = await admin.auth.admin.listUsers();
  const existingUser = existingUserList?.users?.find(
    (u) => u.email?.toLowerCase() === email
  );
  const isExisting = !!existingUser;

  if (existingUser) {
    const { data: recipientProfile } = await admin
      .from("profiles")
      .select("notify_email_party_invite, notify_email_meal_invite")
      .eq("id", existingUser.id)
      .single();

    if (recipientProfile) {
      const emailAllowed = meal_id
        ? recipientProfile.notify_email_meal_invite !== false
        : recipientProfile.notify_email_party_invite !== false;

      if (!emailAllowed) {
        console.log(
          `Skipping email to ${email} because user opted out of ${
            meal_id ? "meal" : "party"
          } email notifications.`
        );
        return Response.json({
          skipped: "email-notifications-disabled",
          email: email,
          item: itemName,
          inviter: inviterName,
        });
      }
    }
  }

  // Initialize Resend
  const resend = new Resend(resendApiKey);

  const htmlContent = buildEmailHtml({
    inviterName,
    itemName,
    itemLabel,
    description,
    isExistingUser: isExisting,
    inviteeEmail: email,
    actionUrl: actionUrl,
    ctaText: ctaText,
  });

  try {
    const { data: resendData, error: resendError } = await resend.emails.send({
      from: senderEmail,
      to: [email],
      subject: subject,
      html: htmlContent,
    });

    if (resendError) {
      console.error("Resend API error:", resendError);
      return Response.json({ error: resendError.message }, { status: 500 });
    }

    console.log(`Successfully sent email via Resend! ID: ${resendData?.id}`);

    return Response.json({
      success: true,
      email: email,
      item: itemName,
      inviter: inviterName,
      isExistingUser: isExisting,
      resendId: resendData?.id,
    });
  } catch (err: any) {
    console.error("Unexpected error sending email with Resend:", err);
    return Response.json({ error: err.message }, { status: 500 });
  }
});
