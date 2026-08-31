-- ===========================================================================
-- Fan `public.notifications` inserts out to the notify-invitees Edge Function.
--
-- This is what the Supabase dashboard calls a "Database Webhook". A webhook is
-- nothing but a trigger calling `supabase_functions.http_request` over pg_net,
-- so it can be written here instead — and it should be, for two reasons the
-- dashboard route gets wrong:
--
--   1. The dashboard bakes the auth header into the trigger definition as a
--      string literal. `db pull` then lifts it into a migration in plaintext,
--      which is how people commit their service role key without noticing.
--   2. It bakes the URL in too, so a local `db reset` reproduces a trigger
--      aimed at the hosted project.
--
-- Both are fixed the same way: read the URL and the secret out of Vault at call
-- time, so this file holds neither, and each environment answers for itself.
-- That means `db push` alone does NOT finish the job — the two Vault rows are
-- separate setup, seeded locally by `supabase/seed.sql` and created once by
-- hand on hosted. See the deploy runbook.
--
-- The function authenticates on `x-webhook-secret`, which it checks itself, and
-- is deployed `verify_jwt = false` so the platform lets an unsigned webhook
-- through to that check. Note this sidesteps a live trap: the app is on the new
-- `sb_publishable_…` keys, and those are rejected on `Authorization: Bearer` —
-- a function that carries its own shared secret never has to care.
-- ===========================================================================

-- Async, so a slow or dead Edge Function cannot hold open the transaction that
-- inserted the notification. The `http` extension would block; pg_net queues.
create extension if not exists pg_net with schema extensions;

create function public.notify_push_on_notification()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    fn_url text;
    secret text;
begin
    select decrypted_secret into fn_url
      from vault.decrypted_secrets
     where name = 'project_url';

    select decrypted_secret into secret
      from vault.decrypted_secrets
     where name = 'webhook_secret';

    -- Absent Vault rows mean "this environment does not do push". Stay quiet
    -- rather than erroring: the in-app inbox is fed by the row that was just
    -- inserted and works without any of this. A raise here would roll back the
    -- insert and break the inbox to protect a notification nobody can receive.
    if fn_url is null or secret is null then
        return new;
    end if;

    -- Shaped to match what a dashboard webhook would have sent, because that is
    -- what `notify-invitees` parses: it checks `type` and `table` before doing
    -- anything, and reads the row out of `record`.
    perform net.http_post(
        url     := fn_url || '/functions/v1/notify-invitees',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      'INSERT',
                       'table',     'notifications',
                       'schema',    'public',
                       'record',    to_jsonb(new),
                       'old_record', null
                   ),
        timeout_milliseconds := 5000
    );

    return new;
end;
$$;

-- AFTER INSERT: the row must be committed and visible before anything is told
-- about it. Both writers of this table are themselves SECURITY DEFINER triggers
-- (notify_invitee, notify_rating), so this fires downstream of those.
create trigger notifications_push_fanout
    after insert on public.notifications
    for each row
    execute function public.notify_push_on_notification();

-- `anon` is locked out of everything in the baseline's final section, and this
-- function is created after it. EXECUTE on a new function defaults to PUBLIC,
-- which anon belongs to — but the baseline's `alter default privileges … revoke
-- all on routines from anon` covers routines created later by this role, so
-- there is nothing to revoke here. It is a trigger function regardless: calling
-- it directly outside a trigger context errors.
