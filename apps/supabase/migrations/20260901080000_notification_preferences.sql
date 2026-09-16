-- ===========================================================================
-- Add notification and email delivery preferences to public.profiles
-- ===========================================================================

alter table public.profiles
    add column if not exists notify_push_party_invite boolean not null default true,
    add column if not exists notify_email_party_invite boolean not null default true,
    add column if not exists notify_push_meal_invite boolean not null default true,
    add column if not exists notify_email_meal_invite boolean not null default true;
