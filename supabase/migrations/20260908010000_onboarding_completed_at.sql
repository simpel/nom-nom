-- Explicit onboarding-completion state, instead of inferring it from
-- first_name being non-blank. Nullable: null means onboarding is not done.
alter table public.profiles
    add column if not exists onboarding_completed_at timestamptz;

-- Backfill existing accounts that already have a name on file — they went
-- through onboarding under the old (first_name-based) scheme and should not
-- be sent back through it now that the gate reads this column instead.
update public.profiles
set onboarding_completed_at = now()
where onboarding_completed_at is null
  and trim(first_name) <> '';
