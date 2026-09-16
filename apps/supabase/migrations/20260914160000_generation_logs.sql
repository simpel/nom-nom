-- 20260914160000_generation_logs.sql

create type public.generation_type as enum (
  'party_insight',
  'member_match',
  'recipe_health',
  'dish_photo',
  'recipe_parse'
);

create table public.generation_logs (
    id uuid primary key default gen_random_uuid(),
    generation_type public.generation_type not null,
    entity_id uuid not null,
    target_id uuid, -- Optional (e.g. for member match where entity is party_id and target is profile_id)
    prompt text,
    response text,
    status text not null, -- 'success', 'error', 'running'
    error_message text,
    model_used text,
    duration_ms integer,
    created_at timestamptz not null default now()
);

alter table public.generation_logs enable row level security;

-- Only admins/authenticated users should select logs
create policy generation_logs_select on public.generation_logs
    for select to authenticated using (true);

-- System can insert/update via service role key, bypassing RLS
