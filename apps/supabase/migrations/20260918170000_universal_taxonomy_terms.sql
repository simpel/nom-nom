-- ===========================================================================
-- Universal Taxonomy Terms: unified table for culinary dimensions
-- (dish_kind, cooking_method, cuisine, etc.) with semantic embedding matching
-- ===========================================================================

create table if not exists public.taxonomy_terms (
    id             uuid primary key default gen_random_uuid(),
    dimension      text        not null check (length(btrim(dimension)) > 0),
    slug           text        not null check (length(btrim(slug)) > 0),
    name           text        not null check (length(btrim(name)) > 0),
    aliases        text[]      not null default '{}',
    embedding      vector(1536),
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now(),
    unique (dimension, slug)
);

create index if not exists taxonomy_terms_dimension_slug_idx on public.taxonomy_terms (dimension, slug);
create index if not exists taxonomy_terms_embedding_hnsw_idx on public.taxonomy_terms using hnsw (embedding vector_cosine_ops);

-- RLS
alter table public.taxonomy_terms enable row level security;

drop policy if exists taxonomy_terms_select on public.taxonomy_terms;
create policy taxonomy_terms_select on public.taxonomy_terms
    for select using (true);

drop policy if exists taxonomy_terms_insert on public.taxonomy_terms;
create policy taxonomy_terms_insert on public.taxonomy_terms
    for insert to authenticated
    with check (true);

drop policy if exists taxonomy_terms_update on public.taxonomy_terms;
create policy taxonomy_terms_update on public.taxonomy_terms
    for update to authenticated
    using (true);

-- Match existing taxonomy terms by semantic vector similarity
create or replace function public.match_taxonomy_terms(
    p_dimension       text,
    p_embedding       vector(1536),
    p_match_threshold float,
    p_match_count     int default 1
)
returns table (
    id             uuid,
    dimension      text,
    slug           text,
    name           text,
    similarity     float
)
language sql
stable
as $$
    select
        t.id,
        t.dimension,
        t.slug,
        t.name,
        1 - (t.embedding <=> p_embedding) as similarity
    from public.taxonomy_terms t
    where t.dimension = p_dimension
      and t.embedding is not null
      and 1 - (t.embedding <=> p_embedding) > p_match_threshold
    order by t.embedding <=> p_embedding
    limit p_match_count;
$$;

-- Record a newly seen synonym or alias against an existing taxonomy term
create or replace function public.append_taxonomy_term_alias(p_id uuid, p_alias text)
returns void
language sql
as $$
    update public.taxonomy_terms
    set aliases = case
        when p_alias = any(aliases) then aliases
        else aliases || p_alias
    end,
    updated_at = now()
    where id = p_id;
$$;

-- Add dish_kind_id foreign key to dishes table
alter table public.dishes
    add column if not exists dish_kind_id uuid references public.taxonomy_terms (id) on delete set null;

create index if not exists dishes_dish_kind_idx on public.dishes (dish_kind_id);

-- Convenience view for dish kinds
create or replace view public.dish_kinds as
select
    id,
    slug,
    name,
    aliases,
    created_at,
    updated_at
from public.taxonomy_terms
where dimension = 'dish_kind';

