create table if not exists public.party_insights (
    id                  uuid primary key default gen_random_uuid(),
    party_id            uuid not null references public.parties (id) on delete cascade unique,
    summary_sentence    text,
    food_profile        text,
    recommendations     jsonb not null default '[]'::jsonb,
    updated_at          timestamptz not null default now()
);

alter table public.party_insights enable row level security;

create policy party_insights_select on public.party_insights
    for select to authenticated using (
        party_id in (
            select party_id from public.party_members where user_id = auth.uid()
        )
        or party_id in (
            select id from public.parties where created_by = auth.uid()
        )
        or party_id in (
            select id from public.parties where is_public = true
        )
    );

create or replace function public.touch_party_updated_at()
returns trigger as $$
begin
    update public.parties set updated_at = now() where id = coalesce(NEW.party_id, OLD.party_id);
    return null;
end;
$$ language plpgsql security definer;

drop trigger if exists touch_party_on_member_change on public.party_members;
create trigger touch_party_on_member_change
    after insert or update or delete on public.party_members
    for each row execute function public.touch_party_updated_at();

drop trigger if exists touch_party_on_meal_party_change on public.meal_parties;
create trigger touch_party_on_meal_party_change
    after insert or update or delete on public.meal_parties
    for each row execute function public.touch_party_updated_at();

create or replace function public.touch_party_on_meal_change()
returns trigger as $$
begin
    update public.parties
    set updated_at = now()
    where id in (
        select party_id from public.meal_parties
        where meal_id = coalesce(NEW.id, OLD.id)
    );
    return null;
end;
$$ language plpgsql security definer;

drop trigger if exists touch_party_on_meal_change on public.meals;
create trigger touch_party_on_meal_change
    after insert or update or delete on public.meals
    for each row execute function public.touch_party_on_meal_change();

create or replace function public.touch_party_on_rating_change()
returns trigger as $$
begin
    update public.parties
    set updated_at = now()
    where id in (
        select party_id from public.meal_parties
        where meal_id = coalesce(NEW.meal_id, OLD.meal_id)
    );
    return null;
end;
$$ language plpgsql security definer;

drop trigger if exists touch_party_on_rating_change on public.meal_ratings;
create trigger touch_party_on_rating_change
    after insert or update or delete on public.meal_ratings
    for each row execute function public.touch_party_on_rating_change();
