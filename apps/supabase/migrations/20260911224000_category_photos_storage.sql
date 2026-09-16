-- ===========================================================================
-- Category Photos Storage Policies
-- Allows read, insert, update, and delete for category photos under 'categories/'
-- in the 'recipe-photos' storage bucket.
-- ===========================================================================

-- Read: Category photos are publicly viewable
drop policy if exists category_photos_read on storage.objects;
create policy category_photos_read on storage.objects
    for select
    using (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) = 'categories'
    );

-- Write: Authenticated users can upload category photos
drop policy if exists category_photos_write on storage.objects;
create policy category_photos_write on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) = 'categories'
    );

-- Update: Authenticated users can update category photos
drop policy if exists category_photos_update on storage.objects;
create policy category_photos_update on storage.objects
    for update to authenticated
    using (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) = 'categories'
    );

-- Delete: Authenticated users can delete category photos
drop policy if exists category_photos_delete on storage.objects;
create policy category_photos_delete on storage.objects
    for delete to authenticated
    using (
        bucket_id = 'recipe-photos'
        and split_part(name, '/', 1) = 'categories'
    );
