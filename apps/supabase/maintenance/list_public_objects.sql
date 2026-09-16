-- Read-only. Run this in the SQL Editor to get the definitive inventory of the
-- `public` schema.
--
-- Worth running because the leftovers were found by probing the REST API with a
-- publishable key, which cannot enumerate a schema — it only reveals a table when
-- a 404's "perhaps you meant" hint happens to name it. That is a fuzzy oracle, not
-- a listing, so there may be objects it never surfaced.

select 'table' as kind, table_name as name, null as detail
  from information_schema.tables
 where table_schema = 'public' and table_type = 'BASE TABLE'
union all
select 'view', table_name, null
  from information_schema.views
 where table_schema = 'public'
union all
select 'function', p.proname, pg_get_function_identity_arguments(p.oid)
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
union all
select 'type', t.typname, null
  from pg_type t join pg_namespace n on n.oid = t.typnamespace
 where n.nspname = 'public' and t.typtype = 'e'
order by kind, name;
