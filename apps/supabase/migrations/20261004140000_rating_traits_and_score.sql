-- One score per rating, from every answer the eater gave.
--
-- 1. Traits: a fixed vocabulary that says what a dish kind or cooking method is like
--    (crust, saucy, raw, ...). Tags bind to traits, never to a dish kind, so a term the
--    taxonomy resolver creates later only needs its traits to get fitting tags.
-- 2. rating_tags: the "what stood out" catalogue as data. Each tag says which verdicts
--    offer it, which trait a dish needs for it to make sense, and whether it is good or
--    a problem.
-- 3. meal_ratings.score (0..1), set by a trigger:
--      verdict   Can't eat 0 · Bad .20 · Meh .40 · Good .60 · Great .80 · Amazing 1
--      again     Not again −.05 · Sometime 0 · Soon +.05
--      plate     A few bites −.03 · Half −.015 · Cleared +.015 · Had seconds +.03
--      stood out .02 × (good − problem) ÷ scored tags
--    A skipped answer adds 0. Can't eat is always 0; every other verdict floors at .15
--    so only Can't eat reads "Can't eat". Clamped to 1.
-- 4. Every server-side consumer reads score instead of mapping the verdict itself.

-- 1. Traits -------------------------------------------------------------------------

alter table public.taxonomy_terms
    add column rating_traits text[] not null default '{}',
    add constraint taxonomy_terms_rating_traits_known check (rating_traits <@ array[
        'crust', 'saucy', 'raw', 'meat_fish', 'starch', 'smoky'
    ]::text[]);

update public.taxonomy_terms t
set rating_traits = s.traits
from (values
    ('dish_kind', 'pizza', array['crust']),
    ('dish_kind', 'pasta', array['starch', 'saucy']),
    ('dish_kind', 'stew', array['saucy']),
    ('dish_kind', 'casserole', array['saucy']),
    ('dish_kind', 'soup', array['saucy']),
    ('dish_kind', 'bbq', array['meat_fish', 'smoky']),
    ('dish_kind', 'curry', array['saucy']),
    ('dish_kind', 'salad', array['raw']),
    ('dish_kind', 'roast', array['meat_fish']),
    ('dish_kind', 'tacos', array['crust']),
    ('dish_kind', 'burger', array['crust', 'meat_fish']),
    ('dish_kind', 'stir_fry', array['starch']),
    ('dish_kind', 'pie', array['crust']),
    ('dish_kind', 'seafood', array['meat_fish']),
    ('dish_kind', 'risotto', array['starch', 'saucy']),
    ('dish_kind', 'bowl', array['starch']),
    ('dish_kind', 'dumplings', array['crust', 'starch']),
    ('dish_kind', 'meatballs', array['meat_fish']),
    ('cooking_method', 'baking', array['crust']),
    ('cooking_method', 'grilling', array['crust', 'smoky']),
    ('cooking_method', 'roasting', array['crust']),
    ('cooking_method', 'frying', array['crust']),
    ('cooking_method', 'slow_cooking', array['saucy']),
    ('cooking_method', 'simmering', array['saucy']),
    ('cooking_method', 'raw_cured', array['raw']),
    ('cooking_method', 'smoking', array['smoky'])
) as s (dimension, slug, traits)
where t.dimension = s.dimension and t.slug = s.slug;

insert into public.ai_feature_configs (feature_id, model_name) values
    ('taxonomy-traits', 'google/gemini-2.5-flash')
on conflict (feature_id) do nothing;

-- 2. Tag catalogue ------------------------------------------------------------------

create table public.rating_tags (
    id          text     primary key,
    label       text     not null,
    is_positive boolean  not null,
    -- false for Can't-eat reasons: they explain, they never move a score
    scored      boolean  not null default true,
    -- verdicts (reaction values) that offer this tag
    verdicts    smallint[] not null,
    -- null: any dish. 'cooked': any dish without the raw trait. Else a trait the
    -- dish's kind or cooking method must carry.
    trait       text     check (trait in ('cooked', 'crust', 'saucy', 'raw', 'meat_fish', 'starch', 'smoky')),
    tag_group   text     not null check (tag_group in ('flavour', 'texture', 'cooking', 'feel', 'why')),
    sort        smallint not null
);

