-- 20261005150000_suggest_parties.sql
-- "Suggested parties": public dinner parties ranked by embedding similarity to the
-- parties the caller belongs to. A party's vector is the average of the embeddings of
-- the dishes it has eaten (meal_parties -> meals -> dishes.embedding).
--
-- security definer: the dishes of a public party belong to other people, so the
-- caller cannot read their embeddings under RLS. Only ids, a score and a cuisine
-- name leave the function.

create or replace function public.suggest_parties(
    p_limit  int default 10,
    p_offset int default 0
)
returns table (
    party_id         uuid,
    similar_party_id uuid,
    similarity       float,
    shared_cuisine   text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with my_parties as (
        select pm.party_id as id from public.party_members pm where pm.user_id = auth.uid()
        union
        select p.id from public.parties p where p.created_by = auth.uid()
    ),
    followed as (
        select pf.party_id as id from public.party_followers pf where pf.user_id = auth.uid()
    ),
    centroids as materialized (
        select mp.party_id, avg(d.embedding) as v
        from public.meal_parties mp
        join public.meals  m on m.id = mp.meal_id
        join public.dishes d on d.id = m.dish_id
        where d.embedding is not null
        group by mp.party_id
    ),
    scored as (
        select p.id as party_id, p.created_at, best.similar_party_id, best.similarity
        from public.parties p
        left join centroids c on c.party_id = p.id
        left join lateral (
            -- the closest of the caller's own parties
            select mine.party_id as similar_party_id,
                   1 - (c.v <=> mine.v) as similarity
            from centroids mine
            where mine.party_id in (select id from my_parties)
            order by c.v <=> mine.v
            limit 1
        ) best on c.party_id is not null
        where p.is_public = true
          and p.id not in (select id from my_parties)
          and p.id not in (select id from followed)
    )
    select s.party_id,
           s.similar_party_id,
           s.similarity,
           (
               -- the cuisine the candidate cooks most that the matched party cooks too
               select d.cuisine
               from public.meal_parties mp
               join public.meals  m on m.id = mp.meal_id
               join public.dishes d on d.id = m.dish_id
               where mp.party_id = s.party_id
                 and s.similar_party_id is not null
                 and d.cuisine is not null
                 and d.cuisine in (
                     select d2.cuisine
                     from public.meal_parties mp2
                     join public.meals  m2 on m2.id = mp2.meal_id
                     join public.dishes d2 on d2.id = m2.dish_id
                     where mp2.party_id = s.similar_party_id and d2.cuisine is not null
                 )
               group by d.cuisine
               order by count(*) desc, d.cuisine
               limit 1
           ) as shared_cuisine
    from scored s
    -- unscorable parties (no embedded meals yet, or the caller has none) come last, newest first
    order by s.similarity desc nulls last, s.created_at desc, s.party_id
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0);
$$;

revoke all on function public.suggest_parties(int, int) from public, anon;
grant execute on function public.suggest_parties(int, int) to authenticated;
