# Nom Nom

An iOS app for keeping track of what you cooked, whether the kids ate it, and what
to cook next. Supabase is the source of truth: dishes, meals, household members and
verdicts live in Postgres, photos in a private storage bucket. One person can cook
and invite others to rate it.

Sign-in is an emailed six-digit code — no password, and signing in for the first
time creates the account.

Open `NomNom.xcodeproj` in Xcode and run. Deployment target iOS 17. A debug build
talks to a local Supabase; see [Running it](#running-it).

> Earlier versions kept everything on-device with SwiftData and no account. That
> layer is gone — the app now requires a login and a network connection, and there
> is no offline mode. `RankingCore` is the only part that came across untouched.

## The four tabs

**Log** — the diary. Photo (camera or library), a title, a date, and a verdict per
kid: 😋 loved / 😐 ok / 🙅 nope. Leaving a verdict blank means "didn't catch it",
which is ignored by the ranking rather than counted as a bad score.

**Calendar** — a month grid where each day shows the food's photo, with a coloured
dot per meal for how the day went. Tap a day to see its meals, or add one straight
onto that date.

**What to eat** — a ranked list of what to cook next, with a filter sheet.

**Inbox** — meals other people asked you to rate, answerable with one tap from the
list, plus a record of who rated your cooking.

## Running it

The debug build points at a local Supabase, because that is the only place the
sign-in code can actually be read: the local stack captures outgoing mail in
Mailpit instead of sending it. The hosted project's built-in SMTP is rate limited to
a couple of messages an hour and only to authorised addresses.

```bash
npx supabase@latest start      # the CLI is not installed globally here
npx supabase@latest db reset   # applies the baseline migration
```

Then ⌘R. `SupabaseConfig.swift` picks the environment with `#if DEBUG`, so a
release build goes to the hosted project instead.

### Signing in without signing in

The shared scheme passes `-dev-sign-in cook@foodlog.test`, so a debug build walks
straight past the sign-in screen into the Log tab. Nothing to type, and nothing to
do after a `db reset` clears the account out from under the keychain.

To see the real form instead, untick that argument in **Product ▸ Scheme ▸ Edit
Scheme ▸ Run ▸ Arguments**. Then sign in with any address — `you@example.com` will
do — and read the code out of Mailpit at <http://127.0.0.1:54324>.

Two more arguments sit alongside it, unticked: `-seed-sample-data` loads a few
months of made-up meals and `-initial-tab 2` opens *What to eat*, which together
give the ranking something to show. The same flags work from the command line:

```bash
xcrun simctl launch booted se.joelsanden.nomnom \
    -dev-sign-in cook@foodlog.test -seed-sample-data -initial-tab 2
```

`-dev-selfcheck` additionally runs
[the store's self check](#what-the-self-check-covers).

`DevSignIn` takes the short way when it can. The CLI bakes a fixed `service_role`
key into every local stack, so it creates `cook@foodlog.test` if it isn't there —
setting a known password and marking the address confirmed — and signs in with
`grant_type=password`. One round trip, no mail, no six digits, and it behaves the
same whether the account already existed. If any of that fails it falls back to the
flow a person actually uses: ask for a code, read it back out of Mailpit, submit it.

The password path exists **only** here. The app itself has no password login and no
UI that could reach one; the account is reachable by password because a debug build
asked a local admin API to make it so.

Both routes check the host first and refuse anything but loopback, so this cannot be
pointed at the hosted project even by accident, and the whole file — service key
included — is compiled out of release builds.

### Hot reload

Save a view file and the running app picks up the change in about a second, without
relaunching and without losing where you were — still signed in, still on the same
tab, same scroll position.

Two packages do it. [InjectionLite](https://github.com/johnno1962/InjectionLite) is
the engine: it watches for saved sources, recompiles the one file, and rebinds its
symbols in the running process. [Inject](https://github.com/krzysztofzablocki/Inject)
is the SwiftUI half — `@ObserveInjection` listens for the swap and
`.enableInjection()` re-renders. Both are plain SPM dependencies; there is no
menu-bar app to install or remember to start.

Nothing to run. ⌘R, edit, save:

```
🔄 [SuggestionsView.swift] Recompiling
⚡ Compiled in 818ms
✅ Hot reload complete - Rebound 5 symbols
```

**What reloads:** the body of any function, which in practice means view bodies —
layout, colours, strings, conditions, the scoring weights in `RankingCore`.

**What needs a normal ⌘R:** anything that changes the shape of a type rather than
its behaviour. Adding or removing a stored property, a new `@State`, a new case on
an enum, a new file, a changed function signature. If a save seems to do nothing,
that's the reason — rebuild and carry on.

Every top-level view in a file carries the two Inject lines, so every file is
covered; sub-views in the same file come along with it.

#### The three settings this needed

All three are on the **Debug** configuration only, and `project.pbxproj` is the only
place they live:

- `OTHER_LDFLAGS = -Xlinker -interposable` — without it the symbols are bound
  directly and cannot be swapped.
- `SWIFT_COMPILATION_MODE = singlefile` — injection recompiles one file, so whole-module
  is no good. Release stays on `wholemodule`.
- `EMIT_FRONTEND_COMMAND_LINES = YES` — Xcode 16.3 stopped logging the compiler
  invocations that InjectionLite reads to know how to recompile a file.

There is also a launch argument in the scheme,
`-HotReloadingBuildLogsDir $(BUILD_DIR)/../../Logs/Build/current.xcactivitylog`.
InjectionLite finds the build log by watching one land while the app is already
running, which never happens on a plain Run — so the path is handed over up front
instead, as a `UserDefaults` key read out of `NSArgumentDomain`. The filename is
ignored; only the directory matters, and the newest log in it is the one scanned. If
the console says `⚠️ Logs dir not initialised`, that argument is what to look at.

#### It does not ship

`InjectionLite` guards its whole implementation behind `#if DEBUG`, and the linker
flag is Debug-only. Checked rather than assumed — a release build has no
`OTHER_LDFLAGS`, and the binary contains zero occurrences of `InjectionLite`,
`xcactivitylog`, or the watcher's startup string.

## Keeping the names consistent

The thing that makes the rest work is that "Tacos" cooked in March and "tacos"
cooked in June are the same dish. Three mechanisms, in
[`DishRepository.swift`](NomNom/Store/DishRepository.swift) and
[`StringMatching.swift`](NomNom/Store/StringMatching.swift):

1. **Ranked autofill** under the title field — exact match, then whole-name prefix,
   then word prefix ("kött" → "Köttbullar"), then substring, then near-typo. Ties
   break towards dishes you cook often and recently.
2. **Inline ghost completion** — the rest of the best prefix match appears greyed
   out; tap the arrow to accept it.
3. **"Did you mean …?"** — if what you typed is one or two edits from an existing
   dish, the app offers to use the existing name instead. This is the safety net
   for the case where you skipped the suggestions and typed "Pancaks".

Matching is done on a folded key (lowercased, accents stripped, punctuation
collapsed), so `Köttbullar & mos` and `kottbullar mos` land on the same dish.

If two dishes drift apart anyway, open one from the *What to eat* tab and use
**Merge into another dish** — every logged meal moves across.

The client's find-or-create is the friendly path, not the guarantee: that is
`unique (owner_id, normalized_name)` in the database. Two devices logging "Tacos" at
once both miss locally and both insert, and the loser gets a `23505` — which
`FoodStore` treats as "go and read the row that won" rather than an error.

## How the suggestions are scored

The maths lives in [`RankingCore.swift`](NomNom/Store/RankingCore.swift), which is
deliberately free of SwiftData and SwiftUI so it can be reasoned about on its own.
[`SuggestionEngine.swift`](NomNom/Store/SuggestionEngine.swift) adapts the models
onto it, applies the filters, and writes the explanation chips.

Each dish gets five numbers:

| Term | Meaning |
| --- | --- |
| **like** | Recency-weighted mean verdict, 0–1. Each verdict decays with a 180-day half-life, so a dish they hated 18 months ago isn't condemned forever. |
| **readiness** | `1 − exp(−days / τ)`, where τ is the dish's *own* average gap between servings (clamped 4–60 days). A weekly staple feels overdue after a week; something you make twice a year does not. |
| **exploration** | `1 / √(1 + verdicts)` — a UCB-flavoured bonus for dishes you know least about, so ratings get more reliable over time instead of the same five meals circling forever. |
| **weekday** | Share of servings that landed on today's weekday, so taco Friday surfaces on Fridays. |
| **dislike** | Ramps 0 → 1 as the *least* happy eater's score falls from "ok" to "nope". Subtracted, so one kid's hard no can sink an otherwise popular dish. |

A dish with no verdicts scores a neutral 0.5 on *like* rather than 0 — it isn't
punished for being unknown. A dish never cooked gets readiness 0.7, not 1.0:
without any history it isn't overdue, it's just available, and letting both
readiness and exploration max out would double-count novelty.

### The four modes

Same five numbers, different weights — that's all a mode is.

| Mode | Leans on |
| --- | --- |
| **Balanced** | Liked food you haven't had lately, with a small nudge towards the barely-tried. |
| **Favourites** | Almost pure popularity; ignores exploration entirely and doubles the dislike penalty. |
| **Overdue** | Rotation first, even for merely-ok dishes. |
| **Adventurous** | The dishes you know least about. |

### The filters

- **Must be liked by** — per kid, keeps only dishes whose recent verdicts from that
  person average out to a yes (≥ 0.55).
- **Not eaten for at least N days** — a hard rotation floor on top of the soft
  readiness curve.
- **Hide dishes somebody disliked** (on by default) — drops anything where the
  worst verdict is below "ok"; catches both a named kid's no and an unnamed
  "nobody liked it".
- **Include dishes we've never rated** — off means known quantities only.
- **Tags** — free-form, entered on the meal (`quick`, `oven`, `veggie`, `friday`…).

Every row carries chips saying *why* it's there ("Everyone's happy", "Overdue — 34
days", "Elsa yes, Vidar no", "Only tried once"), and **Show scores** in the section
header reveals the raw number. Tapping a row breaks the score into its parts. A
ranking you can't interrogate is one you stop trusting.

## Layout

```
NomNom/
  Models/       Dish, Meal, MealRating, Eater, Profile,
                MealInvite, AppNotification, Reaction        — plain values, UUID keys
                PostgresDate     the two date shapes PostgREST returns
  Supabase/     SupabaseConfig   which project, and the shared client
                AuthController   session state + the email-code flow
                FoodStore        every read and write; the app's one data layer
                PhotoCache       authenticated photo fetches, memory + disk
                DevSignIn        DEBUG: sign in via Mailpit
                DevSelfCheck     DEBUG: exercise the store's writes
  Store/        RankingCore      pure scoring maths, no framework dependencies
                SuggestionEngine model adapter + filters + explanations
                DishRepository   autofill ranking and typo matching
                StringMatching   name folding + Levenshtein
                SampleData       DEBUG-only history generator
  Views/        Auth/ Log/ Calendar/ Suggestions/ Invites/ Settings/ Shared/
```

Each row type has a matching insert or patch struct (`NewMeal`, `MealPatch`, …)
rather than being `Encodable` itself, because the database fills in `id` and
`created_at` and sending our own would fight the defaults.

`FoodStore` holds the whole visible dataset in memory. That fits the problem rather
than ducking it: the ranking needs every serving of every dish to work out a
rotation rhythm, so there is no useful partial load, and a household's few hundred
meals is nothing. One fetch on sign-in, then the arrays are patched as writes
succeed.

RLS decides what a plain `select()` returns, so those arrays hold my rows *plus*
the meals other people invited me to. The `myDishes` / `myMeals` accessors draw that
line for the views — the diary should show what I cooked, not somebody else's
dinner.

### Photos

Downscaled to 1600px and JPEG-encoded, then uploaded to the private `meal-photos`
bucket as `<meal_id>/<uuid>.jpg`. That layout is load-bearing: the storage policies
read the meal id back out of the first path segment to decide who may see the
object.

A private bucket has no plain URL to hand to `AsyncImage` — every read is an
authenticated request — so `PhotoCache` downloads the bytes itself and keeps them in
memory and on disk. Without it, scrolling the calendar would re-fetch a photo for
every cell that came back on screen. Cache entries never need invalidating: a
replaced photo is written to a brand new path, so a path always means the same
bytes.

Two ordering details that are easy to get backwards:

- The photo is uploaded *after* the meal row exists. The storage policy checks the
  meal id in the path against a real row in `meals`, so before the first save there
  is nothing to upload to.
- On delete, the object goes first. A row's cascade cannot reach into the bucket, so
  deleting the row first loses the only pointer to the object.

In debug builds, **Log → 👥 → Fill with sample history** loads a few months of
made-up meals so the suggestion tab has something to chew on. It's idempotent.

## `anon` holds nothing

Supabase installs default privileges in `public` that grant all of
INSERT/SELECT/UPDATE/DELETE to `anon` when the creating role is `supabase_admin`.
Locally the migrations run as `postgres`, whose default ACL grants `anon` only
`Dxtm`, so there is no SELECT and the difference never shows up. On the hosted
project it did: an unauthenticated request carrying only the publishable key
returned `200 []` for all eight tables. `anon` genuinely had SELECT, and RLS was
the only thing between that key and the data.

The baseline's final section takes it back, and also revokes it from the
role's default privileges so it can't quietly return on the next table. RLS is
supposed to be the second line, not the only one. `anon` is the pre-login role and
has nothing to do here — sign-up goes through GoTrue and `handle_new_user` is
`security definer`.

Verified against the deployed project: all eight tables return
`401 permission denied`, and an `anon` INSERT is refused at the privilege level
before RLS is even consulted. `authenticated` is untouched.

## Verifying the ranking

`RankingCore.swift` has no framework dependencies, so it can be exercised directly
against a frozen `now` — feed it a fixture of dishes and check the four modes order
them the way you'd expect. That's how the weights above were tuned: the first pass
put a never-cooked dish above the kids' favourites in Balanced mode, which is what
surfaced the readiness/exploration double-count.

## Not done yet

- **No offline mode.** Every read and write goes to Postgres, so the app needs a
  connection and shows an error without one. Nothing is queued or retried. Going
  offline-capable means a local cache and a sync story, and the schema has no
  support for the hard part — no `updated_at` on `dishes` or `meals`, no tombstones,
  so there is nothing to resolve a conflict with.
- **No test target in the project file.** `RankingCore` is written to be testable and
  the RLS suite runs against the API, but there is no XCUITest target, so no
  automated test taps a single button. See
  [what is and isn't verified](#what-is-and-isnt-verified).
- **Sign in with Apple** is still unwritten. No longer blocked — the Developer
  Program membership exists (team `D4F66LSYSF`) — but it is App Store Guideline 4.8
  work rather than anything this backend needs, and 4.8 may not even apply, since an
  emailed code is first-party rather than social login.
- **No push notifications yet.** The Edge Function is written and signs an ES256
  APNs JWT, but it is not deployed, and the app has no push code at all: no
  entitlement, no capability, no registration, and nothing writes to
  `device_tokens`. Both halves are in progress.
- The app icon is an empty placeholder.

---

# Invite mode (Supabase backend)

One person logs a meal, invites others, and each invitee gets asked to rate it.
The backend lives in `supabase/`; the client is the *Inbox* tab plus **Ask someone to
rate this** in the meal editor.

Invites are always by email address, because that is the only identifier a client
has: `profiles` deliberately holds no address and no client role may read
`auth.users`. The database resolves it — see
[linking an invite to an existing account](#linking-an-invite-to-an-existing-account).

## Applying it

```bash
npx supabase@latest link --project-ref bctbqsrsmkyputxyiyzh
npx supabase@latest db push
npx supabase@latest functions deploy notify-invitees
npx supabase@latest functions deploy delete-account
```

Then in the dashboard add a **Database Webhook** on `INSERT` into
`public.notifications` pointing at the `notify-invitees` function. It must carry
`WEBHOOK_SECRET`, which the function checks before doing anything.

None of this is done yet on the new project — see [Status](#status).

### One manual step for the hosted project

**The email template has to carry `{{ .Token }}`.** GoTrue's stock magic-link email
contains only `{{ .ConfirmationURL }}` — a hashed link token — so an app that asks
for a six-digit code has nothing to type, and sign-in simply cannot be completed.
The code and the link are the same verification underneath; which one reaches the
user is decided entirely by the template.

Locally this is committed: `supabase/templates/` plus the
`[auth.email.template.magic_link]` and `.confirmation` blocks in `config.toml`. Both
are overridden because `magic_link` is what an address with an account receives and
`confirmation` covers a brand new one.

On the hosted project it is not, and the CLI does not push auth templates. Paste the
same body into **Authentication → Email Templates → Magic Link** *and* **Confirm
signup**:

> https://supabase.com/dashboard/project/bctbqsrsmkyputxyiyzh/auth/templates

Verifying uses `type: email`, which GoTrue accepts for both a fresh signup and an
existing account, so the client never has to know which case it is in.

## Schema

| Table | Purpose |
| --- | --- |
| `profiles` | Public face of an auth user — display name, emoji. Created automatically by a trigger on `auth.users`. |
| `dishes` | Canonical dish name per owner. `unique (owner_id, normalized_name)` is what stops "Tacos" and "tacos" splitting in two. |
| `meals` | One occasion of eating a dish. |
| `eaters` | Household members with no account — the kids. |
| `meal_invites` | Who was asked to rate a meal. `invitee_id` is null until that person signs up. |
| `meal_ratings` | One verdict per rater per meal, `reaction` 0–2 matching the client's `Reaction` enum. |
| `notifications` | The inbox, and the trigger source for push. |
| `device_tokens` | APNs tokens. Unused until there's an Apple Developer account. |

Two design points worth knowing:

**Ratings have two possible sources.** A verdict comes either from an invited
account holder (`rater_id`) or from a household member the cook rated on their
behalf (`eater_id`), enforced by a `check` constraint that exactly one is set.
Without the `eaters` table, moving storage to Postgres would have quietly dropped
the app's original feature, since only invited adults have an `auth.users` row.

**You can invite an email that has no account.** The invite is stored with
`invitee_email` and no `invitee_id`; a trigger on `auth.users` claims it on first
sign-in, which then fires the notification. Two partial unique indexes rather than
one constraint, because nulls don't collide in a unique index.

## Two things the schema got wrong

Both were found by building the client against it, and both were invisible to the
original 21 RLS checks — which is the interesting part: the tests covered what the
code did, not what the feature needed.

### Linking an invite to an existing account

Now folded into the baseline.

`handle_new_user` claims pending invites, but only on INSERT into `auth.users` — only
when the invited address signs up *after* being invited. Nothing handled the opposite
and more common order: inviting somebody who already has an account. That invite kept
`invitee_id = null` forever, and everything downstream keys off it:

- `notify_invitee` returns early, so no notification is ever created,
- `meal_invites_select` (`invitee_id = auth.uid()`) never matches, so the invitee
  cannot see the invite,
- `is_meal_participant` is false, so they cannot read the meal or the dish,
- `meal_ratings_insert` refuses their rating with `42501`.

The invite was accepted by the database and then silently did nothing. Once two
people use the app, that is the normal case.

The client cannot fix this: there is no `email → uuid` lookup available to it, by
design. So a `BEFORE INSERT` trigger resolves the address instead. A trigger rather
than an RPC keeps it off the API surface, so this adds no account-enumeration
oracle — the caller learns nothing it did not already supply.

### Being notified about your own kids' verdicts

Now folded into the baseline.

`notify_rating` guarded with `if v_creator is null or v_creator = new.rater_id`. But
`rater_id` is null for a household member's verdict, and **`uuid = null` is null, not
true**, so the guard never fired on that path. Every verdict a cook recorded for
their own kid filed a "Someone rated Tacos" notification in the cook's own inbox.
Seeding a few months of history produced 42 of them, and the badge said 42 on a
brand-new account.

The right question is not "is the rater the cook" but "is the person who *recorded*
this the cook", which for an eater rating is the household member's owner —
`meal_ratings_insert` only permits an eater rating from `eaters.owner_id =
auth.uid()`, so the owner is by construction whoever entered it.

Comparing owners also keeps the case the old code was reaching for: a guest at the
table may record their *own* child's verdict on the cook's meal, and the cook should
still hear about that one. It also lets the notification name the child, which the
old version could not — it looked the display name up by `rater_id`, null here, so an
eater rating could only ever come out as "Someone".

## Security

Every table is RLS deny-by-default. Two things that are easy to get wrong and are
both covered:

- **GRANTs are a separate layer from RLS** (the baseline's section 7). A policy
  says *which rows*; a GRANT says whether the role may touch the table at all.
  Without the grants every request fails with `42501` however correct the
  policies are. `notifications` deliberately has no `INSERT` grant — only the
  `SECURITY DEFINER` triggers write it, so nobody can forge an entry in someone
  else's inbox.
- **`SECURITY DEFINER` helpers break RLS recursion, but they're `STABLE`.** A
  policy on `meals` that queries `meal_invites`, whose policy queries `meals`,
  recurses forever; running the lookup as definer stops that. But a STABLE
  function sees the snapshot from the *start* of the statement, so during
  `INSERT ... RETURNING` it cannot see the new row. The select policies therefore
  check the owning column directly *before* falling back to the helper —
  `owner_id = auth.uid() or public.can_read_dish(id)`. Without that first branch
  every create from the app fails, because supabase-swift's `.insert().select()`
  uses `Prefer: return=representation`.

## Why the project was replaced

This app originally shared a Supabase project with an earlier, differently-shaped
nom-nom — one built around groups, meal indicators and AI-generated suggestions.
Reusing it cost more than it saved, and the schema you see is shaped by that.

Six stray tables were dropped early on: `users`, `groups`, `group_members`,
`invite_codes`, `ratings` and, awkwardly, **`meals`**. The old `meals` had
`(id, name, created_by, created_at)` and none of `dish_id`, `eaten_on`, `notes` or
`photo_path`. The schema migration originally said `create table if not exists`,
which would have quietly kept that table and then failed on every insert and
foreign key downstream.

That was the first instance of a pattern worth naming, because it kept recurring: a
statement that **assumes it is creating** an object rather than **asserting the state
that object must be in** is a silent no-op wherever the object already exists. It
looks correct, it runs without error, and it does nothing.

The one that actually drew blood was the photo bucket. `insert into storage.buckets
… on conflict (id) do nothing` met a **public** `meal-photos` bucket left behind by
the old app, hit the conflict, did nothing — and left every meal photo world-readable
behind a schema that believed it had made them private. `storage` is not a schema
this app owns, so nothing in our own cleanup could reach it.

An audit of all nine original migrations found thirteen instances of the pattern.
Rather than patch them one by one against a project nobody could fully inventory, a
**new Supabase project** was created and the migrations squashed into
`20260827000000_baseline.sql`. Re-pointing the app cost two lines in
`SupabaseConfig.swift`; there was no data to move.

So the baseline is plain — a fresh project has no previous tenant to work around —
but two habits survived, each because it cost a real bug:

- **The bucket asserts its settings** with `on conflict do update`, naming every
  column the app depends on. Not just `public`: a pre-existing `file_size_limit` or
  `allowed_mime_types` would reject the client's 1600px JPEGs at runtime with no
  migration ever complaining.
- **Privileges are revoked before they are granted.** "We deliberately withheld
  `INSERT` on `notifications`" is only true if the role did not already have it.

`supabase/maintenance/` still holds inventory scripts written for the old project.
They have not been re-verified against the new one and one of them carries a stale
keep-list, so treat them as historical rather than as tools.

## Verifying

`supabase/tests/rls_test.py` drives the REST API with real user JWTs — no
service-role shortcuts except to create the test users — and asserts the negative
cases, not just the happy path:

```bash
supabase start && supabase db reset
python3 supabase/tests/rls_test.py
```

33 checks, covering: an outsider can read neither the meal nor the dish and cannot
rate it; a guest cannot rate as somebody else, nor on behalf of the cook's kid; a
rating cannot claim both sources at once; signing up claims a pending email invite
and produces exactly one notification.

Twelve of those are new, and guard the two fixes above:

- inviting an address that **already has an account** links on insert, notifies once,
  and lets that person read and rate the meal;
- inviting **your own** address notifies nobody;
- recording **your own kid's** verdict notifies nobody;
- a **guest recording their own kid's** verdict does notify the cook, and names the
  child rather than saying "Someone".

### What the self check covers

The writes that matter most are only reachable by tapping — inviting somebody, rating
a meal you were invited to, replacing and then removing a photo — and a headless
simulator has no way to tap. `DevSelfCheck` calls the same `FoodStore` methods those
buttons call and logs a result for each:

```bash
xcrun simctl launch booted se.joelsanden.nomnom \
    -dev-sign-in cook@foodlog.test -seed-sample-data -dev-selfcheck
xcrun simctl spawn booted log show --last 2m --info \
    --predicate 'subsystem == "NomNom"' --style compact
```

`--info` matters: the passes are logged at info level, which `log show` omits without
it.

17 checks: save a meal with a photo and read the photo back out of the private
bucket; invite an existing account and confirm it resolved; edit a verdict and get an
update rather than a duplicate; rate a meal you were invited to and see the invite
marked answered; mark the inbox read; remove a photo and confirm both the column and
the storage object are cleared; delete the meal.

It covers the store and its round trip through PostgREST and Storage. It says
nothing about whether the buttons are wired to those methods.

Two of those assertions had to be written carefully, and the reason is worth
knowing if you extend them. Asking `PhotoCache` whether a deleted photo is gone
races the live list behind the screen, which renders the new meal and re-populates
the cache. Asking Storage for it with a GET is answered out of `URLSession`'s
`URLCache` from the earlier successful fetch. Only `list` — a POST, so uncached —
actually reports the bucket's state.

## What is and isn't verified

Verified end-to-end against the local stack, through the app:

- the email-code sign-in, including account creation on first use;
- all four tabs rendering real data pulled over PostgREST;
- writes: 10 dishes, 21 meals, 42 verdicts and 9 photos created by app code, checked
  in Postgres afterwards;
- photo upload, authenticated download, and removal from the bucket;
- reading another account's meal through RLS, and the invite that grants it.

Not verified: that tapping each control invokes the right method. There is no
XCUITest target, and driving the simulator's UI needs an accessibility permission
this environment does not have, so the buttons were checked by reading the code and
by screenshotting each tab, not by pressing them.

## Push notifications

Supabase does not deliver APNs push itself. It provides Database Webhooks, Edge
Functions and Realtime; delivery is your call to make. `notify-invitees` signs an
ES256 APNs JWT and posts to Apple directly, dropping dead tokens on a 410.

It reads `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID` and `APNS_PRIVATE_KEY`, and
returns `{"skipped":"apns-not-configured"}` if any is missing — a no-op rather than an
error, so the webhook doesn't retry and the in-app inbox works on its own.

The Developer Program membership needed for the APNs key now exists (team
`D4F66LSYSF`), so this is unblocked. What is missing is the key itself, the secrets,
and the entire client half: the app has no entitlement, no Push Notifications
capability, no registration call, and nothing writing to `device_tokens`. Note that
push cannot be tested in the simulator — `simctl push` fakes a payload but exercises
neither APNs nor the function.

## Status

**The database is rebuilt but not yet deployed.** The nine original migrations are
squashed into `20260827000000_baseline.sql`, which applies clean from scratch and
passes all 33 RLS checks locally. It has not been pushed anywhere.

The app points at a **new** Supabase project, `bctbqsrsmkyputxyiyzh`, created to
replace the one shared with an earlier project — see
[why](#why-the-project-was-replaced). That project is currently empty: no schema, no
Edge Functions, no email configuration.

Done: the iOS client. `supabase-swift` 2.55.1 through SPM, the SwiftData layer gone,
and auth, all four tabs, the inbox and the invite/rating flow running against
Postgres locally. Hot reload and a local sign-in shortcut for development.

Outstanding, roughly in order — tracked as
[issue #1](https://github.com/simpel/nom-nom/issues/1) and its children:

1. Rotate the API keys leaked by the old project's Edge Function, and retire it.
2. Push the baseline to the new project.
3. Custom SMTP via Resend, and the auth email templates —
   [which must carry `{{ .Token }}`](#one-manual-step-for-the-hosted-project), or
   sign-in cannot be completed at all.
4. Deploy `notify-invitees` and `delete-account`, and wire the webhook.
5. Verify hosted sign-in with a real emailed code, for two different people.
6. Drive a **Release** build against hosted end to end. It has no sign-in shortcut —
   `DevSignIn` compiles out entirely — so this exercises the real thing.
7. Push notifications, both halves.
