// Sends a transactional invite email via Resend to join a dinner party / household.
//
// When called by a signed-in member, this function:
// 1. Verifies the caller's JWT.
// 2. Looks up the party name and inviter's name.
// 3. Checks if the invited email already has an account or is a new user.
// 4. Sends a branded email via Resend to the invitee.
//
// Environment variables required:
//   RESEND_API_KEY: Your Resend API key (from https://resend.com/api-keys)
//   SENDER_EMAIL: Sender email address (defaults to "Nom Nom <me@joelsanden.se>")
//
// Deploy with:
//   supabase functions deploy send-invite-email

import { createClient } from "jsr:@supabase/supabase-js@2";
import { Resend } from "npm:resend@4.1.2";

interface RequestBody {
  party_id: string;
  invitee_email: string;
}

function buildEmailHtml(params: {
  inviterName: string;
  partyName: string;
  isExistingUser: boolean;
  inviteeEmail: string;
}): string {
  const { inviterName, partyName, isExistingUser, inviteeEmail } = params;

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>You're invited to Nom Nom</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #0d0e12;
      color: #f1f5f9;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }
    .wrapper {
      max-width: 560px;
      margin: 40px auto;
      background-color: #16181f;
      border: 1px solid #272a38;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.4);
    }
    .header {
      background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
      padding: 32px 28px;
      text-align: center;
    }
    .logo {
      font-size: 28px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #ffffff;
      margin: 0;
    }
    .content {
      padding: 36px 32px;
      color: #cbd5e1;
      font-size: 16px;
      line-height: 1.6;
    }
    .headline {
      font-size: 22px;
      font-weight: 700;
      color: #ffffff;
      margin: 0 0 16px 0;
      line-height: 1.3;
    }
    .party-box {
      background-color: #1e2230;
      border: 1px solid #33384c;
      border-radius: 12px;
      padding: 20px;
      margin: 24px 0;
      text-align: center;
    }
    .party-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #94a3b8;
      margin-bottom: 6px;
    }
    .party-name {
      font-size: 20px;
      font-weight: 700;
      color: #f97316;
      margin: 0;
    }
    .instructions {
      margin: 24px 0;
      font-size: 15px;
      color: #94a3b8;
    }
    .footer {
      background-color: #0f1117;
      padding: 20px 32px;
      font-size: 12px;
      color: #64748b;
      text-align: center;
      border-top: 1px solid #232736;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <h1 class="logo">🍽️ Nom Nom</h1>
    </div>
    <div class="content">
      <h2 class="headline">You're invited!</h2>
      <p><strong>${inviterName}</strong> has invited you to join their household / dinner party on <strong>Nom Nom</strong> to share meal logs and rate delicious food together.</p>
      
      <div class="party-box">
        <div class="party-label">Dinner Party / Household</div>
        <div class="party-name">${partyName}</div>
      </div>

      ${
        isExistingUser
          ? `<p class="instructions">Open <strong>Nom Nom</strong> on your device to view and accept the invitation in your party settings.</p>`
          : `<p class="instructions">To get started, open <strong>Nom Nom</strong> on your device and sign in using your email address (<strong>${inviteeEmail}</strong>). Your invitation will be ready for you as soon as you sign in!</p>`
      }
    </div>
    <div class="footer">
      Sent with Nom Nom · Sharing good food with the people you care about.
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

  const { party_id, invitee_email } = body;
  if (!party_id || !invitee_email) {
    return Response.json({ error: "party_id and invitee_email are required" }, { status: 400 });
  }

  const email = invitee_email.trim().toLowerCase();
  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const senderEmail = Deno.env.get("SENDER_EMAIL") || "Nom Nom <me@joelsanden.se>";

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

  // Fetch party info and caller profile
  const { data: party } = await admin
    .from("parties")
    .select("name")
    .eq("id", party_id)
    .single();

  const { data: profile } = await admin
    .from("profiles")
    .select("first_name, last_name, display_name")
    .eq("id", user.id)
    .single();

  const inviterName = profile?.first_name
    ? `${profile.first_name} ${profile.last_name || ""}`.trim()
    : (profile?.display_name || "Someone");
  const partyName = party?.name || "a dinner party";

  console.log(`Sending Resend invite email to ${email} for party "${partyName}" from ${inviterName}`);

  // Check if user already exists in auth.users
  const { data: existingUserList } = await admin.auth.admin.listUsers();
  const existingUser = existingUserList?.users?.find(
    (u) => u.email?.toLowerCase() === email
  );
  const isExisting = !!existingUser;

  // Initialize Resend
  const resend = new Resend(resendApiKey);

  const subject = `${inviterName} invited you to join ${partyName} on Nom Nom`;
  const htmlContent = buildEmailHtml({
    inviterName,
    partyName,
    isExistingUser: isExisting,
    inviteeEmail: email,
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
      party: partyName,
      inviter: inviterName,
      isExistingUser: isExisting,
      resendId: resendData?.id,
    });
  } catch (err: any) {
    console.error("Unexpected error sending email with Resend:", err);
    return Response.json({ error: err.message }, { status: 500 });
  }
});