-- Seed initial canonical dish kinds (dynamic taxonomy will add more via AI)
insert into public.taxonomy_terms (id, dimension, slug, name, aliases)
values
    ('a0000000-0000-0000-0000-000000000001', 'dish_kind', 'pizza', 'Pizza', array['pizzas', 'calzone']),
    ('a0000000-0000-0000-0000-000000000002', 'dish_kind', 'pasta', 'Pasta', array['spaghetti', 'noodles', 'tagliatelle', 'carbonara', 'bolognese', 'ragu']),
    ('a0000000-0000-0000-0000-000000000003', 'dish_kind', 'stew', 'Stew', array['gryta', 'ragout', 'goulash', 'chili', 'bourguignon']),
    ('a0000000-0000-0000-0000-000000000004', 'dish_kind', 'casserole', 'Casserole', array['gratang', 'gratin', 'bake', 'lasagna', 'shepherd']),
    ('a0000000-0000-0000-0000-000000000005', 'dish_kind', 'soup', 'Soup', array['soppa', 'chowder', 'broth', 'ramen', 'bisque', 'tom yum']),
    ('a0000000-0000-0000-0000-000000000006', 'dish_kind', 'bbq', 'BBQ & Grill', array['grilling', 'barbecue', 'smoked', 'grill', 'grillat', 'ribs', 'pulled pork']),
    ('a0000000-0000-0000-0000-000000000007', 'dish_kind', 'curry', 'Curry', array['tikka', 'korma', 'masala']),
    ('a0000000-0000-0000-0000-000000000008', 'dish_kind', 'salad', 'Salad', array['sallad', 'slaw', 'caesar']),
    ('a0000000-0000-0000-0000-000000000009', 'dish_kind', 'roast', 'Roast', array['stek', 'roast chicken', 'roast beef']),
    ('a0000000-0000-0000-0000-000000000010', 'dish_kind', 'tacos', 'Tacos & Wraps', array['taco', 'burrito', 'wrap', 'quesadilla', 'fajitas', 'carnitas', 'enchiladas', 'enchilada']),
    ('a0000000-0000-0000-0000-000000000011', 'dish_kind', 'burger', 'Burger & Sandwich', array['burgers', 'sandwich', 'sliders', 'toast']),
    ('a0000000-0000-0000-0000-000000000012', 'dish_kind', 'stir_fry', 'Stir-Fry', array['wok', 'pad thai', 'fried rice', 'kung pao']),
    ('a0000000-0000-0000-0000-000000000013', 'dish_kind', 'pie', 'Pie & Tart', array['paj', 'quiche', 'tart']),
    ('a0000000-0000-0000-0000-000000000014', 'dish_kind', 'seafood', 'Seafood', array['fish', 'salmon', 'mussels', 'fisk', 'gambas']),
    ('a0000000-0000-0000-0000-000000000015', 'dish_kind', 'risotto', 'Risotto', array['arborio']),
    ('a0000000-0000-0000-0000-000000000016', 'dish_kind', 'bowl', 'Bowl', array['bowls', 'grain bowl', 'poke bowl', 'tinga']),
    ('a0000000-0000-0000-0000-000000000017', 'dish_kind', 'dumplings', 'Dumplings', array['dumpling', 'gyoza', 'potstickers']),
    ('a0000000-0000-0000-0000-000000000018', 'dish_kind', 'breakfast_brunch', 'Breakfast & Brunch', array['shakshuka', 'brunch', 'eggs', 'pancakes']),
    ('a0000000-0000-0000-0000-000000000019', 'dish_kind', 'appetizer', 'Appetizer & Mezze', array['guacamole', 'mezze', 'dip', 'hummus', 'snack', 'pico']),
    ('a0000000-0000-0000-0000-000000000020', 'dish_kind', 'meatballs', 'Meatballs & Patties', array['meatballs', 'köttbullar'])
on conflict (dimension, slug) do nothing;

-- Backfill existing dishes based on tags, name, and normalized_name
update public.dishes d
set dish_kind_id = tk.id
from public.taxonomy_terms tk
where tk.dimension = 'dish_kind'
  and d.dish_kind_id is null
  and (
    tk.slug = any(d.tags)
    or exists (select 1 from unnest(tk.aliases) a where a = any(d.tags))
    or d.normalized_name ilike '%' || tk.slug || '%'
    or exists (select 1 from unnest(tk.aliases) a where d.normalized_name ilike '%' || a || '%')
    or d.name ilike '%' || tk.name || '%'
    or exists (select 1 from unnest(tk.aliases) a where d.name ilike '%' || a || '%')
  );
