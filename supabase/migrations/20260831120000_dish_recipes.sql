-- ===========================================================================
-- Dish Recipes: Text & Photos
-- ===========================================================================

-- 1. Add recipe columns to dishes
alter table public.dishes
    add column if not exists recipe_text text not null default '',
    add column if not exists recipe_photo_paths text[] not null default '{}';

-- 2. Create private recipe-photos storage bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recipe-photos', 'recipe-photos', false, 10485760, array['image/jpeg'])
on conflict (id) do update
    set name              = excluded.name,
        public            = excluded.public,
        file_size_limit   = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- 3. Storage policies for recipe-photos
-- Read: Allowed if user can read the dish
create policy recipe_photos_read on storage.objects
    for select to authenticated
    using (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        and public.can_read_dish(split_part(name, '/', 1)::uuid)
    );

-- Write: Allowed if user is the dish owner
create policy recipe_photos_write on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        and exists (
            select 1 from public.dishes d
             where d.id = split_part(storage.objects.name, '/', 1)::uuid
               and d.owner_id = auth.uid()
        )
    );

-- Delete: Allowed if user is the dish owner
create policy recipe_photos_delete on storage.objects
    for delete to authenticated
    using (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        and exists (
            select 1 from public.dishes d
             where d.id = split_part(storage.objects.name, '/', 1)::uuid
               and d.owner_id = auth.uid()
        )
    );
