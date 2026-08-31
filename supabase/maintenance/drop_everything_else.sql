-- DESTRUCTIVE. Drops every object in `public` that is not part of this app.
--
-- The keep-list below was generated from a clean local database with only this
-- app's migrations applied, so it is the app's real surface rather than a list
-- written from memory.
--
-- Scope and guards:
--   * touches the `public` schema only — `auth`, `storage`, `extensions` are
--     never referenced, so Supabase's own tables are safe;
--   * skips anything owned by an extension (pg_depend.deptype = 'e'), which
--     Postgres refuses to drop individually anyway;
--   * reports each drop as a NOTICE so the output is an audit trail.
--
-- On this project every stray table was verified empty beforehand, so there is
-- no data to lose. Re-running it is harmless once the strays are gone.

do $$
declare
    keep_tables text[] := array[
        'device_tokens','dishes','eaters','meal_invites',
        'meal_ratings','meals','notifications','profiles'
    ];
    keep_routines text[] := array[
        'can_read_dish','handle_new_user','is_meal_participant',
        'notify_invitee','notify_rating','touch_updated_at'
    ];
    keep_types text[] := array['invite_status'];
    r record;
    dropped int := 0;
begin
    -- Views first: they can depend on tables, and dropping them plainly keeps
    -- the table-level cascades below quieter.
    for r in
        select table_name from information_schema.views where table_schema = 'public'
    loop
        execute format('drop view if exists public.%I cascade', r.table_name);
        raise notice 'dropped view %', r.table_name;
        dropped := dropped + 1;
    end loop;

    for r in
        select c.relname
          from pg_class c
          join pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public'
           and c.relkind = 'r'
           and not (c.relname = any (keep_tables))
           and not exists (select 1 from pg_depend d
                            where d.objid = c.oid and d.deptype = 'e')
    loop
        execute format('drop table if exists public.%I cascade', r.relname);
        raise notice 'dropped table %', r.relname;
        dropped := dropped + 1;
    end loop;

    -- Identity arguments are required: overloads share a name.
    for r in
        select p.oid,
               p.proname,
               pg_get_function_identity_arguments(p.oid) as args,
               case p.prokind when 'p' then 'procedure' else 'function' end as kind
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and not (p.proname = any (keep_routines))
           and not exists (select 1 from pg_depend d
                            where d.objid = p.oid and d.deptype = 'e')
    loop
        execute format('drop %s if exists public.%I(%s) cascade', r.kind, r.proname, r.args);
        raise notice 'dropped % %(%)', r.kind, r.proname, r.args;
        dropped := dropped + 1;
    end loop;

    for r in
        select t.typname
          from pg_type t
          join pg_namespace n on n.oid = t.typnamespace
         where n.nspname = 'public'
           and t.typtype = 'e'
           and not (t.typname = any (keep_types))
           and not exists (select 1 from pg_depend d
                            where d.objid = t.oid and d.deptype = 'e')
    loop
        execute format('drop type if exists public.%I cascade', r.typname);
        raise notice 'dropped type %', r.typname;
        dropped := dropped + 1;
    end loop;

    -- Sequences owned by a dropped table went with it; this catches strays that
    -- were never attached to a column.
    for r in
        select c.relname
          from pg_class c
          join pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public'
           and c.relkind = 'S'
           and not exists (select 1 from pg_depend d
                            where d.objid = c.oid and d.deptype in ('a','e'))
    loop
        execute format('drop sequence if exists public.%I cascade', r.relname);
        raise notice 'dropped sequence %', r.relname;
        dropped := dropped + 1;
    end loop;

    raise notice '--- % object(s) dropped ---', dropped;
end $$;

-- What survived. Should be exactly 8 tables, 6 functions, 1 enum, 0 views.
select 'table' as kind, c.relname as name
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind = 'r'
union all
select 'function', p.proname
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
union all
select 'enum', t.typname
  from pg_type t join pg_namespace n on n.oid = t.typnamespace
 where n.nspname = 'public' and t.typtype = 'e'
order by kind, name;
