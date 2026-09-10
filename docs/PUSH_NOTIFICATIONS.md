# Push notifications

How a database row becomes a banner on someone's phone. For the credential setup
that turns it on, see [docs/SETUP_APPLE_KEYS.md](SETUP_APPLE_KEYS.md).

## The pipeline

```
trigger writes public.notifications row
        │
        ├─ in-app inbox reads it directly (works with zero setup)
        │
        └─ AFTER INSERT trigger  notifications_push_fanout
                 │   reads project_url + webhook_secret from Vault;
                 │   if either is missing it returns quietly (no push, no error)
                 ▼
           pg_net POST  ->  Edge Function  notify-invitees   (verify_jwt = false)
                 │   auth: x-webhook-secret header == WEBHOOK_SECRET
                 │   1. checks profiles.notify_push_* preference for this kind
                 │   2. loads public.device_tokens for the user
                 │   3. signs an ES256 APNs JWT from APNS_PRIVATE_KEY
                 │   4. POSTs api[.sandbox].push.apple.com/3/device/<token>
                 │   5. on 410 Gone, deletes the dead token row
                 ▼
              APNs  ->  device
```

Everything above the Edge Function is built and deployed. The Edge Function is
deployed too, but returns `{"skipped":"apns-not-configured"}` until the four
`APNS_*` secrets exist.

### Where each piece lives

| Piece | File |
|-------|------|
| Tables `notifications`, `device_tokens` + RLS | `supabase/migrations/20260827000000_baseline.sql` |
| Fan-out trigger + Vault contract | `supabase/migrations/20260827140000_notifications_webhook.sql` |
| `updated_at` upkeep on tokens | `supabase/migrations/20260909000000_device_tokens_touch_updated_at.sql` |
| Preference columns | `supabase/migrations/20260901080000_notification_preferences.sql` |
| APNs sender | `supabase/functions/notify-invitees/index.ts` |
| Local Vault seed | `supabase/seed.sql` |
| iOS: permission, token capture, tap routing | `NomNom/Services/NotificationManager.swift` |
| iOS: upload / remove token | `NomNom/Services/FoodStore/FoodStore+Notifications.swift` |
| iOS: register once the store is ready | `NomNom/App/RootView.swift` |
| iOS: deep-link a tapped notification | `NomNom/App/RootTabView.swift` |
| Entitlement (Debug = development, Release = production) | `NomNom/NomNom.entitlements`, `NomNom/NomNom.Release.entitlements` |


## Turning it on

Credential setup — the two Apple keys, the Supabase secrets, the dashboard
config, and end-to-end verification — is a separate ordered runbook:
**[docs/SETUP_APPLE_KEYS.md](SETUP_APPLE_KEYS.md)**.

In short, the function stays a no-op until these Edge Function secrets exist
(`npx supabase@latest secrets list --project-ref bctbqsrsmkyputxyiyzh`):

| Secret | Value |
|--------|-------|
| `APNS_KEY_ID` | `72Z5583A35` (the APNs key in `keys/notifications/`) |
| `APNS_TEAM_ID` | `D4F66LSYSF` |
| `APNS_BUNDLE_ID` | `se.joelsanden.nomnom` |
| `APNS_PRIVATE_KEY` | contents of `keys/notifications/AuthKey_72Z5583A35.p8` |
| `WEBHOOK_SECRET` | must equal Vault `webhook_secret` on the hosted project |

The two Vault rows (`project_url`, `webhook_secret`) already exist on hosted;
`project_url` is `https://bctbqsrsmkyputxyiyzh.supabase.co` with no trailing slash.
