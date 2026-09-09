# Apple signing keys

Local-only. Nothing in this directory except this file is tracked (see `.gitignore`).

Nom Nom uses **two** Apple `.p8` keys, deliberately kept separate so a leak of
one never forces rotation of the other:

| Path | Apple key capability | Key ID | Used by |
|------|----------------------|--------|---------|
| `keys/signinwithapple/AuthKey_D722M2ZZ9T.p8` | Sign in with Apple | `D722M2ZZ9T` | `scripts/generate_apple_client_secret.js` → Supabase Auth "Secret Key" |
| `keys/notifications/AuthKey_B9NMV9DA2H.p8` | Apple Push Notifications service | `B9NMV9DA2H` | `supabase/functions/notify-invitees` via secret `APNS_PRIVATE_KEY` |

Keys are created at <https://developer.apple.com/account/resources/authkeys/list>.
Apple only lets you download a key once — if you lose it, revoke and reissue.

The old combined key `6FLDB732GY` was committed to git and is compromised.
It must stay revoked.

Setup runbook: [`docs/SETUP_APPLE_KEYS.md`](../docs/SETUP_APPLE_KEYS.md).
How the push pipeline works: [`docs/PUSH_NOTIFICATIONS.md`](../docs/PUSH_NOTIFICATIONS.md).