alter table public.rating_tags enable row level security;

create policy rating_tags_select on public.rating_tags
    for select to authenticated using (true);

-- reaction: −1 Can't eat · 1 Bad · 2 Meh · 3 Good · 4 Great · 5 Amazing
insert into public.rating_tags (id, label, is_positive, scored, verdicts, trait, tag_group, sort) values
    ('perfectlySeasoned', 'Perfectly seasoned', true,  true, '{5,4}',   null,        'flavour', 10),
    ('bestYet',           'Best one yet',       true,  true, '{5}',     null,        'feel',    11),
    ('tasty',             'Tasty',              true,  true, '{4,3}',   null,        'flavour', 12),
    ('comforting',        'Comforting',         true,  true, '{5,4,3}', null,        'feel',    13),
    ('fresh',             'Fresh',              true,  true, '{5,4,3}', null,        'feel',    14),
    ('solidWeeknight',    'Solid weeknight',    true,  true, '{3}',     null,        'feel',    15),
    ('niceIdea',          'Nice idea',          true,  true, '{2}',     null,        'feel',    16),
    ('needsTweak',        'Needs one tweak',    false, true, '{4,3}',   null,        'feel',    20),
    ('neededSalt',        'Needed salt',        false, true, '{3,2}',   null,        'flavour', 21),
    ('tooSalty',          'Too salty',          false, true, '{3,2,1}', null,        'flavour', 22),
    ('tooSpicy',          'Too spicy',          false, true, '{3,2,1}', null,        'flavour', 23),
    ('bland',             'Bland',              false, true, '{2,1}',   null,        'flavour', 24),
    ('tooHeavy',          'Too heavy',          false, true, '{3,2,1}', null,        'feel',    25),
    ('forgettable',       'Forgettable',        false, true, '{2}',     null,        'feel',    26),
    ('notMyThing',        'Not my thing',       false, true, '{2,1}',   null,        'feel',    27),
    ('cookedRight',       'Cooked just right',  true,  true, '{5,4,3}', 'cooked',    'cooking', 30),
    ('overcooked',        'Overcooked',         false, true, '{3,2,1}', 'cooked',    'cooking', 31),
    ('undercooked',       'Undercooked',        false, true, '{2,1}',   'cooked',    'cooking', 32),
    ('burnt',             'Burnt',              false, true, '{1}',     'cooked',    'cooking', 33),
    ('crispy',            'Crispy',             true,  true, '{5,4,3}', 'crust',     'texture', 40),
    ('soggy',             'Soggy',              false, true, '{3,2,1}', 'crust',     'texture', 41),
    ('juicy',             'Juicy',              true,  true, '{5,4,3}', 'meat_fish', 'texture', 42),
    ('tender',            'Tender',             true,  true, '{5,4,3}', 'meat_fish', 'texture', 43),
    ('dry',               'Dry',                false, true, '{3,2,1}', 'meat_fish', 'texture', 44),
    ('tough',             'Tough',              false, true, '{2,1}',   'meat_fish', 'texture', 45),
    ('richSauce',         'Rich sauce',         true,  true, '{5,4,3}', 'saucy',     'flavour', 46),
    ('watery',            'Watery',             false, true, '{3,2,1}', 'saucy',     'texture', 47),
    ('perfectBite',       'Perfect bite',       true,  true, '{5,4,3}', 'starch',    'texture', 48),
    ('mushy',             'Mushy',              false, true, '{3,2,1}', 'starch',    'texture', 49),
    ('crunchy',           'Crunchy',            true,  true, '{5,4,3}', 'raw',       'texture', 50),
    ('wellDressed',       'Well dressed',       true,  true, '{5,4}',   'raw',       'flavour', 51),
    ('wilted',            'Wilted',             false, true, '{3,2,1}', 'raw',       'texture', 52),
    ('overdressed',       'Overdressed',        false, true, '{2,1}',   'raw',       'flavour', 53),
    ('smoky',             'Smoky',              true,  true, '{5,4,3}', 'smoky',     'flavour', 54),
    ('allergy',           'Allergy',            false, false, '{-1}',   null,        'why',     60),
    ('notMyDiet',         'Doesn''t fit my diet', false, false, '{-1}', null,        'why',     61),
    ('tooSpicyForMe',     'Too spicy for me',   false, false, '{-1}',   null,        'why',     62),
    ('disagrees',         'Doesn''t agree with me', false, false, '{-1}', null,      'why',     63),
    ('notCookedThrough',  'Not cooked through', false, false, '{-1}',   null,        'why',     64);

