-- 20261012150000_rename_dish_to_recipe.sql
--
-- The domain has two things: a Recipe (a user's catalogue entry) and a Meal (one
-- occasion of eating a recipe). "Dish" was a third name for Recipe. This migration
-- removes it from the schema:
--
--   dishes                       -> recipes
--   *.dish_id                    -> *.recipe_id
--   dish_ingredients_canonical   -> recipe_ingredients_canonical
--   dish_kind / dish_kinds       -> recipe_kind / recipe_kinds
--   can_read_dish, match_dishes, embed_dish_on_change,
--   sync_dish_cuisines_to_categories -> the same with "recipe"
--   generation_type dish_photo/dish_embed -> recipe_photo/recipe_embed (+ meal_photo)
--   edge functions embed-dish -> embed-recipe; generate-dish-photo -> generate-recipe-photo
--     (recipes, categories) and generate-meal-photo (meals)
--
-- Hard rename, no compatibility views: app builds that still query "dishes" or
-- "dish_id" stop working once this runs. Function bodies below were generated from
-- the live definitions (pg_get_functiondef) with the identifiers renamed.


-- 1. Tables -------------------------------------------------------------------
alter table public.dishes                     rename to recipes;
alter table public.dish_ingredients_canonical rename to recipe_ingredients_canonical;

-- 2. Columns ------------------------------------------------------------------
alter table public.recipes                       rename column dish_kind_id to recipe_kind_id;
alter table public.meals                         rename column dish_id to recipe_id;
alter table public.notifications                 rename column dish_id to recipe_id;
alter table public.party_recipe_notes            rename column dish_id to recipe_id;
alter table public.party_recommendations         rename column dish_id to recipe_id;
alter table public.recipe_ingredients_canonical  rename column dish_id to recipe_id;

-- 3. Constraints (renaming one also renames the index behind it) ---------------
alter table public.recipes rename constraint dishes_name_check                  to recipes_name_check;
alter table public.recipes rename constraint dishes_normalized_name_check       to recipes_normalized_name_check;
alter table public.recipes rename constraint dishes_pkey                        to recipes_pkey;
alter table public.recipes rename constraint dishes_owner_id_normalized_name_key to recipes_owner_id_normalized_name_key;
alter table public.recipes rename constraint dishes_owner_id_fkey               to recipes_owner_id_fkey;
alter table public.recipes rename constraint dishes_effort_check                to recipes_effort_check;
alter table public.recipes rename constraint dishes_dish_kind_id_fkey           to recipes_recipe_kind_id_fkey;
alter table public.recipes rename constraint dishes_cooking_method_id_fkey      to recipes_cooking_method_id_fkey;
alter table public.recipes rename constraint dishes_cuisine_id_fkey             to recipes_cuisine_id_fkey;

alter table public.meals                 rename constraint meals_dish_id_fkey                    to meals_recipe_id_fkey;
alter table public.notifications         rename constraint notifications_dish_id_fkey            to notifications_recipe_id_fkey;
alter table public.party_recommendations rename constraint party_recommendations_dish_id_fkey    to party_recommendations_recipe_id_fkey;
alter table public.party_recipe_notes    rename constraint party_recipe_notes_dish_id_fkey       to party_recipe_notes_recipe_id_fkey;
alter table public.party_recipe_notes    rename constraint party_recipe_notes_party_id_dish_id_key to party_recipe_notes_party_id_recipe_id_key;

alter table public.recipe_ingredients_canonical rename constraint dish_ingredients_canonical_pkey to recipe_ingredients_canonical_pkey;
alter table public.recipe_ingredients_canonical rename constraint dish_ingredients_canonical_dish_id_raw_text_canonical_ingre_key to recipe_ingredients_canonical_recipe_id_raw_text_canonical_ingre_key;
alter table public.recipe_ingredients_canonical rename constraint dish_ingredients_canonical_dish_id_fkey to recipe_ingredients_canonical_recipe_id_fkey;
alter table public.recipe_ingredients_canonical rename constraint dish_ingredients_canonical_canonical_ingredient_id_fkey to recipe_ingredients_canonical_canonical_ingredient_id_fkey;

