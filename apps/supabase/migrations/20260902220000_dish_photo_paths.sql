-- ===========================================================================
-- Dish Cover Photos Support
-- ===========================================================================

-- Add photo_paths text[] column to dishes table
alter table public.dishes
    add column if not exists photo_paths text[] not null default '{}';
