-- ===========================================================================
-- The generate-recipe-image Edge Function was renamed to generate-dish-photo
-- (it generates both single-recipe and category-spread photographs, so
-- "recipe" was misleading). Point the category photo trigger at the new URL.
-- ===========================================================================

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
        url     := fn_url || '/functions/v1/generate-dish-photo',
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