-- 4. Standalone indexes -------------------------------------------------------
alter index public.meals_dish_idx                                    rename to meals_recipe_idx;
alter index public.dishes_owner_idx                                  rename to recipes_owner_idx;
alter index public.dishes_cuisine_idx                                rename to recipes_cuisine_idx;
alter index public.dishes_is_public_idx                              rename to recipes_is_public_idx;
alter index public.dishes_embedding_idx                              rename to recipes_embedding_idx;
alter index public.dishes_dish_kind_idx                              rename to recipes_recipe_kind_idx;
alter index public.dishes_cooking_method_idx                         rename to recipes_cooking_method_idx;
alter index public.dish_ingredients_canonical_dish_id_idx            rename to recipe_ingredients_canonical_recipe_id_idx;
alter index public.dish_ingredients_canonical_canonical_ingredient_id_idx rename to recipe_ingredients_canonical_canonical_ingredient_id_idx;
alter index public.party_recipe_notes_dish_idx                       rename to party_recipe_notes_recipe_idx;

-- 5. Triggers -----------------------------------------------------------------
alter trigger dishes_touch                          on public.recipes rename to recipes_touch;
alter trigger dish_cuisines_sync_categories_trigger on public.recipes rename to recipe_cuisines_sync_categories_trigger;
alter trigger embed_dish_webhook                    on public.recipes rename to embed_recipe_webhook;

-- 6. Policies named after the table ---------------------------------------------
alter policy dishes_select     on public.recipes rename to recipes_select;
alter policy dishes_insert_own on public.recipes rename to recipes_insert_own;
alter policy dishes_update_own on public.recipes rename to recipes_update_own;
alter policy dishes_delete_own on public.recipes rename to recipes_delete_own;

-- 7. Functions that only change name (bodies are replaced below) ----------------
alter function public.embed_dish_on_change()                 rename to embed_recipe_on_change;
alter function public.sync_dish_cuisines_to_categories()     rename to sync_recipe_cuisines_to_categories;
alter function public.match_dishes(vector, double precision, integer) rename to match_recipes;

-- 8. Taxonomy: the dimension is part of the data ----------------------------------
update public.taxonomy_terms set dimension = 'recipe_kind' where dimension = 'dish_kind';
drop view public.dish_kinds;

-- 9. Function bodies. can_read_dish(p_dish_id) cannot keep its parameter name under
--    CREATE OR REPLACE, so can_read_recipe is created new, the policies are
--    repointed, and the old function is dropped.
CREATE OR REPLACE FUNCTION public.analyze_recipe_steps_on_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    fn_url text;
    secret text;
begin
    select decrypted_secret into fn_url
      from vault.decrypted_secrets
     where name = 'project_url';

    select decrypted_secret into secret
      from vault.decrypted_secrets
     where name = 'webhook_secret';

    if fn_url is null or secret is null then
        return new;
    end if;

    -- Only re-run when instructions or ingredients actually changed.
    if TG_OP = 'UPDATE' and old.ingredients is not distinct from new.ingredients and old.instructions is not distinct from new.instructions then
        return new;
    end if;

    perform net.http_post(
        url     := fn_url || '/functions/v1/analyze-recipe-steps',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      TG_OP,
                       'table',     'recipes',
                       'schema',    'public',
                       'record',    to_jsonb(new),
                       'old_record', to_jsonb(old)
                   ),
        timeout_milliseconds := 15000
    );

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.can_read_recipe(p_recipe_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
    select exists (
        select 1 from public.recipes d
        where d.id = p_recipe_id and d.is_deleted = false and (d.is_public = true or d.owner_id = auth.uid())
    ) or exists (
        select 1
        from public.meals m
        join public.meal_invites i on i.meal_id = m.id
        where m.recipe_id = p_recipe_id and i.invitee_id = auth.uid()
    ) or exists (
        select 1
        from public.meals m
        join public.meal_parties mp on mp.meal_id = m.id
        join public.party_members pm on pm.party_id = mp.party_id
        where m.recipe_id = p_recipe_id and pm.user_id = auth.uid()
    ) or exists (
        select 1
        from public.meals m
        where m.recipe_id = p_recipe_id and m.created_by = auth.uid()
    );
$function$
;

CREATE OR REPLACE FUNCTION public.canonicalize_ingredients_on_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    fn_url text;
    secret text;
begin
    select decrypted_secret into fn_url
      from vault.decrypted_secrets
     where name = 'project_url';

    select decrypted_secret into secret
      from vault.decrypted_secrets
     where name = 'webhook_secret';

    if fn_url is null or secret is null then
        return new;
    end if;

    -- Only re-run when the ingredient list actually changed.
    if TG_OP = 'UPDATE' and old.ingredients is not distinct from new.ingredients then
        return new;
    end if;

    perform net.http_post(
        url     := fn_url || '/functions/v1/canonicalize-ingredients',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      TG_OP,
                       'table',     'recipes',
                       'schema',    'public',
                       'record',    to_jsonb(new),
                       'old_record', to_jsonb(old)
                   ),
        timeout_milliseconds := 15000
    );

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.embed_recipe_on_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    fn_url text;
    secret text;
