-- ===========================================================================
-- Add serves (portions) column to dishes
-- ===========================================================================

alter table public.dishes
    add column if not exists serves integer;
