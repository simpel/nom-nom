-- ===========================================================================
-- Universal Taxonomy Expansion:
-- 1. Seed canonical Cooking Methods, Cuisines, and Ingredient Categories
-- 2. Add cooking_method_id and cuisine_id to public.dishes
-- 3. Remove hardcoded check constraint on ingredient_vocabulary.category and add category_id
-- 4. Drop tags column from public.dishes
-- ===========================================================================

-- 1. Seed canonical cooking methods
insert into public.taxonomy_terms (id, dimension, slug, name, aliases)
values
    ('b0000000-0000-0000-0000-000000000001', 'cooking_method', 'baking', 'Baking', array['bake', 'baked', 'oven', 'ugnsbakat']),
    ('b0000000-0000-0000-0000-000000000002', 'cooking_method', 'grilling', 'Grilling', array['grill', 'grilled', 'bbq', 'barbecue', 'charcoal', 'grillat']),
    ('b0000000-0000-0000-0000-000000000003', 'cooking_method', 'slow_cooking', 'Slow Cooking', array['slow-cooked', 'slow cook', 'crockpot', 'braised', 'braising', 'stewed', 'långkok']),
    ('b0000000-0000-0000-0000-000000000004', 'cooking_method', 'roasting', 'Roasting', array['roast', 'roasted', 'sheet-pan', 'ugnsstekt']),
    ('b0000000-0000-0000-0000-000000000005', 'cooking_method', 'steaming', 'Steaming', array['steam', 'steamed', 'ångkoka', 'ångad']),
    ('b0000000-0000-0000-0000-000000000006', 'cooking_method', 'frying', 'Frying', array['fried', 'deep-fried', 'pan-fried', 'crispy', 'friterad', 'stekt']),
    ('b0000000-0000-0000-0000-000000000007', 'cooking_method', 'sauteing', 'Sautéing', array['saute', 'sauté', 'pan-sear', 'stir-fry', 'wok', 'wokat', 'fräst']),
    ('b0000000-0000-0000-0000-000000000008', 'cooking_method', 'simmering', 'Simmering & Boiling', array['simmer', 'simmered', 'boiled', 'boiling', 'poached', 'broth', 'kokt']),
    ('b0000000-0000-0000-0000-000000000009', 'cooking_method', 'raw_cured', 'Raw & Cured', array['raw', 'fresh', 'cured', 'ceviche', 'marinated', 'gravad', 'sallad']),
    ('b0000000-0000-0000-0000-000000000010', 'cooking_method', 'smoking', 'Smoking', array['smoked', 'smoke', 'rökt'])
on conflict (dimension, slug) do nothing;

-- 2. Seed canonical cuisines (wide/umbrella picks)
insert into public.taxonomy_terms (id, dimension, slug, name, aliases)
values
    ('c0000000-0000-0000-0000-000000000001', 'cuisine', 'mexican', 'Mexican', array['mexico', 'tex-mex', 'taco']),
    ('c0000000-0000-0000-0000-000000000002', 'cuisine', 'italian', 'Italian', array['italy', 'pasta', 'pizza']),
    ('c0000000-0000-0000-0000-000000000003', 'cuisine', 'asian', 'Asian', array['pan-asian', 'oriental']),
    ('c0000000-0000-0000-0000-000000000004', 'cuisine', 'nordic', 'Nordic', array['swedish', 'scandinavian', 'svensk', 'nordisk']),
    ('c0000000-0000-0000-0000-000000000005', 'cuisine', 'mediterranean', 'Mediterranean', array['medelhavet']),
    ('c0000000-0000-0000-0000-000000000006', 'cuisine', 'indian', 'Indian', array['india', 'curry']),
    ('c0000000-0000-0000-0000-000000000007', 'cuisine', 'middle_eastern', 'Middle Eastern', array['lebanese', 'arabic', 'persian', 'mellanöstern']),
    ('c0000000-0000-0000-0000-000000000008', 'cuisine', 'american', 'American', array['usa', 'diner']),
    ('c0000000-0000-0000-0000-000000000009', 'cuisine', 'french', 'French', array['france', 'bistro', 'fransk']),
    ('c0000000-0000-0000-0000-000000000010', 'cuisine', 'japanese', 'Japanese', array['japan', 'sushi', 'ramen']),
    ('c0000000-0000-0000-0000-000000000011', 'cuisine', 'thai', 'Thai', array['thailand', 'pad thai']),
    ('c0000000-0000-0000-0000-000000000012', 'cuisine', 'korean', 'Korean', array['korea', 'kimchi']),
    ('c0000000-0000-0000-0000-000000000013', 'cuisine', 'greek', 'Greek', array['greece', 'hellenic']),
    ('c0000000-0000-0000-0000-000000000014', 'cuisine', 'spanish', 'Spanish', array['spain', 'tapas', 'spanien']),
    ('c0000000-0000-0000-0000-000000000015', 'cuisine', 'chinese', 'Chinese', array['china', 'cantonese', 'sichuan']),
    ('c0000000-0000-0000-0000-000000000016', 'cuisine', 'vietnamese', 'Vietnamese', array['vietnam', 'pho']),
    ('c0000000-0000-0000-0000-000000000017', 'cuisine', 'moroccan', 'Moroccan', array['morocco', 'north african'])
