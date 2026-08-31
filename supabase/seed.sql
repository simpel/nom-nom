-- Seeded into the local stack after every `supabase db reset`
-- (`[db.seed]` in config.toml points at this file).
--
-- Its whole job is the local half of the notifications webhook. The trigger in
-- 20260827140000_notifications_webhook.sql reads both of these out of Vault and
-- stays silent if either is missing, so this file is what makes the fan-out
-- actually fire locally — and it is why the same migration can run against
-- local and hosted without either one aiming at the other.
--
-- Nothing secret lives here. `webhook_secret` is a fixed local development
-- value, deliberately not the hosted one, which is set as a Supabase secret and
-- as a Vault row on the hosted project by hand.

-- Reached from inside the Postgres container, so not localhost and not
-- 127.0.0.1 — those resolve to the database container itself. This is the
-- local API gateway under the name the stack's own network knows it by.
select vault.create_secret(
    'http://api.supabase.internal:8000',
    'project_url',
    'Base URL this environment reaches its own Edge Functions on.'
);

select vault.create_secret(
    'local-development-webhook-secret',
    'webhook_secret',
    'Shared secret sent as x-webhook-secret; must match the WEBHOOK_SECRET the Edge Function holds.'
);
