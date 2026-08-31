// Deletes the caller's own account and everything belonging to it.
//
// App Store Review Guideline 5.1.1(v) requires that an app which lets people
// create an account also lets them delete it from inside the app. Nom Nom creates
// an account on first sign-in, so this is a condition of shipping at all.
//
// Why a function rather than a client call: nothing on the device can remove an
// auth user. That is a `service_role` operation, and the service role key must
// never reach a phone — it bypasses RLS entirely. So the device asks, and this
// function, which holds the key, does the work.
//
// The account to delete is taken from the caller's JWT and never from the request
// body. Accepting a user id would turn this into "delete anybody" for anyone
// holding any valid token.
//
//   supabase functions deploy delete-account
//
// Unlike notify-invitees this one keeps the default verify_jwt = true: it is
// called by a signed-in user, not by a webhook.

import { createClient } from "jsr:@supabase/supabase-js@2";

const BUCKET = "meal-photos";

/// PostgREST caps a select at `db.max_rows` (1000 by default). A household that
/// has been logging for years can exceed that, and a silent truncation here means
/// photos left in the bucket with no row left to find them by — so page.
const PAGE = 1000;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "use POST" }, { status: 405 });
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return Response.json({ error: "not signed in" }, { status: 401 });
  }

  const url = Deno.env.get("SUPABASE_URL")!;

  // Resolve the caller by handing their own token back to GoTrue. This is the
  // whole security model of the function: whoever this resolves to is the only
  // account that can be deleted by this request.
  const caller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authorization } },
  });

  const { data: { user }, error: whoError } = await caller.auth.getUser();
  if (whoError || !user) {
    return Response.json({ error: "not signed in" }, { status: 401 });
  }

  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // ---- 1. Photos, before anything else -------------------------------------
  //
  // Every table cascades from auth.users, so deleting the user cleans out
  // Postgres on its own. The bucket is the exception: a foreign key cascade
  // cannot reach into storage. Once the meals rows are gone there is nothing
  // left that names the objects, so they have to go first or not at all.

  const mealIDs: string[] = [];
  for (let from = 0; ; from += PAGE) {
    const { data, error } = await admin
      .from("meals")
      .select("id")
      .eq("created_by", user.id)
      .range(from, from + PAGE - 1);

    if (error) {
      console.error("could not list meals", error);
      return Response.json({ error: error.message }, { status: 500 });
    }
    mealIDs.push(...(data ?? []).map((row) => row.id as string));
    if (!data || data.length < PAGE) break;
  }

  // Listing each meal's prefix rather than trusting `photo_path` also sweeps up
  // anything a failed cleanup orphaned earlier — replacing a photo writes a new
  // path and removes the old one, and that removal is deliberately non-fatal.
  const doomed: string[] = [];
  for (const mealID of mealIDs) {
    const { data, error } = await admin.storage.from(BUCKET).list(mealID);
    if (error) {
      console.error(`could not list ${mealID}`, error);
      return Response.json({ error: error.message }, { status: 500 });
    }
    for (const object of data ?? []) doomed.push(`${mealID}/${object.name}`);
  }

  if (doomed.length) {
    const { error } = await admin.storage.from(BUCKET).remove(doomed);
    if (error) {
      // Deliberately fatal. Reporting a successful deletion while the person's
      // photos are still sitting in the bucket is the one outcome worse than
      // failing: they asked for their data to be gone. A retry is cheap.
      console.error("could not remove photos", error);
      return Response.json({ error: error.message }, { status: 500 });
    }
  }

  // ---- 2. The account ------------------------------------------------------
  //
  // This cascades to all eight tables. Note what it also does by cascade that is
  // easy to miss: meal_invites where this user was the *invitee* disappear, and
  // so do their ratings on other people's meals — which is correct, that is
  // their data, but it means a cook's meal can lose a verdict it used to show.

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("could not delete user", deleteError);
    return Response.json({ error: deleteError.message }, { status: 500 });
  }

  console.log(`deleted account, ${doomed.length} photo(s) removed`);
  return Response.json({ deleted: true, photosRemoved: doomed.length });
});
