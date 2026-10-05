-- 20261004120000_party_recommendations.sql
-- AI "Picked for <party>" recommendations: embedding candidate search, a per-party
-- cache written by the recommend-party-recipes edge function, and its log/config rows.

alter type public.generation_type add value if not exists 'party_recommendation';

insert into public.ai_feature_configs (feature_id, model_name) values
    ('party-recommendations', 'google/gemini-2.5-flash')
on conflict (feature_id) do nothing;

-- Cache: written with the service role key, read by party members.
create table if not exists public.party_recommendations (
    party_id     uuid        not null references public.parties (id) on delete cascade,
    dish_id      uuid        not null references public.dishes (id) on delete cascade,
    rank         smallint    not null,
    reason       text        not null default '',
    generated_at timestamptz not null default now(),
    primary key (party_id, dish_id)
);

create index if not exists party_recommendations_party_idx
    on public.party_recommendations (party_id, rank);

alter table public.party_recommendations enable row level security;

create policy party_recommendations_select on public.party_recommendations
    for select to authenticated using (public.is_party_member(party_id));

-- Candidates: dishes the party has not eaten, closest to what it rated well (>= 3 on
-- the -1..5 scale) and nudged away from what it rated poorly (<= 1). Service role only;
-- the edge function has already checked membership.
create or replace function public.party_recommendation_candidates(
    p_party_id uuid,
    p_user_id  uuid,
    p_limit    int default 30
)
returns table (
    id           uuid,
    name         text,
    cuisine      text,
    ingredients  jsonb,
    health_score integer,
    effort       smallint,
    similarity   float
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with party_meals as (
        select m.id as meal_id, m.dish_id
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        where mp.party_id = p_party_id
    ),
    meal_avg as (
        select pm.dish_id, avg(mr.reaction) as score
        from party_meals pm
        join public.meal_ratings mr on mr.meal_id = pm.meal_id
        group by pm.dish_id, pm.meal_id
    ),
    liked as (
        select avg(d.embedding) as v
        from meal_avg ma join public.dishes d on d.id = ma.dish_id
        where ma.score >= 3 and d.embedding is not null
    ),
    disliked as (
        select avg(d.embedding) as v
        from meal_avg ma join public.dishes d on d.id = ma.dish_id
        where ma.score <= 1 and d.embedding is not null
    )
    select d.id, d.name, d.cuisine, d.ingredients, d.health_score, d.effort,
           1 - (d.embedding <=> l.v) as similarity
    from public.dishes d
    cross join liked l
    left join disliked x on true
    where l.v is not null
      and d.embedding is not null
      and (d.is_public = true or d.owner_id = p_user_id)
      and d.id not in (select dish_id from party_meals)
    -- a quarter-weight push away from what the party rated poorly
    order by (d.embedding <=> l.v) - 0.25 * coalesce(d.embedding <=> x.v, 0)
    limit p_limit;
$$;

revoke all on function public.party_recommendation_candidates(uuid, uuid, int) from public, anon, authenticated;
grant execute on function public.party_recommendation_candidates(uuid, uuid, int) to service_role;
