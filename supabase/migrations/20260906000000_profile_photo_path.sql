-- ===========================================================================
-- User Profile Avatar Photo Support
-- ===========================================================================

-- 1. Add photo_path column to public.profiles
alter table public.profiles
    add column if not exists photo_path text;

-- 2. Create private profile-photos storage bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-photos', 'profile-photos', false, 10485760, array['image/jpeg', 'image/png'])
on conflict (id) do update
    set name              = excluded.name,
        public            = excluded.public,
        file_size_limit   = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- 3. Storage policies for profile-photos
drop policy if exists profile_photos_read on storage.objects;
create policy profile_photos_read on storage.objects
    for select to authenticated
    using (bucket_id = 'profile-photos');

drop policy if exists profile_photos_write on storage.objects;
create policy profile_photos_write on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'profile-photos'
        and split_part(name, '/', 1) = auth.uid()::text
    );

drop policy if exists profile_photos_update on storage.objects;
create policy profile_photos_update on storage.objects
    for update to authenticated
    using (
        bucket_id = 'profile-photos'
        and split_part(name, '/', 1) = auth.uid()::text
    );

drop policy if exists profile_photos_delete on storage.objects;
create policy profile_photos_delete on storage.objects
    for delete to authenticated
    using (
        bucket_id = 'profile-photos'
        and split_part(name, '/', 1) = auth.uid()::text
    );
