create table if not exists public.profile_insights (
    id                  uuid primary key default gen_random_uuid(),
    profile_id          uuid not null references public.profiles (id) on delete cascade unique,
    summary_sentence    text,
    food_profile        text,
    recommendations     jsonb not null default '[]'::jsonb,
    top_ingredients     jsonb,
    ways_of_cooking     jsonb,
    health_analysis     jsonb,
    updated_at          timestamptz not null default now()
);

alter table public.profile_insights enable row level security;

-- A user can read their own insight; admin tooling reads/writes via the
-- service role key, same as party_insights.
create policy profile_insights_select on public.profile_insights
    for select to authenticated using (
        profile_id = auth.uid()
    );