begin
    select decrypted_secret into fn_url
      from vault.decrypted_secrets
     where name = 'project_url';

    select decrypted_secret into secret
      from vault.decrypted_secrets
     where name = 'webhook_secret';

    if fn_url is null or secret is null then
        return new;
    end if;

    perform net.http_post(
        url     := fn_url || '/functions/v1/embed-recipe',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      TG_OP,
                       'table',     'recipes',
                       'schema',    'public',
                       'record',    to_jsonb(new),
                       'old_record', to_jsonb(old)
                   ),
        timeout_milliseconds := 5000
    );

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_flavor_profile(p_scope text, p_id uuid)
 RETURNS TABLE(canonical_ingredient_id uuid, canonical_name text, category text, sample_size integer, loved_pct integer, polarization integer, sentiment text)
 LANGUAGE sql
 STABLE
AS $function$
    with target_scores as (
        select m.recipe_id,
               avg(case mr.reaction
                       when -1 then 0.0 when 1 then 0.2 when 2 then 0.4
                       when 3 then 0.6 when 4 then 0.8 when 5 then 1.0
                       else 0.6 end) as score
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        join public.meal_ratings mr on mr.meal_id = m.id
        join public.party_members pm on pm.party_id = mp.party_id 
          and pm.user_id = coalesce(mr.rater_id, (select owner_id from public.eaters where id = mr.eater_id))
        where p_scope = 'party' and mp.party_id = p_id
        group by m.recipe_id

        union all

        select m.recipe_id,
               avg(case mr.reaction
                       when -1 then 0.0 when 1 then 0.2 when 2 then 0.4
                       when 3 then 0.6 when 4 then 0.8 when 5 then 1.0
                       else 0.6 end) as score
        from public.meal_ratings mr
        join public.meals m on m.id = mr.meal_id
        where p_scope = 'person' and coalesce(mr.rater_id, mr.eater_id) = p_id
        group by m.recipe_id
    ),
    ingredient_scores as (
        select dic.canonical_ingredient_id, ts.score
        from public.recipe_ingredients_canonical dic
        join target_scores ts on ts.recipe_id = dic.recipe_id
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
$function$
;

CREATE OR REPLACE FUNCTION public.handle_user_deletion()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    v_party record;
    v_new_owner uuid;
begin
    -- 1. Handover or delete parties
    for v_party in select id from public.parties where created_by = old.id loop
        select user_id into v_new_owner
        from public.party_members
        where party_id = v_party.id and user_id != old.id
        order by joined_at asc
        limit 1;

        if v_new_owner is not null then
            update public.parties set created_by = v_new_owner where id = v_party.id;
        else
            delete from public.parties where id = v_party.id;
        end if;
    end loop;
    
    -- 2. Anonymize recipes
    update public.recipes set owner_id = null where owner_id = old.id;
    
    -- 3. Anonymize meals
    update public.meals set created_by = null where created_by = old.id;
    
    -- 4. Anonymize meal ratings
    update public.meal_ratings set rater_id = null where rater_id = old.id;
    
    update public.meal_ratings 
    set eater_id = null 
    where eater_id in (select id from public.eaters where owner_id = old.id);

    -- 5. Anonymize invites
    update public.meal_invites set inviter_id = null where inviter_id = old.id;
    update public.party_invites set inviter_id = null where inviter_id = old.id;

    return old;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.match_recipes(query_embedding vector, match_threshold double precision, match_count integer)
 RETURNS TABLE(id uuid, name text, cuisine text, similarity double precision)
 LANGUAGE sql
 STABLE
AS $function$
  select
    recipes.id,
    recipes.name,
    recipes.cuisine,
    1 - (recipes.embedding <=> query_embedding) as similarity
  from recipes
  where recipes.embedding is not null
    and 1 - (recipes.embedding <=> query_embedding) > match_threshold
  order by recipes.embedding <=> query_embedding
  limit match_count;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_invitee()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    v_recipe_name text;
begin
    if new.invitee_id is null then
        return new;
    end if;

    -- Already notified when the row was first linked to this user.
    if tg_op = 'UPDATE' and old.invitee_id is not null then
        return new;
    end if;

    if new.invitee_id = new.inviter_id then
        return new;
    end if;

    select d.name
      into v_recipe_name
      from public.meals m
      join public.recipes d on d.id = m.recipe_id
     where m.id = new.meal_id;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        new.invitee_id,
        new.meal_id,
        'rating_request',
        'How was it?',
        coalesce(v_recipe_name, 'A meal') || ' is waiting for your rating.'
    );

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_rating()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    v_creator   uuid;
    v_recipe_name text;
    v_actor     uuid;
    v_who       text;
