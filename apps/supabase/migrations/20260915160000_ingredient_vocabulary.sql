-- Canonical ingredient vocabulary: a shared, deduplicated set of "flavor entities"
-- (e.g. "cinnamon") that ingredient text from any dish, in any language or form
-- ("kanel", "cinnamon stick", "kanelstång"), resolves to via the
-- canonicalize-ingredients edge function. Matching is done with embeddings so the
-- same entity converges to the same row even across independent LLM calls on
-- different dishes — an LLM alone can't guarantee two calls pick identical strings.
create table public.ingredient_vocabulary (
    id             uuid primary key default gen_random_uuid(),
    canonical_name text        not null unique check (length(btrim(canonical_name)) > 0),
    category       text        not null check (category in (
                       'spice', 'herb', 'protein', 'produce', 'dairy', 'grain', 'condiment', 'other'
                   )),
    -- Surface forms seen so far across all dishes/languages that resolved to this
    -- entity, e.g. ["cinnamon", "kanel", "cinnamon stick", "kanelstång"].
    aliases        text[]      not null default '{}',
    embedding      vector(1536),
    created_at     timestamptz not null default now()
);

create index on public.ingredient_vocabulary using hnsw (embedding vector_cosine_ops);

create or replace function public.match_ingredient_vocabulary(
    query_embedding vector(1536),
    match_threshold float,
    match_count int
)
returns table (
    id             uuid,
    canonical_name text,
    category       text,
    similarity     float
)
language sql stable
as $$
    select
        iv.id,
        iv.canonical_name,
        iv.category,
        1 - (iv.embedding <=> query_embedding) as similarity
    from public.ingredient_vocabulary iv
    where iv.embedding is not null
      and 1 - (iv.embedding <=> query_embedding) > match_threshold
    order by iv.embedding <=> query_embedding
    limit match_count;
$$;

-- One row per (dish, canonical ingredient) resolved from a raw ingredient line.
-- A single raw line can bundle multiple items ("onion, 4 garlic cloves, 1
-- cinnamon stick") and decompose into several rows here, all carrying the same
-- raw_text — so the uniqueness key includes canonical_ingredient_id, not just
-- raw_text. Kept as a real join table (not jsonb) so the flavor-profile
-- aggregation can GROUP BY canonical_ingredient_id directly.
create table public.dish_ingredients_canonical (
    id                     uuid primary key default gen_random_uuid(),
    dish_id                uuid        not null references public.dishes (id) on delete cascade,
    raw_text               text        not null,
    canonical_ingredient_id uuid       not null references public.ingredient_vocabulary (id) on delete cascade,
    created_at             timestamptz not null default now(),
    unique (dish_id, raw_text, canonical_ingredient_id)
);

create index on public.dish_ingredients_canonical (dish_id);
create index on public.dish_ingredients_canonical (canonical_ingredient_id);

-- Records a newly-seen surface form (e.g. "kanel") against an existing vocabulary
-- entry, without duplicating aliases already recorded.
create or replace function public.append_ingredient_alias(p_id uuid, p_alias text)
returns void
language sql
as $$
    update public.ingredient_vocabulary
    set aliases = case
        when p_alias = any(aliases) then aliases
        else aliases || p_alias
    end
    where id = p_id;
$$;
