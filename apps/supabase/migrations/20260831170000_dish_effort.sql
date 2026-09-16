-- ===========================================================================
-- Dish Cooking Effort Support
-- ===========================================================================

-- Add effort (0=breeze, 1=normal, 2=project) to public.dishes
alter table public.dishes
    add column if not exists effort smallint check (effort between 0 and 2);