begin
    select m.created_by, d.name
      into v_creator, v_recipe_name
      from public.meals m
      join public.recipes d on d.id = m.recipe_id
     where m.id = new.meal_id;

    if v_creator is null then
        return new;
    end if;

    if new.rater_id is not null then
        v_actor := new.rater_id;
        select nullif(p.display_name, '')
          into v_who
          from public.profiles p
         where p.id = new.rater_id;
    else
        -- meal_ratings_insert only permits an eater rating from
        -- eaters.owner_id = auth.uid(), so the owner is by construction whoever
        -- entered it.
        select e.owner_id, nullif(e.name, '')
          into v_actor, v_who
          from public.eaters e
         where e.id = new.eater_id;
    end if;

    -- Your own doing: nothing to report.
    if v_actor is null or v_creator = v_actor then
        return new;
    end if;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        v_creator,
        new.meal_id,
        'rating_received',
        'New rating',
        coalesce(v_who, 'Someone') || ' rated ' || coalesce(v_recipe_name, 'a meal') || '.'
    );

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_recipe_favorited()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    v_owner     uuid;
    v_recipe_name text;
    v_liker     text;
begin
    select d.owner_id, d.name
      into v_owner, v_recipe_name
      from public.recipes d
     where d.id = new.recipe_id;

    -- Owner gone, or you liked your own recipe: nothing to report.
    if v_owner is null or v_owner = new.user_id then
        return new;
    end if;

    select coalesce(
        nullif(pr.display_name, ''),
        nullif(btrim(pr.first_name || ' ' || coalesce(pr.last_name, '')), ''),
        'Someone'
    )
      into v_liker
      from public.profiles pr
     where pr.id = new.user_id;

    insert into public.notifications (user_id, recipe_id, kind, title, body)
    values (
        v_owner,
        new.recipe_id,
        'recipe_liked',
        'New like',
        coalesce(v_liker, 'Someone') || ' liked ' || coalesce(v_recipe_name, 'your recipe') || '.'
    );

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.party_recommendation_candidates(p_party_id uuid, p_user_id uuid, p_limit integer DEFAULT 30)
 RETURNS TABLE(id uuid, name text, cuisine text, ingredients jsonb, health_score integer, effort smallint, similarity double precision)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
    with party_meals as (
        select m.id as meal_id, m.recipe_id
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        where mp.party_id = p_party_id
    ),
    meal_avg as (
        select pm.recipe_id, avg(mr.score) as score
        from party_meals pm
        join public.meal_ratings mr on mr.meal_id = pm.meal_id
        group by pm.recipe_id, pm.meal_id
    ),
    liked as (
        select avg(d.embedding) as v
        from meal_avg ma join public.recipes d on d.id = ma.recipe_id
        where ma.score >= 0.5 and d.embedding is not null
    ),
    disliked as (
        select avg(d.embedding) as v
        from meal_avg ma join public.recipes d on d.id = ma.recipe_id
        where ma.score < 0.3 and d.embedding is not null
    )
    select d.id, d.name, d.cuisine, d.ingredients, d.health_score, d.effort,
           1 - (d.embedding <=> l.v) as similarity
    from public.recipes d
    cross join liked l
    left join disliked x on true
    where l.v is not null
      and d.embedding is not null
      and (d.is_public = true or d.owner_id = p_user_id)
      and d.id not in (select recipe_id from party_meals)
    -- a quarter-weight push away from what the party rated poorly
    order by (d.embedding <=> l.v) - 0.25 * coalesce(d.embedding <=> x.v, 0)
    limit p_limit;
