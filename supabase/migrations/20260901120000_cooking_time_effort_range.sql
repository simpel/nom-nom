-- ===========================================================================
-- Expand cooking duration / effort constraint to 0..3 (0-15, 15-30, 30-60, 60+)
-- ===========================================================================

alter table public.meals
    drop constraint if exists meals_effort_check;
alter table public.meals
    add constraint meals_effort_check check (effort is null or (effort between 0 and 3));

alter table public.dishes
    drop constraint if exists dishes_effort_check;
alter table public.dishes
    add constraint dishes_effort_check check (effort is null or (effort between 0 and 3));
