-- ===========================================================================
-- Dinner Party Multiple Photos Support
-- ===========================================================================

-- 1. Add photo_paths text[] column
alter table public.parties
    add column if not exists photo_paths text[] not null default '{}';

-- 2. Backfill from the single photo_path
update public.parties
   set photo_paths = array[photo_path]
 where photo_path is not null
   and photo_paths = '{}';

-- 3. Keep photo_path in sync as the cover (used by the party avatar)
create or replace function public.sync_party_photo_path()
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

drop trigger if exists party_photo_path_sync on public.parties;
create trigger party_photo_path_sync
    before insert or update of photo_paths on public.parties
    for each row
    execute function public.sync_party_photo_path();
