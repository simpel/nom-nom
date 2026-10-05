-- Optional name for one serving of a recipe. Null means "use the recipe's name".
alter table public.meals add column title text;
