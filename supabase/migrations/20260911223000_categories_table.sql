-- ===========================================================================
-- Categories Table & Preset Cuisines
-- ===========================================================================

create table if not exists public.categories (
    id uuid primary key default gen_random_uuid(),
    slug text not null unique,
    name text not null,
    photo_path text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists categories_slug_idx on public.categories (slug);

-- RLS
alter table public.categories enable row level security;

-- Readable by anyone authenticated or anonymous
drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
    for select using (true);

-- Insertable by authenticated users
drop policy if exists categories_insert on public.categories;
create policy categories_insert on public.categories
    for insert to authenticated
    with check (true);

-- Updatable by authenticated users
drop policy if exists categories_update on public.categories;
create policy categories_update on public.categories
    for update to authenticated
    using (true);

-- Seed initial 14 preset cuisines
insert into public.categories (slug, name)
values
    ('american', 'American'),
    ('asian', 'Asian'),
    ('french', 'French'),
    ('greek', 'Greek'),
    ('indian', 'Indian'),
    ('italian', 'Italian'),
    ('japanese', 'Japanese'),
    ('korean', 'Korean'),
    ('mediterranean', 'Mediterranean'),
    ('mexican', 'Mexican'),
    ('middle_eastern', 'Middle Eastern'),
    ('nordic', 'Nordic'),
    ('spanish', 'Spanish'),
    ('thai', 'Thai')
on conflict (slug) do update set
    name = excluded.name;
