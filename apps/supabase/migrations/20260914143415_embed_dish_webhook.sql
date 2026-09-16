create function public.embed_dish_on_change()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
as $$
declare
    fn_url text;
    secret text;
begin
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
        url     := fn_url || '/functions/v1/embed-dish',
        headers := jsonb_build_object(
                       'Content-Type',     'application/json',
                       'x-webhook-secret', secret
                   ),
        body    := jsonb_build_object(
                       'type',      TG_OP,
                       'table',     'dishes',
                       'schema',    'public',
                       'record',    to_jsonb(new),
                       'old_record', to_jsonb(old)
                   ),
        timeout_milliseconds := 5000
    );

    return new;
end;
$$;

create trigger embed_dish_webhook
    after insert or update on public.dishes
    for each row
    execute function public.embed_dish_on_change();
