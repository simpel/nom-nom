create table if not exists public.ai_feature_configs (
    feature_id text primary key,
    model_name text not null,
    updated_at timestamptz not null default now()
);

alter table public.ai_feature_configs enable row level security;

-- Only authenticated users
create policy ai_feature_configs_select on public.ai_feature_configs
    for select to authenticated using (true);

create policy ai_feature_configs_all on public.ai_feature_configs
    for all to authenticated using (true) with check (true);

-- Seed defaults
insert into public.ai_feature_configs (feature_id, model_name) values
    ('analyze-recipe-health', 'google/gemini-2.5-flash'),
    ('parse-recipe', 'google/gemini-2.5-flash'),
    ('canonicalize-ingredients', 'google/gemini-2.5-flash'),
    ('generate-dish-photo', 'openai/dall-e-3'),
    ('party-insights', 'google/gemini-2.5-flash')
on conflict (feature_id) do update set model_name = excluded.model_name;
