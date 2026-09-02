-- ===========================================================================
-- Expand Meal Ratings Reaction Scale (-1 to 5)
-- -1: Can't eat / Disgusting
--  1: Bad
--  2: Meh
--  3: Good
--  4: Great
--  5: Amazing
-- ===========================================================================

alter table public.meal_ratings drop constraint if exists meal_ratings_reaction_check;
alter table public.meal_ratings add constraint meal_ratings_reaction_check check (reaction between -1 and 5);
