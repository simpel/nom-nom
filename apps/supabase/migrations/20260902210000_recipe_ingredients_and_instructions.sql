-- ===========================================================================
-- Recipe Ingredients (quantity, measurement, ingredient) & Instructions
-- ===========================================================================

-- 1. Add ingredients (jsonb) and instructions (text[]) columns to dishes
alter table public.dishes
    add column if not exists ingredients jsonb not null default '[]'::jsonb,
    add column if not exists instructions text[] not null default '{}';

-- 2. Drop legacy recipe_text column
alter table public.dishes
    drop column if exists recipe_text;
