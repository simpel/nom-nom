-- ===========================================================================
-- Dedicated 'category-photos' Storage Bucket & Policies
-- ===========================================================================

-- 1. Create public 'category-photos' storage bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('category-photos', 'category-photos', true, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- 2. Storage policies for 'category-photos'
drop policy if exists category_photos_bucket_read on storage.objects;
create policy category_photos_bucket_read on storage.objects
    for select
    using (bucket_id = 'category-photos');

drop policy if exists category_photos_bucket_insert on storage.objects;
create policy category_photos_bucket_insert on storage.objects
    for insert to authenticated
    with check (bucket_id = 'category-photos');

drop policy if exists category_photos_bucket_update on storage.objects;
create policy category_photos_bucket_update on storage.objects
    for update to authenticated
    using (bucket_id = 'category-photos');

drop policy if exists category_photos_bucket_delete on storage.objects;
create policy category_photos_bucket_delete on storage.objects
    for delete to authenticated
    using (bucket_id = 'category-photos');

-- 3. Migrate any existing category objects from recipe-photos to category-photos bucket
update storage.objects
   set bucket_id = 'category-photos',
       name = regexp_replace(name, '^categories/', '')
 where bucket_id = 'recipe-photos'
   and split_part(name, '/', 1) = 'categories';

-- 4. Update photo_path in public.categories to strip 'categories/' prefix
update public.categories
   set photo_path = regexp_replace(photo_path, '^categories/', '')
 where photo_path like 'categories/%';

-- 5. Drop old storage policies on recipe-photos/categories
drop policy if exists category_photos_read on storage.objects;
drop policy if exists category_photos_write on storage.objects;
drop policy if exists category_photos_update on storage.objects;
drop policy if exists category_photos_delete on storage.objects;

-- 6. Update category photo cleanup trigger for category-photos bucket
create or replace function public.trigger_category_photo_cleanup()
returns trigger
language plpgsql
security definer
set search_path = public, storage, pg_temp
as $$
begin
    set local storage.allow_delete_query = 'true';

    delete from storage.objects
     where bucket_id = 'category-photos'
       and (
           name = old.photo_path
           or name = old.slug || '.jpg'
           or name = 'categories/' || old.slug || '.jpg'
       );

    return old;
end;
$$;
