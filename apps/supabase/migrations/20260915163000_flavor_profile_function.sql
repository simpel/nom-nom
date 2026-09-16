-- Shared flavor-profile aggregation for both an individual profile and a dinner
-- party, so neither the iOS app nor the web app computes this stat itself — they
-- just call this function and render the result.
--
-- p_scope = 'party': dish score = average of every meal_ratings reaction recorded
--   for that dish's meals within the party (party consensus).
-- p_scope = 'person': dish score = that person's own reaction only (rater_id or
--   eater_id, whichever the row uses — see meal_ratings.one_rating_source).
--
-- Reaction -> 0..1 normalization matches the mapping already used by the admin
-- party dashboard (apps/web .../admin/parties/[id]/page.tsx normalizeScore) so the
-- numbers mean the same thing everywhere.
create or replace function public.get_flavor_profile(p_scope text, p_id uuid)
returns table (
    canonical_ingredient_id uuid,
    canonical_name          text,
    category                text,
    sample_size             int,
    loved_pct               int,
    polarization            int,
    sentiment               text
)
language sql
stable
as $$
    with target_scores as (
        select m.dish_id,
               avg(case mr.reaction
                       when -1 then 0.0 when 1 then 0.2 when 2 then 0.4
                       when 3 then 0.6 when 4 then 0.8 when 5 then 1.0
                       else 0.6 end) as score
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        join public.meal_ratings mr on mr.meal_id = m.id
        where p_scope = 'party' and mp.party_id = p_id
        group by m.dish_id

        union all

        select m.dish_id,
               avg(case mr.reaction
                       when -1 then 0.0 when 1 then 0.2 when 2 then 0.4
                       when 3 then 0.6 when 4 then 0.8 when 5 then 1.0
                       else 0.6 end) as score
        from public.meal_ratings mr
        join public.meals m on m.id = mr.meal_id
        where p_scope = 'person' and coalesce(mr.rater_id, mr.eater_id) = p_id
        group by m.dish_id
    ),
    ingredient_scores as (
        select dic.canonical_ingredient_id, ts.score
        from public.dish_ingredients_canonical dic
        join target_scores ts on ts.dish_id = dic.dish_id
    )
    select
        iv.id as canonical_ingredient_id,
        iv.canonical_name,
        iv.category,
        count(*)::int as sample_size,
        round((avg(is_.score) * 100)::numeric)::int as loved_pct,
        round((coalesce(stddev_pop(is_.score), 0) * 100)::numeric)::int as polarization,
        case
            when count(*) < 2 then 'insufficient'
            when coalesce(stddev_pop(is_.score), 0) > 0.25 then 'polarizing'
            when avg(is_.score) >= 0.7 then 'loved'
            when avg(is_.score) <= 0.35 then 'disliked'
            else 'mixed'
        end as sentiment
    from ingredient_scores is_
    join public.ingredient_vocabulary iv on iv.id = is_.canonical_ingredient_id
    group by iv.id, iv.canonical_name, iv.category
    having count(*) >= 2
    order by loved_pct desc;
$$;
