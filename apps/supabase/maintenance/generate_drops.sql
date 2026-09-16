-- Read-only: prints the DROP statements for anything in `public` that isn't part
-- of this app, without executing them. Eyeball the output, then run what you agree
-- with. Deliberately not a migration — a blind mass-drop against a database
-- nobody has looked at is not something to automate.

with keep(name) as (
    values ('profiles'), ('dishes'), ('meals'), ('eaters'),
           ('meal_invites'), ('meal_ratings'), ('notifications'), ('device_tokens')
)
select format('drop table if exists public.%I cascade;', t.table_name) as statement,
       (select count(*) from pg_class c
         where c.relname = t.table_name and c.relnamespace = 'public'::regnamespace) as exists_now
  from information_schema.tables t
 where t.table_schema = 'public'
   and t.table_type = 'BASE TABLE'
   and t.table_name not in (select name from keep)
 order by t.table_name;
