# Releasing Nom Nom

> **Tracked in more detail** as [issue #1, *Finish hosted Supabase*](https://github.com/simpel/nom-nom/issues/1)
> and its child tickets. That map covers the backend and push; this file stays the
> App Store checklist. Where they overlap, the map is the one being worked.

What has to happen between here and an App Store build, in the order it has to
happen. Each phase depends on the one before it.

**Legend** — 🔴 blocks submission · 🟡 blocks automation or hurts review · ⚪ nice to have

---

## Phase 0 — Apple Developer Program

Nothing else can start until this exists.

- [x] 🔴 **Enrol in the Apple Developer Program** — **done.** Team `D4F66LSYSF`.
      Confirmed by the signing identities on this machine: `Apple Distribution:
      Joel Sanden (D4F66LSYSF)` and a Mac App Store distribution certificate, both
      issued only to members.
- [ ] 🔴 **Register the App ID** `se.joelsanden.nomnom` in Certificates, Identifiers & Profiles.
      Enable the **Push Notifications** capability while you're there.
- [ ] 🔴 **Create the app record** in App Store Connect using that same bundle ID.

> The bundle ID is permanent once submitted. It was renamed to `se.joelsanden.nomnom`
> ahead of this precisely so it never has to change again.

---

## Phase 1 — Code that must land first

### 🔴 Account deletion — the one real blocker

App Store Review **Guideline 5.1.1(v)**: any app that lets users create an account
must let them delete it from inside the app. Nom Nom creates accounts on first
sign-in and currently only offers **Sign out** (`Views/Settings/EatersView.swift:91`).
This *will* be rejected.

It is not a checkbox — it needs both halves:

1. **Backend.** A client can't delete its own auth user; that needs `service_role`.
   Add an Edge Function alongside `notify-invitees` that calls
   `supabase.auth.admin.deleteUser(uid)`, taking the caller's JWT and deleting only
   the caller.
2. **Storage.** Every table already cascades from `auth.users` (`…000100_invite_schema.sql`),
   so the Postgres side cleans itself up. **The bucket does not** — a cascade can't
   reach into storage. The function must list and remove `meal-photos/<meal_id>/…`
   for the user's meals *before* deleting the user, or the photos are orphaned with
   no row left pointing at them.
3. **UI.** A destructive row in Settings behind a confirmation, then sign out.

- [x] 🔴 Edge Function `delete-account` **written** — `supabase/functions/delete-account/`.
      Takes the account from the caller's own JWT, never the request body, and pages
      the storage listing so a long history isn't silently truncated. **Not deployed.**
- [x] 🔴 Storage cleanup before user deletion — the function clears the bucket prefix
      before removing the user, because a Postgres cascade cannot reach into storage.
- [x] 🔴 Settings UI + confirmation — `EatersView.swift`, with `AuthController.deleteAccount()`.
- [ ] 🔴 Verify: delete an account, confirm zero rows in all 8 tables *and* an empty bucket prefix

### 🔴 App icon

`Assets.xcassets/AppIcon.appiconset/` declares a 1024×1024 slot with **no image
file**. A build with no icon is rejected automatically before review.

- [x] 🔴 **Done** — 1024×1024 PNG added to `NomNom/Assets.xcassets/AppIcon.appiconset/AppIcon.png`

### 🟡 Export compliance key

`ITSAppUsesNonExemptEncryption` isn't set, so every single upload stops to ask you
the encryption question by hand — which also blocks unattended CI.

- [x] 🟡 **Done** — `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` is set on both
      build configs in `project.pbxproj`.

> `NO` is the correct answer when the only cryptography is HTTPS, which is the case
> here. If that ever stops being true, this has to be revisited.

### ⚪ Sign in with Apple — probably *not* required

Guideline 4.8 only bites when an app offers **third-party or social** login.
Nom Nom's emailed code is first-party, so 4.8 shouldn't apply and this shouldn't
block you. Worth a second look before submitting, since a wrong reading costs a
rejection cycle.

- [ ] ⚪ Confirm 4.8 doesn't apply, or add Sign in with Apple. No longer blocked by
      the account — that exists now — so this is purely a reading of the guideline.

---

## Phase 2 — Hosted Supabase

### 🔴 The email template

**This is the one that silently breaks everything.** GoTrue's stock template sends
`{{ .ConfirmationURL }}` — a link. The app asks for a six-digit code. On the hosted
project, sign-in simply cannot be completed until the template carries `{{ .Token }}`.
The CLI does not push auth templates, so this is manual and easy to forget.

Paste `supabase/templates/magic_link.html` into **both**:

- [ ] 🔴 Authentication → Email Templates → **Magic Link**
- [ ] 🔴 Authentication → Email Templates → **Confirm signup**

<https://supabase.com/dashboard/project/bctbqsrsmkyputxyiyzh/auth/templates>

Both, because `magic_link` goes to an address that already has an account and
`confirmation` goes to a brand new one — and a first-ever user hits the second one.

### Schema and functions

**Automated Deployment (Recommended):**
With `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID`, and `SUPABASE_DB_PASSWORD` set in GitHub Secrets (see [CI.md](CI.md)), pushing or merging to `main` automatically runs `.github/workflows/supabase-deploy.yml` to apply pending migrations and deploy Edge Functions.

**Manual Fallback:**
```bash
npx supabase@latest link --project-ref bctbqsrsmkyputxyiyzh
npx supabase@latest db push          # should report "up to date"
npx supabase@latest functions deploy delete-account
npx supabase@latest functions deploy notify-invitees
npx supabase@latest functions deploy send-invite-email
```

- [ ] 🔴 `db push` applies `20260827000000_baseline.sql` to a project that has never
      seen a migration. This should be the first clean push in the project's life —
      the drifted history belonged to the project that was replaced.
- [ ] 🟡 Database Webhook on `INSERT` into `public.notifications` → `notify-invitees`
- [ ] 🟡 Re-confirm `anon` has nothing: all 8 tables should return `401`, not `200 []`

> The `supabase` CLI is **not** installed globally on this machine — use `npx supabase@latest`.

---

## Phase 3 — Verify the release build

Everything verified so far ran against **local** Supabase in a Debug build. The
Release path — hosted project, hosted keys, `#if DEBUG` code stripped — has never
been exercised end to end. Do it before you ship, not after.

- [ ] 🔴 Archive a Release build and run it on a real device
- [ ] 🔴 Sign in with a **real** address against the hosted project (this proves Phase 2's template)
- [ ] 🔴 Log a meal with a photo; confirm the row and the object land in the hosted project
- [ ] 🔴 Invite a second real account and rate from it
- [ ] 🟡 Confirm `DevSignIn` / `DevSelfCheck` / `SampleData` are absent from the Release binary
      (all three are `#if DEBUG`-guarded — confirm, don't assume)

> On a physical device `127.0.0.1` is the phone, not your Mac — which is exactly why
> Release must point at the hosted project. That's already handled in
> `SupabaseConfig.swift`, but it's the kind of thing to see working rather than read.

---

## Phase 4 — Store listing

- [ ] 🔴 **Privacy policy URL** — required for any app with accounts. Must cover email
      addresses, photos, and the fact that invitees can see a meal you shared with them.
- [ ] 🔴 **App Privacy** answers — you collect **Email** (account) and **Photos** (user content),
      both linked to identity. Answering these wrong is a common rejection.
- [ ] 🔴 Screenshots — 6.9" iPhone at minimum; the four tabs with sample data look fine
- [ ] 🔴 Name, subtitle, description, keywords, support URL
- [ ] 🔴 Age rating questionnaire
- [ ] ⚪ Set `MARKETING_VERSION` to `1.0` deliberately (it's already 1.0)

---

## Phase 5 — Ship

- [ ] Archive → upload to TestFlight
- [ ] Install from TestFlight and repeat Phase 3 once on the TestFlight build
- [ ] Submit for review

---

## Deliberately not blocking

- **Push notifications.** `notify-invitees` returns `{"skipped":"apns-not-configured"}`
  without the APNs secrets — a no-op, not an error. The in-app inbox works alone.
  Add the APNs key after Phase 0 whenever you like.
- **Offline mode.** Needs `updated_at` and tombstones in the schema first. A v1.1 conversation.
- **Test target.** There isn't one. `RankingCore` is pure and testable and the 33-check
  RLS suite plus the 17-check `DevSelfCheck` cover the backend, but nothing automated
  presses a button. Worth having before the *second* release; not a gate on the first.

---

## Shortest path

If you only read one thing: **enrol** → **account deletion** → **app icon** →
**email template** → **verify a Release build against hosted**. Those five are the
difference between "submittable" and "rejected". Everything else is paperwork.

See [CI.md](CI.md) for automating the build-and-upload half of this.