-- 3. The score ----------------------------------------------------------------------

-- No backwards compatibility yet: the old tag ids go.
update public.meal_ratings set tags = '{}';
alter table public.meal_ratings drop constraint meal_ratings_tags_known;

create function public.meal_rating_score(
    p_reaction smallint,
    p_tags     text[],
    p_plate    smallint,
    p_again    smallint
)
    returns numeric
    language sql
    stable
    set search_path = public, pg_temp
as $$
    with t as (
        select count(*) filter (where rt.is_positive)     as good,
               count(*) filter (where not rt.is_positive) as problem
        from public.rating_tags rt
        where rt.scored and rt.id = any (coalesce(p_tags, '{}'))
    )
    select case
        when p_reaction < 0 then 0
        else least(1, greatest(0.15,
            case p_reaction when 5 then 1.0 when 4 then 0.8 when 3 then 0.6
                            when 2 then 0.4 else 0.2 end
            + case p_again when 2 then 0.05 when 0 then -0.05 else 0 end
            + case p_plate when 3 then 0.03 when 2 then 0.015
                           when 1 then -0.015 when 0 then -0.03 else 0 end
            + case when t.good + t.problem = 0 then 0
                   else 0.02 * (t.good - t.problem)::numeric / (t.good + t.problem) end
        ))
    end
    from t;
$$;

alter table public.meal_ratings add column score numeric(4, 3) not null default 0;

create function public.meal_ratings_set_score()
    returns trigger
    language plpgsql
    set search_path = public, pg_temp
as $$
begin
    if exists (
        select 1 from unnest(new.tags) as t (id)
        where not exists (select 1 from public.rating_tags rt where rt.id = t.id)
    ) then
        raise exception 'unknown rating tag in %', new.tags using errcode = '23514';
    end if;
    new.score := public.meal_rating_score(new.reaction, new.tags, new.plate, new.again);
    return new;
end;
$$;

create trigger meal_ratings_set_score
    before insert or update of reaction, tags, plate, again on public.meal_ratings
    for each row execute function public.meal_ratings_set_score();

update public.meal_ratings
set score = public.meal_rating_score(reaction, tags, plate, again);

-- 4. Consumers read score -----------------------------------------------------------

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
        select m.dish_id, avg(mr.score) as score
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        join public.meal_ratings mr on mr.meal_id = m.id
        where p_scope = 'party' and mp.party_id = p_id
        group by m.dish_id

        union all

        select m.dish_id, avg(mr.score) as score
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

-- Liked = scored Good or better (>= .50, where the verdict word turns Good).
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
          and mr.score >= 0.5
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

-- Liked: a meal averaging Good or better (>= .50). Disliked: Bad or worse (< .30).
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
        select pm.dish_id, avg(mr.score) as score
        from party_meals pm
        join public.meal_ratings mr on mr.meal_id = pm.meal_id
        group by pm.dish_id, pm.meal_id
    ),
    liked as (
        select avg(d.embedding) as v
        from meal_avg ma join public.dishes d on d.id = ma.dish_id
        where ma.score >= 0.5 and d.embedding is not null
    ),
    disliked as (
        select avg(d.embedding) as v
        from meal_avg ma join public.dishes d on d.id = ma.dish_id
        where ma.score < 0.3 and d.embedding is not null
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
