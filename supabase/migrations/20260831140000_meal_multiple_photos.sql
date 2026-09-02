-- ===========================================================================
-- Meal Multiple Photos Support
-- ===========================================================================

-- 1. Add photo_paths text[] column
alter table public.meals
    add column if not exists photo_paths text[] not null default '{}';

-- 2. Backfill from legacy single photo_path if exists
update public.meals
   set photo_paths = array[photo_path]
 where photo_path is not null
   and photo_paths = '{}';

-- 3. Keep photo_path in sync as the primary/cover photo for backwards compatibility
create or replace function public.sync_meal_photo_path()
returns trigger
language plpgsql
security definer
as $$
begin
    if array_length(new.photo_paths, 1) > 0 then
        new.photo_path = new.photo_paths[1];
    else
        new.photo_path = null;
    end if;
    return new;
end;
$$;

drop trigger if exists meal_photo_path_sync on public.meals;
create trigger meal_photo_path_sync
    before insert or update of photo_paths on public.meals
    for each row
    execute function public.sync_meal_photo_path();

-- 4. Fix recipe-photos RLS storage policies (qualify storage.objects.name)
drop policy if exists recipe_photos_write on storage.objects;
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

drop policy if exists recipe_photos_delete on storage.objects;
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