$function$
;

CREATE OR REPLACE FUNCTION public.remind_meal_invite(p_invite_id uuid)
 RETURNS meal_invites
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    v_invite    public.meal_invites;
    v_recipe_name text;
    v_last      timestamptz;
begin
    select * into v_invite from public.meal_invites where id = p_invite_id for update;
    if not found then
        raise exception 'invite not found' using errcode = 'P0002';
    end if;

    -- Same audience as the insert policy: the cook or anyone sharing the meal's party.
    if not (
        exists (select 1 from public.meals m where m.id = v_invite.meal_id and m.created_by = auth.uid())
        or public.shares_meal_party(v_invite.meal_id)
    ) then
        raise exception 'not allowed' using errcode = '42501';
    end if;

    if v_invite.invitee_id is null or v_invite.status <> 'pending' then
        raise exception 'nothing to remind' using errcode = '22023';
    end if;

    -- Already rated: nothing to nudge.
    if exists (
        select 1 from public.meal_ratings r
         where r.meal_id = v_invite.meal_id and r.rater_id = v_invite.invitee_id
    ) then
        raise exception 'already rated' using errcode = '22023';
    end if;

    v_last := coalesce(v_invite.reminded_at, v_invite.created_at);
    if now() - v_last < interval '24 hours' then
        raise exception 'reminded too recently' using errcode = 'P0001',
            detail = to_char(v_last + interval '24 hours', 'YYYY-MM-DD"T"HH24:MI:SSOF');
    end if;

    update public.meal_invites
       set reminded_at = now(), remind_count = remind_count + 1
     where id = p_invite_id
    returning * into v_invite;

    select d.name
      into v_recipe_name
      from public.meals m
      join public.recipes d on d.id = m.recipe_id
     where m.id = v_invite.meal_id;

    insert into public.notifications (user_id, meal_id, kind, title, body)
    values (
        v_invite.invitee_id,
        v_invite.meal_id,
        'rating_request',
        'Still waiting on you',
        coalesce(v_recipe_name, 'A meal') || ' is waiting for your rating.'
    );

    return v_invite;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.suggest_parties(p_limit integer DEFAULT 10, p_offset integer DEFAULT 0)
 RETURNS TABLE(party_id uuid, similar_party_id uuid, similarity double precision, shared_cuisine text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
    with my_parties as (
        select pm.party_id as id from public.party_members pm where pm.user_id = auth.uid()
    ),
    followed as (
        select pf.party_id as id from public.party_followers pf where pf.user_id = auth.uid()
    ),
    centroids as materialized (
        select mp.party_id, avg(d.embedding) as v
        from public.meal_parties mp
        join public.meals  m on m.id = mp.meal_id
        join public.recipes d on d.id = m.recipe_id
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
               join public.recipes d on d.id = m.recipe_id
               where mp.party_id = s.party_id
                 and s.similar_party_id is not null
                 and d.cuisine is not null
                 and d.cuisine in (
                     select d2.cuisine
                     from public.meal_parties mp2
                     join public.meals  m2 on m2.id = mp2.meal_id
                     join public.recipes d2 on d2.id = m2.recipe_id
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
$function$
;

CREATE OR REPLACE FUNCTION public.suggest_recipes_for_party(p_party_id uuid, p_match_count integer DEFAULT 5)
 RETURNS TABLE(id uuid, name text, cuisine text, health_score integer, effort smallint, similarity double precision)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
    with party_taste as (
        select avg(d.embedding) as taste_embedding
        from public.meal_parties mp
        join public.meals m on m.id = mp.meal_id
        join public.recipes d on d.id = m.recipe_id
        join public.meal_ratings mr on mr.meal_id = m.id
        join public.party_members pm on pm.party_id = mp.party_id 
          and pm.user_id = coalesce(mr.rater_id, (select owner_id from public.eaters where id = mr.eater_id))
        where mp.party_id = p_party_id
          and d.embedding is not null
          and mr.reaction >= 3
    ),
    eaten as (
        select distinct m.recipe_id
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
    from public.recipes d
    cross join party_taste pt
    where pt.taste_embedding is not null
      and d.embedding is not null
      and d.is_public = true
      and d.is_deleted = false
      and d.id not in (select recipe_id from eaten)
    order by d.embedding <=> pt.taste_embedding
    limit p_match_count;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_recipe_cuisines_to_categories()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    v_part text;
    v_slug text;
begin
    if new.cuisine is not null and trim(new.cuisine) != '' then
        foreach v_part in array string_to_array(new.cuisine, ',') loop
            v_part := trim(v_part);
            if v_part != '' then
                v_slug := lower(regexp_replace(v_part, '[^a-zA-Z0-9]+', '-', 'g'));
                v_slug := trim(both '-' from v_slug);
                if v_slug != '' and not exists (select 1 from public.categories where slug = v_slug) then
                    insert into public.categories (slug, name)
                    values (v_slug, initcap(v_part))
                    on conflict (slug) do nothing;
                end if;
            end if;
        end loop;
    end if;
    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.trigger_category_photo_generation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
    fn_url text;
    secret text;
begin
    -- Only generate if photo_path is currently NULL
    if new.photo_path is not null then
        return new;
    end if;

    select decrypted_secret into fn_url
      from vault.decrypted_secrets
     where name = 'project_url';

    select decrypted_secret into secret
      from vault.decrypted_secrets
     where name = 'webhook_secret';

    if fn_url is null or secret is null then
        return new;
    end if;

    perform net.http_post(
        url     := fn_url || '/functions/v1/generate-recipe-photo',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      TG_OP,
                       'table',     'categories',
                       'schema',    'public',
                       'record',    to_jsonb(new)
                   ),
        timeout_milliseconds := 60000
    );

    return new;
end;
$function$
;


-- 10. Policies that call can_read_dish -----------------------------------------------
alter policy recipes_select on public.recipes
    using ((owner_id = auth.uid()) or public.can_read_recipe(id));

alter policy recipe_photos_read on storage.objects
    using ((bucket_id = 'recipe-photos'::text)
           and (split_part(name, '/'::text, 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'::text)
           and public.can_read_recipe((split_part(name, '/'::text, 1))::uuid));

alter policy party_recipe_notes_insert on public.party_recipe_notes
    with check (public.is_party_member(party_id) and public.can_read_recipe(recipe_id));

alter policy party_recipe_notes_update on public.party_recipe_notes
    using (public.is_party_member(party_id))
    with check (public.is_party_member(party_id) and public.can_read_recipe(recipe_id));

alter policy recipe_favorites_insert on public.recipe_favorites
    with check ((user_id = auth.uid()) and public.can_read_recipe(recipe_id));

drop function public.can_read_dish(uuid);

-- 11. recipe_kinds view -------------------------------------------------------------
create view public.recipe_kinds as
select id, slug, name, aliases, created_at, updated_at
from public.taxonomy_terms
where dimension = 'recipe_kind';

-- 12. Enum values and config rows that carry the old name -------------------------------
alter type public.generation_type rename value 'dish_photo' to 'recipe_photo';
alter type public.generation_type rename value 'dish_embed' to 'recipe_embed';
alter type public.generation_type add value if not exists 'meal_photo';

-- generate-dish-photo is now two functions: recipe photos (and categories) and meal photos.
-- The meal function starts on the same model the combined one used.
update public.ai_feature_configs set feature_id = 'generate-recipe-photo' where feature_id = 'generate-dish-photo';
update public.ai_feature_configs set feature_id = 'recipe-photo-brief'    where feature_id = 'dish-photo-brief';
insert into public.ai_feature_configs (feature_id, model_name)
select 'generate-meal-photo', model_name from public.ai_feature_configs where feature_id = 'generate-recipe-photo'
on conflict (feature_id) do nothing;

