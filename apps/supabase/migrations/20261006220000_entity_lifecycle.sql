-- 1. Recipe Soft Deletes & Anonymized Owners
alter table public.dishes
    add column is_deleted boolean not null default false,
    alter column owner_id drop not null;

-- 2. Anonymized Meals
alter table public.meals
    alter column created_by drop not null;

-- 3. Anonymized Meal Ratings
alter table public.meal_ratings drop constraint if exists one_rating_source;
alter table public.meal_ratings add constraint one_rating_source check (
    rater_id is null or eater_id is null
);

-- 4. Handle User Deletion (Anonymize recipes/meals/ratings, transfer or delete parties)
create or replace function public.handle_user_deletion()
returns trigger as $$
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
    update public.dishes set owner_id = null where owner_id = old.id;
    
    -- 3. Anonymize meals
    update public.meals set created_by = null where created_by = old.id;
    
    -- 4. Anonymize meal ratings
    update public.meal_ratings set rater_id = null where rater_id = old.id;
    
    -- Eaters are deleted by cascade, but their ratings should be anonymized too
    update public.meal_ratings 
    set eater_id = null 
    where eater_id in (select id from public.eaters where owner_id = old.id);

    return old;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_deleted on auth.users;
create trigger on_auth_user_deleted
    before delete on auth.users
    for each row execute function public.handle_user_deletion();

-- 5. Update get_flavor_profile to restrict party flavor profile to current members
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
        join public.party_members pm on pm.party_id = mp.party_id 
          and pm.user_id = coalesce(mr.rater_id, (select owner_id from public.eaters where id = mr.eater_id))
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

-- 6. Update suggest_recipes_for_party to restrict taste vector to current members
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
        join public.party_members pm on pm.party_id = mp.party_id 
          and pm.user_id = coalesce(mr.rater_id, (select owner_id from public.eaters where id = mr.eater_id))
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
      and d.is_deleted = false
      and d.id not in (select dish_id from eaten)
    order by d.embedding <=> pt.taste_embedding
    limit p_match_count;
$$;

-- 7. Anonymize Meal and Party Invites to preserve access for invitees
alter table public.meal_invites alter column inviter_id drop not null;
alter table public.party_invites alter column inviter_id drop not null;

create or replace function public.handle_user_deletion()
returns trigger as $$
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
    update public.dishes set owner_id = null where owner_id = old.id;
    
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
$$ language plpgsql security definer;

-- 8. Equality for all party members (no "owner" privileges)
alter table public.parties alter column created_by drop not null;

drop policy if exists parties_update on public.parties;
create policy parties_update on public.parties
    for update to authenticated
    using (public.is_party_member(id))
    with check (public.is_party_member(id));

drop policy if exists parties_delete on public.parties;
create policy parties_delete on public.parties
    for delete to authenticated
    using (public.is_party_member(id));

drop policy if exists party_members_insert on public.party_members;
create policy party_members_insert on public.party_members
    for insert to authenticated
    with check (
        user_id = auth.uid()
        or public.is_party_member(party_id)
    );

drop policy if exists party_members_delete on public.party_members;
create policy party_members_delete on public.party_members
    for delete to authenticated
    using (
        user_id = auth.uid()
        or public.is_party_member(party_id)
    );

create or replace function public.check_can_follow_party(p_party_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if exists (
        select 1 from public.party_members
        where party_id = p_party_id and user_id = auth.uid()
    ) then
        raise exception 'Cannot follow a dinner party you are already a member of';
    end if;

    if not exists (
        select 1 from public.parties
        where id = p_party_id and is_public = true
    ) then
        raise exception 'Party not found or not public';
    end if;
end;
$$;

drop policy if exists parties_select on public.parties;
create policy parties_select on public.parties
    for select to authenticated using (
        public.is_party_member(id)
        or is_public = true
        or exists (
            select 1
            from public.party_invites pi
            where pi.party_id = parties.id
              and pi.status = 'pending'
              and (pi.invitee_id = auth.uid() or pi.invitee_email = auth.email())
        )
    );

drop policy if exists parties_insert on public.parties;
create policy parties_insert on public.parties
    for insert to authenticated
    with check (true);

-- 9. Update suggest_parties to not use created_by
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

-- 10. Update all_insights to not use created_by
create or replace function public.all_insights(
    p_since timestamptz default null
)
returns table (
    party_id         uuid,
    insight_type     text,
    insight_data     jsonb,
    created_at       timestamptz,
    is_new           boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with my_parties as (
        select party_id as id from public.party_members where user_id = auth.uid()
    ),
    all_rows as (
        select
            pi.party_id,
            pi.insight_type,
            pi.insight_data,
            pi.created_at,
            (p_since is not null and pi.created_at > p_since) as is_new
        from public.party_insights pi
        join my_parties mp on mp.id = pi.party_id
    )
    select * from all_rows order by created_at desc;
$$;

-- 11. Restrict public access to deleted dishes
create or replace function public.can_read_dish(p_dish_id uuid)
    returns boolean
    language sql
    security definer
    stable
    set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.dishes d
        where d.id = p_dish_id and d.is_deleted = false and (d.is_public = true or d.owner_id = auth.uid())
    ) or exists (
        select 1
        from public.meals m
        join public.meal_invites i on i.meal_id = m.id
        where m.dish_id = p_dish_id and i.invitee_id = auth.uid()
    ) or exists (
        select 1
        from public.meals m
        join public.meal_parties mp on mp.meal_id = m.id
        join public.party_members pm on pm.party_id = mp.party_id
        where m.dish_id = p_dish_id and pm.user_id = auth.uid()
    ) or exists (
        select 1
        from public.meals m
        where m.dish_id = p_dish_id and m.created_by = auth.uid()
    );
$$;

drop policy if exists dishes_select on public.dishes;
create policy dishes_select on public.dishes
    for select to authenticated using (
        public.can_read_dish(id)
    );
