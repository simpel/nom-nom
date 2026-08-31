// Sends an email with an invite link to join a dinner party / household.
//
// When called by a signed-in member, this function:
// 1. Verifies the caller's JWT.
// 2. Looks up the party name and inviter's name.
// 3. Invokes Supabase Auth Admin API to invite the user by email (or generate a magic link if already registered).
//
// Deploy with:
//   supabase functions deploy send-invite-email

import { createClient } from "jsr:@supabase/supabase-js@2";

interface RequestBody {
  party_id: string;
  invitee_email: string;
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
    ? `${profile.first_name} ${profile.last_name}`.trim()
    : (profile?.display_name || "Someone");
  const partyName = party?.name || "a dinner party";

  console.log(`Sending invite email to ${email} for party "${partyName}" from ${inviterName}`);

  let inviteResult;
  try {
    const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
      data: {
        invited_to_party_id: party_id,
        party_name: partyName,
        inviter_name: inviterName,
      },
    });

    if (error) {
      // If user already registered, generate an email magic link for them
      console.log(`inviteUserByEmail notice: ${error.message}. Generating link for existing user.`);
      const linkRes = await admin.auth.admin.generateLink({
        type: "magiclink",
        email: email,
      });
      inviteResult = { sent: true, existingUser: true, details: linkRes.error ? linkRes.error.message : "link generated" };
    } else {
      inviteResult = { sent: true, newUser: true, user: data?.user?.id };
    }
  } catch (err: any) {
    console.error("Error sending invite email:", err);
    return Response.json({ error: err.message }, { status: 500 });
  }

  return Response.json({
    success: true,
    email: email,
    party: partyName,
    inviter: inviterName,
    result: inviteResult,
  });
});
