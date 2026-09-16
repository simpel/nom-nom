-- ===========================================================================
-- Recipe Suggestions for a Party
-- Suggests public dishes the party hasn't eaten yet, ranked by similarity to
-- the embedding of dishes the party has previously rated well (reaction >= 3).
-- ===========================================================================

create or replace function public.suggest_recipes_for_party(
    p_party_id uuid,
    p_match_count int default 5
)
returns table (
    id           uuid,
    name         text,
    cuisine      text,
    health_score integer,
    effort       smallint,
    similarity   float
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with party_taste as (
        select avg(d.embedding) as taste_embedding
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        join public.dishes d on d.id = m.dish_id
        join public.meal_ratings mr on mr.meal_id = m.id
        where mp.party_id = p_party_id
          and d.embedding is not null
          and mr.reaction >= 3
    ),
    eaten as (
        select distinct m.dish_id
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        where mp.party_id = p_party_id
    )
    select
        d.id,
        d.name,
        d.cuisine,
        d.health_score,
        d.effort,
        1 - (d.embedding <=> pt.taste_embedding) as similarity
    from public.dishes d
    cross join party_taste pt
    where pt.taste_embedding is not null
      and d.embedding is not null
      and d.is_public = true
      and d.id not in (select dish_id from eaten)
    order by d.embedding <=> pt.taste_embedding
    limit p_match_count;
$$;
