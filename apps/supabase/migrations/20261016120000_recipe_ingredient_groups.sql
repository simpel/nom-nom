-- Recipe ingredients in groups ("For the sauce", "For the salad", …).
--
-- recipes.ingredients (a flat jsonb array) becomes recipes.ingredient_groups:
--   [{ "name": "Sauce" | null, "ingredients": [{ "quantity", "measurement", "ingredient" }, …] }, …]
-- A group's name is optional; a recipe with no sections is one unnamed group.
-- Group order and ingredient order are the order they are cooked/listed in.
--
-- instruction_details[].ingredients stay indexes, now into the groups' ingredients
-- read in order (group 0's, then group 1's, …), so cook mode keeps working unchanged.

alter table public.recipes
    add column ingredient_groups jsonb not null default '[]'::jsonb;

-- Existing recipes become one unnamed group.
update public.recipes
   set ingredient_groups = jsonb_build_array(jsonb_build_object('name', null, 'ingredients', ingredients))
 where jsonb_typeof(ingredients) = 'array'
   and jsonb_array_length(ingredients) > 0;

alter table public.recipes
    add constraint recipes_ingredient_groups_is_array check (jsonb_typeof(ingredient_groups) = 'array');

-- The webhooks compared the old column; point them at the new one.
create or replace function public.canonicalize_ingredients_on_change()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
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

    -- Only re-run when the ingredients actually changed.
    if TG_OP = 'UPDATE' and old.ingredient_groups is not distinct from new.ingredient_groups then
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
$function$;

create or replace function public.analyze_recipe_steps_on_change()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
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
    if TG_OP = 'UPDATE' and old.ingredient_groups is not distinct from new.ingredient_groups and old.instructions is not distinct from new.instructions then
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
$function$;

-- The return type changes, so drop and recreate.
drop function public.party_recommendation_candidates(uuid, uuid, int);

create function public.party_recommendation_candidates(p_party_id uuid, p_user_id uuid, p_limit integer default 30)
 returns table(id uuid, name text, cuisine text, ingredient_groups jsonb, health_score integer, effort smallint, similarity double precision)
 language sql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
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
    select d.id, d.name, d.cuisine, d.ingredient_groups, d.health_score, d.effort,
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
$function$;

revoke all on function public.party_recommendation_candidates(uuid, uuid, int) from public, anon, authenticated;
grant execute on function public.party_recommendation_candidates(uuid, uuid, int) to service_role;

alter table public.recipes
    drop column ingredients;
