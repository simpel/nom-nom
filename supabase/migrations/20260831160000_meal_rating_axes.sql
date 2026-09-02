-- ===========================================================================
-- Meal Rating Axes (Effort and Rotation Goal)
-- ===========================================================================

-- 1. Add effort (0=breeze, 1=normal, 2=project) and repeat_desire (0=one_and_done, 1=sometimes, 2=staple)
alter table public.meals
    add column if not exists effort smallint check (effort between 0 and 2),
    add column if not exists repeat_desire smallint check (repeat_desire between 0 and 2);
