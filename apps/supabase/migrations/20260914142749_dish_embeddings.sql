create extension if not exists vector;

alter table public.dishes
add column embedding vector(1536);

-- For small-medium tables, HNSW is better than IVFFLAT, or we can just leave it unindexed if it's small, but let's add HNSW
create index on public.dishes using hnsw (embedding vector_cosine_ops);

create or replace function match_dishes(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  name text,
  cuisine text,
  similarity float
)
language sql stable
as $$
  select
    dishes.id,
    dishes.name,
    dishes.cuisine,
    1 - (dishes.embedding <=> query_embedding) as similarity
  from dishes
  where dishes.embedding is not null
    and 1 - (dishes.embedding <=> query_embedding) > match_threshold
  order by dishes.embedding <=> query_embedding
  limit match_count;
$$;
