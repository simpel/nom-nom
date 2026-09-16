-- ===========================================================================
-- Category Photo Triggers & Automatic Synchronization
-- Automatically triggers Edge Function generation of category photographs via pg_net
-- when categories are created, and cleans up images from storage on deletion.
-- ===========================================================================

create extension if not exists pg_net with schema extensions;

-- 1. Trigger to invoke generate-recipe-image Edge Function for categories without photos
create or replace function public.trigger_category_photo_generation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    fn_url text;
    secret text;
begin
    -- Only generate if photo_path is currently NULL
    if new.photo_path is not null then
        return new;
    end if;

    select decrypted_secret into fn_url
      from vault.decrypted_secrets
     where name = 'project_url';

    select decrypted_secret into secret
      from vault.decrypted_secrets
     where name = 'webhook_secret';

    if fn_url is null or secret is null then
        return new;
    end if;

    perform net.http_post(
        url     := fn_url || '/functions/v1/generate-recipe-image',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      TG_OP,
                       'table',     'categories',
                       'schema',    'public',
                       'record',    to_jsonb(new)
                   ),
        timeout_milliseconds := 60000
    );

    return new;
end;
$$;

drop trigger if exists category_photo_generate_trigger on public.categories;
create trigger category_photo_generate_trigger
    after insert or update of name, slug, photo_path on public.categories
    for each row
    execute function public.trigger_category_photo_generation();

-- 2. Trigger to clean up storage image when a category is deleted
create or replace function public.trigger_category_photo_cleanup()
returns trigger
language plpgsql
security definer
set search_path = public, storage, pg_temp
as $$
begin
    set local storage.allow_delete_query = 'true';

    delete from storage.objects
     where bucket_id = 'recipe-photos'
       and (
           name = old.photo_path
           or name = 'categories/' || old.slug || '.jpg'
       );

    return old;
end;
$$;

drop trigger if exists category_photo_cleanup_trigger on public.categories;
create trigger category_photo_cleanup_trigger
    after delete on public.categories
    for each row
    execute function public.trigger_category_photo_cleanup();

-- 3. Trigger on dishes to automatically register custom cuisines in public.categories
create or replace function public.sync_dish_cuisines_to_categories()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_part text;
    v_slug text;
begin
    if new.cuisine is not null and trim(new.cuisine) != '' then
        foreach v_part in array string_to_array(new.cuisine, ',') loop
            v_part := trim(v_part);
            if v_part != '' then
                v_slug := lower(regexp_replace(v_part, '[^a-zA-Z0-9]+', '-', 'g'));
                v_slug := trim(both '-' from v_slug);
                if v_slug != '' and not exists (select 1 from public.categories where slug = v_slug) then
                    insert into public.categories (slug, name)
                    values (v_slug, initcap(v_part))
                    on conflict (slug) do nothing;
                end if;
            end if;
        end loop;
    end if;
    return new;
end;
$$;

drop trigger if exists dish_cuisines_sync_categories_trigger on public.dishes;
create trigger dish_cuisines_sync_categories_trigger
    after insert or update of cuisine on public.dishes
    for each row
    execute function public.sync_dish_cuisines_to_categories();