on conflict (dimension, slug) do nothing;

-- 3. Seed canonical ingredient categories
insert into public.taxonomy_terms (id, dimension, slug, name, aliases)
values
    ('d0000000-0000-0000-0000-000000000001', 'ingredient_category', 'protein', 'Protein', array['meat', 'poultry', 'fish', 'seafood', 'tofu', 'legume']),
    ('d0000000-0000-0000-0000-000000000002', 'ingredient_category', 'produce', 'Produce', array['vegetable', 'vegetables', 'fruit', 'greens']),
    ('d0000000-0000-0000-0000-000000000003', 'ingredient_category', 'dairy', 'Dairy', array['cheese', 'milk', 'cream', 'butter', 'yogurt']),
    ('d0000000-0000-0000-0000-000000000004', 'ingredient_category', 'grain', 'Grain', array['pasta', 'rice', 'bread', 'flour', 'cereal']),
    ('d0000000-0000-0000-0000-000000000005', 'ingredient_category', 'herb', 'Herb', array['herbs', 'fresh herbs']),
    ('d0000000-0000-0000-0000-000000000006', 'ingredient_category', 'spice', 'Spice', array['spices', 'seasoning']),
    ('d0000000-0000-0000-0000-000000000007', 'ingredient_category', 'condiment', 'Condiment', array['sauce', 'oil', 'vinegar', 'dressing']),
    ('d0000000-0000-0000-0000-000000000008', 'ingredient_category', 'baking', 'Baking', array['sugar', 'yeast', 'baking powder']),
    ('d0000000-0000-0000-0000-000000000009', 'ingredient_category', 'pantry', 'Pantry', array['canned', 'stock', 'broth', 'nuts', 'seeds']),
    ('d0000000-0000-0000-0000-000000000010', 'ingredient_category', 'other', 'Other', array['miscellaneous'])
on conflict (dimension, slug) do nothing;

-- 4. Alter public.dishes: add taxonomy foreign keys
alter table public.dishes
    add column if not exists cooking_method_id uuid references public.taxonomy_terms (id) on delete set null,
    add column if not exists cuisine_id uuid references public.taxonomy_terms (id) on delete set null;

create index if not exists dishes_cooking_method_idx on public.dishes (cooking_method_id);
create index if not exists dishes_cuisine_idx on public.dishes (cuisine_id);

-- Backfill cuisine_id on dishes from existing cuisine string
update public.dishes d
set cuisine_id = t.id
from public.taxonomy_terms t
where t.dimension = 'cuisine'
  and d.cuisine_id is null
  and d.cuisine is not null
  and (
    t.slug = lower(trim(d.cuisine))
    or t.slug = replace(lower(trim(d.cuisine)), ' ', '_')
    or t.slug = replace(lower(trim(d.cuisine)), '-', '_')
    or lower(trim(d.cuisine)) = any(t.aliases)
    or lower(trim(d.cuisine)) = lower(t.name)
  );

-- Backfill cooking_method_id on dishes from name / instructions
update public.dishes d
set cooking_method_id = t.id
from public.taxonomy_terms t
where t.dimension = 'cooking_method'
  and d.cooking_method_id is null
  and (
    d.normalized_name ilike '%' || t.slug || '%'
    or exists (select 1 from unnest(t.aliases) a where d.normalized_name ilike '%' || a || '%')
    or exists (select 1 from unnest(d.instructions) inst where inst ilike '%' || t.slug || '%' or exists (select 1 from unnest(t.aliases) a where inst ilike '%' || a || '%'))
  );

-- 5. Alter ingredient_vocabulary: remove check constraint and add category_id
alter table public.ingredient_vocabulary
    drop constraint if exists ingredient_vocabulary_category_check;

alter table public.ingredient_vocabulary
    add column if not exists category_id uuid references public.taxonomy_terms (id) on delete set null;

create index if not exists ingredient_vocabulary_category_idx on public.ingredient_vocabulary (category_id);

-- Backfill category_id on ingredient_vocabulary
update public.ingredient_vocabulary iv
set category_id = t.id
from public.taxonomy_terms t
where t.dimension = 'ingredient_category'
  and iv.category_id is null
  and (
    t.slug = lower(trim(iv.category))
    or lower(trim(iv.category)) = any(t.aliases)
  );

-- 6. Drop tags column entirely from public.dishes
alter table public.dishes
    drop column if exists tags;
