-- ===========================================================================
-- Nom Nom Database Seed: 3 Dinner Parties, 40 Recipes, 58 Meals & Ratings
-- ===========================================================================

-- 1. Local Vault Secrets
do $$
begin
    if not exists (select 1 from vault.secrets where name = 'project_url') then
        perform vault.create_secret(
            'http://api.supabase.internal:8000',
            'project_url',
            'Base URL this environment reaches its own Edge Functions on.'
        );
    end if;
    if not exists (select 1 from vault.secrets where name = 'webhook_secret') then
        perform vault.create_secret(
            'local-development-webhook-secret',
            'webhook_secret',
            'Shared secret sent as x-webhook-secret; must match the WEBHOOK_SECRET the Edge Function holds.'
        );
    end if;
end $$;

-- 2. Auth Users & Profiles (10 Members total, dev password: nomnom-dev-password)
insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'f917e487-1f8c-4d3c-b42a-d77f1c19bceb',
    'authenticated',
    'authenticated',
    'cook@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Joel", "last_name": "Sanden", "full_name": "Joel Sanden", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-d455f6af9cea',
    'f917e487-1f8c-4d3c-b42a-d77f1c19bceb',
    'f917e487-1f8c-4d3c-b42a-d77f1c19bceb',
    jsonb_build_object('sub', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'email', 'cook@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Joel', 'Sanden', 'Joel Sanden')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

-- Apple App Review & Demo test account (Password: NomNomAppleReview2025!)
insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    email_change_confirm_status, created_at, updated_at
) values (
    '00000000-0000-0000-0000-000000000000',
    'e0000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'app@nomnom.casa',
    '$2a$10$B/C2sWlVWr5GPQKP3BVN8ujZMddC7V7laP5jx5bgQEBgm./xkfq8W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Test", "last_name": "Account", "full_name": "Test Account", "email_verified": true}'::jsonb,
    false,
    false,
    '', '', '', '', '', '', '', '', 0, now(), now()
) on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'e0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001',
    jsonb_build_object('sub', 'e0000000-0000-0000-0000-000000000001', 'email', 'app@nomnom.casa', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('e0000000-0000-0000-0000-000000000001', 'Test', 'Account', 'Test Account')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'a1111111-1111-1111-1111-111111111111',
    'authenticated',
    'authenticated',
    'astrid.lind@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Astrid", "last_name": "Lind", "full_name": "Astrid Lind", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-a11111111111',
    'a1111111-1111-1111-1111-111111111111',
    'a1111111-1111-1111-1111-111111111111',
    jsonb_build_object('sub', 'a1111111-1111-1111-1111-111111111111', 'email', 'astrid.lind@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('a1111111-1111-1111-1111-111111111111', 'Astrid', 'Lind', 'Astrid Lind')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'a2222222-2222-2222-2222-222222222222',
    'authenticated',
    'authenticated',
    'marcus.berg@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Marcus", "last_name": "Berg", "full_name": "Marcus Berg", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-a22222222222',
    'a2222222-2222-2222-2222-222222222222',
    'a2222222-2222-2222-2222-222222222222',
    jsonb_build_object('sub', 'a2222222-2222-2222-2222-222222222222', 'email', 'marcus.berg@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('a2222222-2222-2222-2222-222222222222', 'Marcus', 'Berg', 'Marcus Berg')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'a3333333-3333-3333-3333-333333333333',
    'authenticated',
    'authenticated',
    'sofia.ek@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Sofia", "last_name": "Ek", "full_name": "Sofia Ek", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-a33333333333',
    'a3333333-3333-3333-3333-333333333333',
    'a3333333-3333-3333-3333-333333333333',
    jsonb_build_object('sub', 'a3333333-3333-3333-3333-333333333333', 'email', 'sofia.ek@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('a3333333-3333-3333-3333-333333333333', 'Sofia', 'Ek', 'Sofia Ek')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'b1111111-1111-1111-1111-111111111111',
    'authenticated',
    'authenticated',
    'elena.rostova@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Elena", "last_name": "Rostova", "full_name": "Elena Rostova", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-b11111111111',
    'b1111111-1111-1111-1111-111111111111',
    'b1111111-1111-1111-1111-111111111111',
    jsonb_build_object('sub', 'b1111111-1111-1111-1111-111111111111', 'email', 'elena.rostova@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('b1111111-1111-1111-1111-111111111111', 'Elena', 'Rostova', 'Elena Rostova')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'b2222222-2222-2222-2222-222222222222',
    'authenticated',
    'authenticated',
    'leo.larsson@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Leo", "last_name": "Larsson", "full_name": "Leo Larsson", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-b22222222222',
    'b2222222-2222-2222-2222-222222222222',
    'b2222222-2222-2222-2222-222222222222',
    jsonb_build_object('sub', 'b2222222-2222-2222-2222-222222222222', 'email', 'leo.larsson@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('b2222222-2222-2222-2222-222222222222', 'Leo', 'Larsson', 'Leo Larsson')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'b3333333-3333-3333-3333-333333333333',
    'authenticated',
    'authenticated',
    'clara.wallin@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Clara", "last_name": "Wallin", "full_name": "Clara Wallin", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-b33333333333',
    'b3333333-3333-3333-3333-333333333333',
    'b3333333-3333-3333-3333-333333333333',
    jsonb_build_object('sub', 'b3333333-3333-3333-3333-333333333333', 'email', 'clara.wallin@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('b3333333-3333-3333-3333-333333333333', 'Clara', 'Wallin', 'Clara Wallin')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'c1111111-1111-1111-1111-111111111111',
    'authenticated',
    'authenticated',
    'liam.nilsson@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Liam", "last_name": "Nilsson", "full_name": "Liam Nilsson", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-c11111111111',
    'c1111111-1111-1111-1111-111111111111',
    'c1111111-1111-1111-1111-111111111111',
    jsonb_build_object('sub', 'c1111111-1111-1111-1111-111111111111', 'email', 'liam.nilsson@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('c1111111-1111-1111-1111-111111111111', 'Liam', 'Nilsson', 'Liam Nilsson')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'c2222222-2222-2222-2222-222222222222',
    'authenticated',
    'authenticated',
    'maya.holm@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Maya", "last_name": "Holm", "full_name": "Maya Holm", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-c22222222222',
    'c2222222-2222-2222-2222-222222222222',
    'c2222222-2222-2222-2222-222222222222',
    jsonb_build_object('sub', 'c2222222-2222-2222-2222-222222222222', 'email', 'maya.holm@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('c2222222-2222-2222-2222-222222222222', 'Maya', 'Holm', 'Maya Holm')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000',
    'c3333333-3333-3333-3333-333333333333',
    'authenticated',
    'authenticated',
    'oliver.strand@foodlog.test',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W',
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "Oliver", "last_name": "Strand", "full_name": "Oliver Strand", "email_verified": true}'::jsonb,
    false,
    false
) on conflict (id) do update set
    raw_user_meta_data = excluded.raw_user_meta_data,
    email = excluded.email;

insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
    'cac26331-22f2-4c3b-a146-c33333333333',
    'c3333333-3333-3333-3333-333333333333',
    'c3333333-3333-3333-3333-333333333333',
    jsonb_build_object('sub', 'c3333333-3333-3333-3333-333333333333', 'email', 'oliver.strand@foodlog.test', 'email_verified', true),
    'email',
    now(),
    now(),
    now()
) on conflict (id) do nothing;

insert into public.profiles (id, first_name, last_name, display_name)
values ('c3333333-3333-3333-3333-333333333333', 'Oliver', 'Strand', 'Oliver Strand')
on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name;

-- Ensure auth.users tokens and timestamps satisfy GoTrue non-null scan expectations
update auth.users
set confirmation_token = coalesce(confirmation_token, ''),
    recovery_token = coalesce(recovery_token, ''),
    email_change_token_new = coalesce(email_change_token_new, ''),
    email_change = coalesce(email_change, ''),
    phone_change = coalesce(phone_change, ''),
    phone_change_token = coalesce(phone_change_token, ''),
    reauthentication_token = coalesce(reauthentication_token, ''),
    email_change_token_current = coalesce(email_change_token_current, ''),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now());

-- 3. Clean up any existing sample test parties, meals, and dishes
-- Remove orphan test parties, meals, and dishes not in our seed list
delete from public.parties where id not in (
    'd1111111-1111-1111-1111-111111111111',
    'd2222222-2222-2222-2222-222222222222',
    'd3333333-3333-3333-3333-333333333333',
    'd4444444-4444-4444-4444-444444444444',
    'd5555555-5555-5555-5555-555555555555'
);
delete from public.meals where id::text not like 'ba000000-%';
delete from public.dishes where id::text not like 'e0000000-%';

-- 4. 5 Dinner Parties, Members & Followers
-- Party 1: The Friday Feast Club (Public, Joel is creator & member)
insert into public.parties (id, name, about, is_public, created_by)
values (
    'd1111111-1111-1111-1111-111111111111',
    'The Friday Feast Club',
    'A weekly gathering of home cooks exploring rustic and elevated dinners every Friday night.',
    true,
    'f917e487-1f8c-4d3c-b42a-d77f1c19bceb'
)
on conflict (id) do update set
    name = excluded.name,
    about = excluded.about,
    is_public = excluded.is_public;

insert into public.party_members (party_id, user_id)
values ('d1111111-1111-1111-1111-111111111111', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d1111111-1111-1111-1111-111111111111', 'a2222222-2222-2222-2222-222222222222')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d1111111-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d1111111-1111-1111-1111-111111111111', 'e0000000-0000-0000-0000-000000000001')
on conflict (party_id, user_id) do nothing;

-- Party 2: Sunday Supper Society (Public, Joel is creator & member)
insert into public.parties (id, name, about, is_public, created_by)
values (
    'd2222222-2222-2222-2222-222222222222',
    'Sunday Supper Society',
    'Slow-simmered comfort meals, family roasts, and shared desserts to wind down the weekend.',
    true,
    'f917e487-1f8c-4d3c-b42a-d77f1c19bceb'
)
on conflict (id) do update set
    name = excluded.name,
    about = excluded.about,
    is_public = excluded.is_public;

insert into public.party_members (party_id, user_id)
values ('d2222222-2222-2222-2222-222222222222', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d2222222-2222-2222-2222-222222222222', 'b1111111-1111-1111-1111-111111111111')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d2222222-2222-2222-2222-222222222222', 'b2222222-2222-2222-2222-222222222222')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d2222222-2222-2222-2222-222222222222', 'b3333333-3333-3333-3333-333333333333')
on conflict (party_id, user_id) do nothing;

-- Party 3: Taco & Tapas Crew (Private, Joel is creator & member)
insert into public.parties (id, name, about, is_public, created_by)
values (
    'd3333333-3333-3333-3333-333333333333',
    'Taco & Tapas Crew',
    'Private family crew rotating tacos, pintxos, and street food favorites.',
    false,
    'f917e487-1f8c-4d3c-b42a-d77f1c19bceb'
)
on conflict (id) do update set
    name = excluded.name,
    about = excluded.about,
    is_public = excluded.is_public;

insert into public.party_members (party_id, user_id)
values ('d3333333-3333-3333-3333-333333333333', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d3333333-3333-3333-3333-333333333333', 'c1111111-1111-1111-1111-111111111111')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d3333333-3333-3333-3333-333333333333', 'c2222222-2222-2222-2222-222222222222')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d3333333-3333-3333-3333-333333333333', 'c3333333-3333-3333-3333-333333333333')
on conflict (party_id, user_id) do nothing;

-- Party 4: Pasta & Vino Society (Public, Astrid is creator; Joel is a FOLLOWER, not member)
insert into public.parties (id, name, about, is_public, created_by)
values (
    'd4444444-4444-4444-4444-444444444444',
    'Pasta & Vino Society',
    'Handmade semolina pasta, slow-cooked sugo, and natural wine pairings every Saturday.',
    true,
    'a1111111-1111-1111-1111-111111111111'
)
on conflict (id) do update set
    name = excluded.name,
    about = excluded.about,
    is_public = excluded.is_public;

insert into public.party_members (party_id, user_id)
values ('d4444444-4444-4444-4444-444444444444', 'a1111111-1111-1111-1111-111111111111')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d4444444-4444-4444-4444-444444444444', 'a2222222-2222-2222-2222-222222222222')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d4444444-4444-4444-4444-444444444444', 'a3333333-3333-3333-3333-333333333333')
on conflict (party_id, user_id) do nothing;

-- Party 5: Nordic Hearth & Ferments (Public, Björn is creator; discoverable by Joel)
insert into public.parties (id, name, about, is_public, created_by)
values (
    'd5555555-5555-5555-5555-555555555555',
    'Nordic Hearth & Ferments',
    'Wood-fired cooking, wild game, pickling, and seasonal Scandinavian forest foraging.',
    true,
    'b1111111-1111-1111-1111-111111111111'
)
on conflict (id) do update set
    name = excluded.name,
    about = excluded.about,
    is_public = excluded.is_public;

insert into public.party_members (party_id, user_id)
values ('d5555555-5555-5555-5555-555555555555', 'b1111111-1111-1111-1111-111111111111')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d5555555-5555-5555-5555-555555555555', 'b2222222-2222-2222-2222-222222222222')
on conflict (party_id, user_id) do nothing;

insert into public.party_members (party_id, user_id)
values ('d5555555-5555-5555-5555-555555555555', 'b3333333-3333-3333-3333-333333333333')
on conflict (party_id, user_id) do nothing;

-- Seed Party Followers
-- Joel follows Pasta & Vino Society
insert into public.party_followers (party_id, user_id)
values ('d4444444-4444-4444-4444-444444444444', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb')
on conflict (party_id, user_id) do nothing;

-- Björn follows The Friday Feast Club
insert into public.party_followers (party_id, user_id)
values ('d1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111')
on conflict (party_id, user_id) do nothing;


-- 5. 40 Recipes across 13 cuisines
insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000001', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Classic Margherita Pizza', 'margherita pizza', array['pizza', 'classic', 'vegetarian'], 'italian', 2, true,
    '[{"quantity": "500", "measurement": "g", "ingredient": "pizza flour (Tipo 00)"}, {"quantity": "325", "measurement": "ml", "ingredient": "warm water"}, {"quantity": "3", "measurement": "g", "ingredient": "dry yeast"}, {"quantity": "10", "measurement": "g", "ingredient": "salt"}, {"quantity": "400", "measurement": "g", "ingredient": "San Marzano tomatoes, crushed"}, {"quantity": "250", "measurement": "g", "ingredient": "fresh mozzarella"}, {"quantity": "", "measurement": "", "ingredient": "Fresh basil leaves & extra virgin olive oil"}]'::jsonb,
    array['Combine flour, water, yeast, and salt. Knead for 10 min until smooth. Proof for 8-24 hours.', 'Stretch dough into thin rounds.', 'Spread seasoned tomato sauce, top with torn mozzarella.', 'Bake at 250°C (or pizza oven at 450°C) until blistered and bubbling.', 'Finish with fresh basil and a drizzle of olive oil.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000002', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Creamy Tagliatelle Carbonara', 'tagliatelle carbonara', array['pasta', 'classic', 'comfort-food', 'quick'], 'italian', 1, true,
    '[{"quantity": "400", "measurement": "g", "ingredient": "fresh tagliatelle"}, {"quantity": "200", "measurement": "g", "ingredient": "guanciale (or pancetta), diced"}, {"quantity": "4", "measurement": "", "ingredient": "egg yolks + 1 whole egg"}, {"quantity": "80", "measurement": "g", "ingredient": "Pecorino Romano, freshly grated"}, {"quantity": "", "measurement": "", "ingredient": "Freshly cracked black pepper"}]'::jsonb,
    array['Crisp guanciale in a wide skillet over medium heat until golden. Remove from heat.', 'Whisk egg yolks, whole egg, grated Pecorino, and abundant black pepper into a smooth paste.', 'Boil tagliatelle in salted water until al dente.', 'Toss hot pasta with guanciale and a ladle of starchy pasta water.', 'Remove skillet from heat, stir in egg mixture quickly to form a creamy, glossy emulsion.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000003', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Slow-Cooked Bolognese Ragu', 'bolognese ragu', array['pasta', 'slow-cook', 'comfort-food'], 'italian', 3, true,
    '[{"quantity": "500", "measurement": "g", "ingredient": "ground beef chuck & 250g ground pork"}, {"quantity": "1", "measurement": "", "ingredient": "finely diced onion, carrot, and celery stalk"}, {"quantity": "150", "measurement": "g", "ingredient": "diced pancetta"}, {"quantity": "200", "measurement": "ml", "ingredient": "dry white wine"}, {"quantity": "200", "measurement": "ml", "ingredient": "whole milk"}, {"quantity": "600", "measurement": "g", "ingredient": "canned crushed tomatoes"}, {"quantity": "", "measurement": "", "ingredient": "Salt, pepper & fresh nutmeg"}]'::jsonb,
    array['Brown pancetta in a heavy Dutch oven, then soften soffritto vegetables.', 'Brown minced meats breaking up clumps.', 'Pour in white wine and simmer until evaporated.', 'Add milk and simmer until absorbed.', 'Stir in tomatoes, cover loosely, and simmer on lowest heat for 3-4 hours until dark, velvety, and rich.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000004', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Fresh Basil Pesto Penne', 'basil pesto penne', array['pasta', 'quick', 'vegetarian'], 'italian', 0, true,
    '[{"quantity": "400", "measurement": "g", "ingredient": "penne rigate"}, {"quantity": "2", "measurement": "large bunches", "ingredient": "fresh basil"}, {"quantity": "50", "measurement": "g", "ingredient": "toasted pine nuts"}, {"quantity": "60", "measurement": "g", "ingredient": "Parmigiano-Reggiano"}, {"quantity": "1", "measurement": "", "ingredient": "garlic clove"}, {"quantity": "100", "measurement": "ml", "ingredient": "cold-pressed extra virgin olive oil"}, {"quantity": "", "measurement": "", "ingredient": "Flaky sea salt"}]'::jsonb,
    array['Pound garlic, pine nuts, and salt into a coarse paste in a mortar or pulse in a food processor.', 'Add basil leaves and gently crush.', 'Fold in grated parmesan and stream in olive oil until emulsified.', 'Boil penne until al dente. Toss warm pasta with pesto and a splash of cooking water.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000005', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Wild Mushroom & Truffle Risotto', 'wild mushroom risotto', array['risotto', 'vegetarian', 'special-occasion'], 'italian', 2, true,
    '[{"quantity": "350", "measurement": "g", "ingredient": "Carnaroli or Arborio rice"}, {"quantity": "300", "measurement": "g", "ingredient": "mixed wild mushrooms (chanterelles, cremini, porcini)"}, {"quantity": "1", "measurement": "liter", "ingredient": "rich vegetable or chicken broth"}, {"quantity": "1", "measurement": "", "ingredient": "shallot, minced"}, {"quantity": "150", "measurement": "ml", "ingredient": "dry white wine"}, {"quantity": "50", "measurement": "g", "ingredient": "unsalted butter & 60g Parmigiano"}, {"quantity": "", "measurement": "", "ingredient": "Truffle oil to finish"}]'::jsonb,
    array['Sauté sliced mushrooms in olive oil until golden; set aside.', 'Sweat shallots in butter, add rice and toast 2 minutes until translucent.', 'Deglaze with white wine.', 'Add hot stock ladle by ladle, stirring steadily until rice is creamy and tender (approx. 18 min).', 'Mantecare: stir in butter, parmesan, sautéed mushrooms, and drizzle with truffle oil.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000006', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Birria Beef Tacos', 'birria beef tacos', array['tacos', 'slow-cook', 'mexican', 'crowd-pleaser'], 'mexican', 3, true,
    '[{"quantity": "1", "measurement": "kg", "ingredient": "beef chuck roast"}, {"quantity": "4", "measurement": "", "ingredient": "dried guajillo & 2 ancho chiles, stemmed and seeded"}, {"quantity": "1", "measurement": "", "ingredient": "onion, 4 garlic cloves, 1 cinnamon stick, Mexican oregano"}, {"quantity": "500", "measurement": "ml", "ingredient": "beef broth"}, {"quantity": "", "measurement": "", "ingredient": "Corn tortillas & Oaxaca cheese"}, {"quantity": "", "measurement": "", "ingredient": "Diced white onion & cilantro"}]'::jsonb,
    array['Toast and soak chiles, then blend with roasted onion, garlic, spices, and broth into a smooth adobo.', 'Sear beef chuck roast in a Dutch oven, pour over chile broth.', 'Braise covered at 150°C for 3.5 hours until falling apart tender.', 'Shred beef. Dip corn tortillas in braising fat, sear on flat grill with cheese and shredded beef.', 'Fold crisp tacos and serve with bowls of hot consommé for dipping.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000007', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Baja Crispy Fish Tacos', 'baja fish tacos', array['tacos', 'seafood', 'summer', 'mexican'], 'mexican', 2, true,
    '[{"quantity": "500", "measurement": "g", "ingredient": "firm white fish fillets (cod or mahi-mahi)"}, {"quantity": "150", "measurement": "g", "ingredient": "flour, 1 tsp baking powder, Mexican spices"}, {"quantity": "200", "measurement": "ml", "ingredient": "cold lager beer"}, {"quantity": "", "measurement": "", "ingredient": "Shredded red cabbage & lime juice"}, {"quantity": "", "measurement": "", "ingredient": "Chipotle crema: sour cream, adobo, lime, garlic"}, {"quantity": "", "measurement": "", "ingredient": "Small corn tortillas"}]'::jsonb,
    array['Whisk beer into flour and spices to make a crisp batter.', 'Toss cabbage with lime juice and salt.', 'Dip fish strips into batter and fry in hot oil (180°C) until deep golden and crunchy (3-4 min).', 'Warm tortillas on a dry skillet.', 'Assemble tacos with crispy fish, lime slaw, and smoky chipotle crema drizzle.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000008', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Smoky Chicken Tinga Bowls', 'chicken tinga bowls', array['chicken', 'mexican', 'bowls'], 'mexican', 2, true,
    '[{"quantity": "600", "measurement": "g", "ingredient": "chicken breasts or thighs, poached and shredded"}, {"quantity": "1", "measurement": "can", "ingredient": "chipotle peppers in adobo"}, {"quantity": "400", "measurement": "g", "ingredient": "fire-roasted crushed tomatoes"}, {"quantity": "1", "measurement": "", "ingredient": "sliced onion & 2 minced garlic cloves"}, {"quantity": "", "measurement": "", "ingredient": "Warm cilantro-lime rice"}, {"quantity": "", "measurement": "", "ingredient": "Black beans, avocado slices, and cotija cheese"}]'::jsonb,
    array['Blend tomatoes, chipotles, garlic, and Mexican oregano until smooth.', 'Sauté sliced onions in oil until caramelized and soft.', 'Pour in tinga sauce and simmer 10 minutes.', 'Stir in shredded chicken and cook until sauce coats the meat richly.', 'Serve over cilantro-lime rice topped with black beans, fresh avocado, and crumbled cotija.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000009', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Black Bean & Corn Enchiladas', 'black bean enchiladas', array['enchiladas', 'vegetarian', 'mexican'], 'mexican', 2, true,
    '[{"quantity": "12", "measurement": "", "ingredient": "small corn tortillas"}, {"quantity": "2", "measurement": "cans", "ingredient": "black beans, rinsed"}, {"quantity": "200", "measurement": "g", "ingredient": "sweet corn kernels"}, {"quantity": "1", "measurement": "bunch", "ingredient": "scallions & 1 tsp cumin"}, {"quantity": "400", "measurement": "ml", "ingredient": "red enchilada sauce"}, {"quantity": "200", "measurement": "g", "ingredient": "Monterey Jack and Cheddar cheese"}]'::jsonb,
    array['Warm enchilada sauce in a skillet. Briefly dip tortillas to soften.', 'Mix black beans, corn, scallions, cumin, and half the cheese.', 'Roll filling tightly inside tortillas and arrange seam-side down in a baking dish.', 'Pour remaining sauce over top and cover with remaining shredded cheese.', 'Bake at 190°C for 20-25 minutes until bubbly and edges are crisp.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000010', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Authentic Guacamole & Fresh Pico', 'guacamole and pico', array['dip', 'quick', 'fresh', 'vegetarian'], 'mexican', 0, true,
    '[{"quantity": "4", "measurement": "", "ingredient": "ripe Hass avocados"}, {"quantity": "4", "measurement": "", "ingredient": "ripe plum tomatoes, diced"}, {"quantity": "1", "measurement": "", "ingredient": "small red onion, finely chopped"}, {"quantity": "1", "measurement": "", "ingredient": "jalapeño, seeded and minced"}, {"quantity": "1", "measurement": "", "ingredient": "large bunch fresh cilantro, chopped"}, {"quantity": "3", "measurement": "", "ingredient": "juicy limes & flaky sea salt"}, {"quantity": "", "measurement": "", "ingredient": "Crispy tortilla chips"}]'::jsonb,
    array['For pico de gallo: toss diced tomatoes, red onion, jalapeño, half the cilantro, lime juice, and salt.', 'Mash avocados coarsely with a fork leaving chunks.', 'Fold lime juice, salt, and remaining cilantro into avocado.', 'Top guacamole with a spoonful of fresh pico.', 'Serve immediately with warm tortilla chips.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000011', 'a1111111-1111-1111-1111-111111111111', 'Swedish Meatballs with Cream Sauce', 'swedish meatballs', array['meatballs', 'nordic', 'comfort-food', 'classic'], 'nordic', 2, true,
    '[{"quantity": "300", "measurement": "g", "ingredient": "ground beef & 300g ground pork"}, {"quantity": "1", "measurement": "", "ingredient": "onion, finely grated and sweated"}, {"quantity": "50", "measurement": "g", "ingredient": "breadcrumbs soaked in 100ml cream"}, {"quantity": "1", "measurement": "", "ingredient": "egg, allspice, white pepper & salt"}, {"quantity": "", "measurement": "", "ingredient": "Cream sauce: butter, flour, beef stock, heavy cream, soy sauce"}, {"quantity": "", "measurement": "", "ingredient": "Boiled buttery potatoes & stirred lingonberries"}]'::jsonb,
    array['Combine meats, soaked breadcrumbs, egg, grated onion, and spices. Roll into small meatballs.', 'Fry in butter over medium-high heat until deeply browned and cooked through. Remove.', 'Deglaze skillet with beef stock, whisk in flour/butter roux and heavy cream. Simmer until velvety.', 'Return meatballs to the sauce.', 'Serve with silky mashed potatoes, pickled cucumbers, and tart lingonberries.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000012', 'a1111111-1111-1111-1111-111111111111', 'Pan-Seared Salmon with Dill Potatoes', 'salmon with dill potatoes', array['salmon', 'seafood', 'nordic', 'healthy'], 'nordic', 1, true,
    '[{"quantity": "4", "measurement": "", "ingredient": "skin-on fresh salmon fillets"}, {"quantity": "600", "measurement": "g", "ingredient": "baby new potatoes"}, {"quantity": "1", "measurement": "", "ingredient": "large bunch fresh dill, chopped"}, {"quantity": "50", "measurement": "g", "ingredient": "butter"}, {"quantity": "1", "measurement": "", "ingredient": "lemon, halved"}, {"quantity": "", "measurement": "", "ingredient": "Flaky sea salt & cracked black pepper"}]'::jsonb,
    array['Boil baby potatoes in salted water until fork-tender (15 min). Drain and toss with butter and dill.', 'Season salmon skin with sea salt.', 'Sear salmon skin-side down in a hot pan for 4-5 min until skin is shatteringly crisp.', 'Flip and cook 1-2 min until center is tender and just translucent.', 'Squeeze fresh lemon juice over fillets and serve with warm dill potatoes.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000013', 'a1111111-1111-1111-1111-111111111111', 'Creamy Chanterelle Mushroom Toast', 'chanterelle toast', array['toast', 'mushrooms', 'quick', 'autumn'], 'nordic', 0, true,
    '[{"quantity": "300", "measurement": "g", "ingredient": "fresh wild chanterelles, cleaned"}, {"quantity": "2", "measurement": "", "ingredient": "thick slices sourdough country bread"}, {"quantity": "40", "measurement": "g", "ingredient": "butter"}, {"quantity": "1", "measurement": "", "ingredient": "shallot, minced"}, {"quantity": "75", "measurement": "ml", "ingredient": "heavy cream"}, {"quantity": "", "measurement": "", "ingredient": "Fresh parsley, salt & white pepper"}]'::jsonb,
    array['Dry sauté chanterelles in a hot skillet until liquid evaporates.', 'Add butter and minced shallot; sauté until mushrooms are golden and aromatic.', 'Pour in heavy cream and simmer until reduced to a rich coating.', 'Toast thick sourdough slices in butter until golden.', 'Spoon creamed chanterelles generously over toasts and garnish with fresh parsley.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000014', 'a2222222-2222-2222-2222-222222222222', 'Yellow Thai Coconut Chicken Curry', 'yellow coconut curry', array['curry', 'thai', 'chicken', 'comfort-food'], 'thai', 1, true,
    '[{"quantity": "500", "measurement": "g", "ingredient": "chicken thighs, sliced"}, {"quantity": "3", "measurement": "tbsp", "ingredient": "yellow Thai curry paste"}, {"quantity": "1", "measurement": "can", "ingredient": "(400ml) full-fat coconut milk"}, {"quantity": "200", "measurement": "g", "ingredient": "baby potatoes, quartered"}, {"quantity": "1", "measurement": "", "ingredient": "red bell pepper & 1 onion, chopped"}, {"quantity": "1", "measurement": "tbsp", "ingredient": "fish sauce & 1 tbsp palm sugar"}, {"quantity": "", "measurement": "", "ingredient": "Fresh Thai basil & jasmine rice"}]'::jsonb,
    array['Fry curry paste in 2 tbsp coconut cream until fragrant and oil begins to separate.', 'Add sliced chicken thighs and sear lightly.', 'Pour in remaining coconut milk, potatoes, and onion. Simmer 15 min until potatoes are tender.', 'Add bell peppers, fish sauce, and palm sugar. Cook 3 more minutes.', 'Stir in Thai basil leaves and ladle over steamed fragrant jasmine rice.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000015', 'a2222222-2222-2222-2222-222222222222', 'Pad Thai with Tiger Prawns', 'pad thai prawns', array['noodles', 'thai', 'seafood', 'quick'], 'thai', 1, true,
    '[{"quantity": "250", "measurement": "g", "ingredient": "flat rice noodles (soak 30 min in warm water)"}, {"quantity": "200", "measurement": "g", "ingredient": "peeled tiger prawns"}, {"quantity": "2", "measurement": "", "ingredient": "eggs, lightly beaten"}, {"quantity": "100", "measurement": "g", "ingredient": "firm tofu, cubed"}, {"quantity": "", "measurement": "", "ingredient": "Sauce: tamarind paste, fish sauce, palm sugar"}, {"quantity": "", "measurement": "", "ingredient": "Bean sprouts, Chinese chives, crushed roasted peanuts & lime"}]'::jsonb,
    array['Sear prawns and tofu in a very hot wok with peanut oil. Push to side.', 'Scramble eggs in center until soft curd.', 'Add drained noodles and pad thai sauce. Toss vigorously over high heat until noodles absorb sauce.', 'Toss in fresh bean sprouts and chives for 30 seconds.', 'Serve immediately with crushed peanuts, chili flakes, and fresh lime wedges.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000016', 'a2222222-2222-2222-2222-222222222222', 'Spicy Tom Yum Goong', 'tom yum goong', array['soup', 'thai', 'seafood', 'spicy'], 'thai', 1, true,
    '[{"quantity": "300", "measurement": "g", "ingredient": "large prawns, shells reserved for stock"}, {"quantity": "1", "measurement": "liter", "ingredient": "water or chicken stock"}, {"quantity": "2", "measurement": "stalks", "ingredient": "lemongrass, bruised"}, {"quantity": "4", "measurement": "", "ingredient": "kaffir lime leaves, torn"}, {"quantity": "3", "measurement": "slices", "ingredient": "galangal"}, {"quantity": "150", "measurement": "g", "ingredient": "straw mushrooms or oyster mushrooms"}, {"quantity": "2", "measurement": "tbsp", "ingredient": "Thai chili paste (nam prik pao), fish sauce & lime juice"}]'::jsonb,
    array['Simmer prawn shells in water for 10 min to make a rich broth; strain.', 'Bring broth to boil with lemongrass, galangal, and kaffir lime leaves.', 'Add mushrooms and chili paste. Simmer 3 minutes.', 'Add prawns and cook 2 minutes until pink and tender.', 'Take off heat, stir in fish sauce and fresh lime juice. Garnish with fresh cilantro and bird''''s eye chilies.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000017', 'a2222222-2222-2222-2222-222222222222', 'Rich Tonkotsu Pork Ramen', 'tonkotsu ramen', array['ramen', 'japanese', 'noodles', 'comfort-food'], 'japanese', 3, true,
    '[{"quantity": "", "measurement": "", "ingredient": "Fresh ramen noodles"}, {"quantity": "1", "measurement": "kg", "ingredient": "pork neck bones & pork trotters"}, {"quantity": "", "measurement": "", "ingredient": "Aromatics: ginger, garlic, scallions, shallots"}, {"quantity": "", "measurement": "", "ingredient": "Chashu pork belly slices"}, {"quantity": "", "measurement": "", "ingredient": "Ramen eggs (ajitsuke tamago)"}, {"quantity": "", "measurement": "", "ingredient": "Menma (bamboo shoots), nori & green onions"}]'::jsonb,
    array['Blanch bones in boiling water, scrub clean, then boil vigorously for 8-10 hours until opaque and creamy milky white.', 'Strain broth and season with soy sauce-mirin tare.', 'Cook ramen noodles for 90 seconds in boiling water; drain thoroughly.', 'Place noodles in pre-warmed bowls, ladle steaming hot tonkotsu broth over top.', 'Garnish with rolled chashu pork, marinated soft-boiled egg halves, green onions, and nori sheets.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000018', 'a2222222-2222-2222-2222-222222222222', 'Crispy Chicken Katsu Curry', 'chicken katsu curry', array['chicken', 'japanese', 'curry', 'crispy'], 'japanese', 2, true,
    '[{"quantity": "4", "measurement": "", "ingredient": "chicken cutlets, pounded even"}, {"quantity": "", "measurement": "", "ingredient": "Flour, egg, and Japanese panko breadcrumbs"}, {"quantity": "", "measurement": "", "ingredient": "Japanese curry roux block"}, {"quantity": "1", "measurement": "", "ingredient": "onion, 1 carrot, 1 potato, cubed"}, {"quantity": "600", "measurement": "ml", "ingredient": "water"}, {"quantity": "", "measurement": "", "ingredient": "Steamed Japanese short-grain rice & fukujinzuke pickles"}]'::jsonb,
    array['Sauté onions, carrots, and potatoes in a saucepan. Add water, bring to boil, and simmer 15 min.', 'Turn off heat, dissolve curry roux cubes, then simmer on low until thick and glossy.', 'Dredge chicken in flour, dip in beaten egg, and coat thickly with panko.', 'Deep fry cutlets in 170°C oil until golden brown and super crunchy (5-6 min). Slice into strips.', 'Plate rice, arrange sliced katsu, and ladle hot aromatic curry sauce generously alongside.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000019', 'a2222222-2222-2222-2222-222222222222', 'Teriyaki Salmon Rice Bowls', 'teriyaki salmon bowls', array['salmon', 'japanese', 'rice-bowl', 'quick'], 'japanese', 1, true,
    '[{"quantity": "4", "measurement": "", "ingredient": "salmon fillets"}, {"quantity": "", "measurement": "", "ingredient": "Homemade teriyaki: 3 tbsp soy sauce, 3 tbsp mirin, 2 tbsp sake, 1.5 tbsp sugar"}, {"quantity": "2", "measurement": "cups", "ingredient": "cooked Japanese sushi rice"}, {"quantity": "", "measurement": "", "ingredient": "Steamed edamame & cucumber slices"}, {"quantity": "", "measurement": "", "ingredient": "Toasted sesame seeds & scallions"}]'::jsonb,
    array['Simmer soy sauce, mirin, sake, and sugar in a small saucepan until reduced to a shiny glaze.', 'Pan-sear salmon fillets in a hot skillet for 3 minutes on each side.', 'Brush glaze generously over salmon in the last minute of cooking until caramelized.', 'Scoop warm sushi rice into bowls.', 'Top with glazed salmon, shelled edamame, cucumber ribbon salad, and sprinkle with sesame seeds.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000020', 'a2222222-2222-2222-2222-222222222222', 'Miso-Glazed Roasted Eggplant', 'miso roasted eggplant', array['eggplant', 'japanese', 'vegetarian', 'side'], 'japanese', 1, true,
    '[{"quantity": "2", "measurement": "", "ingredient": "medium Japanese or Italian eggplants, halved lengthwise"}, {"quantity": "", "measurement": "", "ingredient": "Glaze: 3 tbsp white miso, 2 tbsp mirin, 1 tbsp sake, 1 tbsp brown sugar"}, {"quantity": "2", "measurement": "tbsp", "ingredient": "sesame oil"}, {"quantity": "", "measurement": "", "ingredient": "Toasted white and black sesame seeds & finely sliced scallions"}]'::jsonb,
    array['Score eggplant flesh in a diamond pattern without piercing the skin.', 'Brush cut sides generously with sesame oil.', 'Pan sear eggplant cut-side down in an ovenproof pan until browned (3-4 min).', 'Whisk miso, mirin, sake, and sugar until silky smooth.', 'Flip eggplant, spoon thick glaze over scored flesh, and broil in oven at 200°C for 8-10 min until bubbling and caramelized.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000021', 'a3333333-3333-3333-3333-333333333333', 'Sichuan Kung Pao Chicken', 'kung pao chicken', array['chicken', 'sichuan', 'spicy', 'quick'], 'asian', 1, true,
    '[{"quantity": "450", "measurement": "g", "ingredient": "boneless chicken thighs, diced"}, {"quantity": "10-12", "measurement": "", "ingredient": "whole dried red chilies, cut"}, {"quantity": "1", "measurement": "tsp", "ingredient": "Sichuan peppercorns"}, {"quantity": "1/2", "measurement": "cup", "ingredient": "roasted unsalted peanuts"}, {"quantity": "3", "measurement": "", "ingredient": "scallions, cut into inch batons"}, {"quantity": "", "measurement": "", "ingredient": "Kung Pao sauce: Chinkiang black vinegar, soy sauce, Shaoxing wine, sugar, cornstarch"}]'::jsonb,
    array['Marinate chicken with light soy sauce and cornstarch for 15 min.', 'Heat oil in a hot wok. Stir fry dried chilies and Sichuan peppercorns until fragrant and darkened.', 'Add chicken pieces and sear over high heat until browned.', 'Stir in minced ginger, garlic, and scallion whites.', 'Pour in sauce, toss until glossy and clinging to chicken, then fold in roasted peanuts.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000022', 'a3333333-3333-3333-3333-333333333333', 'Cantonese Beef & Broccoli Stir-Fry', 'beef and broccoli', array['beef', 'asian', 'stir-fry', 'quick'], 'asian', 1, true,
    '[{"quantity": "400", "measurement": "g", "ingredient": "flank steak, sliced thin across the grain"}, {"quantity": "1", "measurement": "", "ingredient": "large head broccoli, cut into florets"}, {"quantity": "2", "measurement": "cloves", "ingredient": "garlic & 1 tbsp grated ginger"}, {"quantity": "", "measurement": "", "ingredient": "Sauce: oyster sauce, dark soy sauce, Shaoxing wine, sesame oil, broth, cornstarch"}, {"quantity": "", "measurement": "", "ingredient": "Steamed jasmine rice"}]'::jsonb,
    array['Velveting: toss beef with soy sauce, Shaoxing wine, and cornstarch for 15 min.', 'Blanch broccoli florets in boiling water for 60 seconds until bright green; drain.', 'Sear marinated beef in a smoking hot wok in single layer (90 seconds); remove.', 'Sauté garlic and ginger in wok, return beef and broccoli.', 'Pour in sauce and toss 1 minute until sauce thickens to a glossy coat.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000023', 'a3333333-3333-3333-3333-333333333333', 'Steamed Pork & Chive Dumplings', 'pork chive dumplings', array['dumplings', 'asian', 'finger-food', 'pork'], 'asian', 2, true,
    '[{"quantity": "40", "measurement": "", "ingredient": "dumpling wrappers"}, {"quantity": "400", "measurement": "g", "ingredient": "ground pork"}, {"quantity": "150", "measurement": "g", "ingredient": "Chinese garlic chives, finely chopped"}, {"quantity": "1", "measurement": "tbsp", "ingredient": "grated ginger, 2 tbsp light soy sauce, 1 tbsp Shaoxing wine, 1 tbsp sesame oil"}, {"quantity": "", "measurement": "", "ingredient": "Dipping sauce: black vinegar, chili oil, garlic"}]'::jsonb,
    array['Mix pork, chives, ginger, soy, wine, and sesame oil vigorously in one direction until sticky.', 'Place 1 tbsp filling in center of each wrapper, wet edges, and pleat tightly.', 'Line bamboo steamer with parchment paper and arrange dumplings.', 'Steam over boiling water for 8-10 minutes until skins are translucent and cooked.', 'Serve immediately with spicy Chinkiang vinegar dipping sauce.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000024', 'a3333333-3333-3333-3333-333333333333', 'Korean Bulgogi Beef Bowls', 'bulgogi beef bowls', array['beef', 'korean', 'rice-bowl', 'bbq'], 'korean', 1, true,
    '[{"quantity": "500", "measurement": "g", "ingredient": "ribeye or sirloin, sliced paper thin"}, {"quantity": "", "measurement": "", "ingredient": "Marinade: grated Asian pear, soy sauce, brown sugar, sesame oil, minced garlic, ginger"}, {"quantity": "1", "measurement": "", "ingredient": "sweet onion, sliced"}, {"quantity": "", "measurement": "", "ingredient": "Cooked rice, kimchi, and toasted sesame seeds"}, {"quantity": "", "measurement": "", "ingredient": "Crisp romaine lettuce cups for wrapping"}]'::jsonb,
    array['Blend Asian pear, soy sauce, sugar, garlic, and sesame oil.', 'Marinate beef and sliced onion for at least 30 min (or overnight).', 'Heat a cast iron skillet or grill pan screaming hot.', 'Cook beef in a single layer for 2-3 minutes until charred on edges and caramelized.', 'Serve over warm rice bowls with fresh kimchi and crisp lettuce wraps.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000025', 'a3333333-3333-3333-3333-333333333333', 'Crispy Kimchi Fried Rice', 'kimchi fried rice', array['rice', 'korean', 'quick', 'spicy'], 'korean', 0, true,
    '[{"quantity": "3", "measurement": "cups", "ingredient": "day-old cold cooked white rice"}, {"quantity": "1", "measurement": "cup", "ingredient": "well-fermented kimchi, chopped (plus 3 tbsp kimchi juice)"}, {"quantity": "100", "measurement": "g", "ingredient": "bacon or pork belly, diced"}, {"quantity": "1", "measurement": "tbsp", "ingredient": "gochujang (Korean chili paste)"}, {"quantity": "1", "measurement": "tbsp", "ingredient": "sesame oil"}, {"quantity": "", "measurement": "", "ingredient": "Fried sunny-side eggs & toasted nori strips"}]'::jsonb,
    array['Crisp bacon in a wide skillet or wok.', 'Add chopped kimchi and stir fry 3 minutes until softened and translucent.', 'Stir in gochujang and kimchi juice.', 'Add cold rice, breaking up grains, tossing over high heat for 3-4 minutes.', 'Drizzle sesame oil, top with runny fried eggs and shredded toasted seaweed.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000026', 'b1111111-1111-1111-1111-111111111111', 'Murgh Makhani Butter Chicken', 'butter chicken', array['curry', 'indian', 'chicken', 'comfort-food'], 'indian', 2, true,
    '[{"quantity": "600", "measurement": "g", "ingredient": "chicken thighs in yogurt, ginger, garlic, garam masala marinade"}, {"quantity": "50", "measurement": "g", "ingredient": "butter & 1 tbsp oil"}, {"quantity": "1", "measurement": "", "ingredient": "finely chopped onion"}, {"quantity": "400", "measurement": "g", "ingredient": "tomato puree"}, {"quantity": "150", "measurement": "ml", "ingredient": "heavy cream & 1 tbsp kasuri methi (fenugreek leaves)"}, {"quantity": "", "measurement": "", "ingredient": "Warm basmati rice & garlic naan"}]'::jsonb,
    array['Broil or grill marinated chicken chunks on high heat until lightly charred; set aside.', 'Melt butter in pan, sauté onions until golden.', 'Add tomato puree, ginger-garlic paste, chili powder, and garam masala; simmer 15 min.', 'Puree sauce until velvety smooth.', 'Stir in cream, crushed fenugreek leaves, and grilled chicken. Simmer 5 min.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000027', 'b1111111-1111-1111-1111-111111111111', 'Chicken Tikka Masala', 'chicken tikka masala', array['curry', 'indian', 'chicken', 'classic'], 'indian', 2, true,
    '[{"quantity": "600", "measurement": "g", "ingredient": "chicken breast cubes marinated in spiced yogurt"}, {"quantity": "2", "measurement": "", "ingredient": "onions, finely diced"}, {"quantity": "3", "measurement": "cloves", "ingredient": "garlic & 2 tbsp ginger paste"}, {"quantity": "", "measurement": "", "ingredient": "Ground coriander, cumin, turmeric, Kashmiri chili"}, {"quantity": "400", "measurement": "g", "ingredient": "crushed canned tomatoes"}, {"quantity": "100", "measurement": "ml", "ingredient": "heavy cream & fresh cilantro"}]'::jsonb,
    array['Skewer marinated chicken and broil at 230°C until edges are blackened.', 'Sauté onions, ginger, and garlic in ghee until caramelized.', 'Add dry spices and bloom for 1 minute.', 'Add crushed tomatoes and simmer into a thick aromatic gravy.', 'Fold in cream and roasted chicken pieces. Simmer 5 minutes, garnish with fresh chopped cilantro.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000028', 'b1111111-1111-1111-1111-111111111111', 'Spiced Red Lentil Dal with Garlic Naan', 'red lentil dal', array['curry', 'dal', 'indian', 'vegan'], 'indian', 1, true,
    '[{"quantity": "250", "measurement": "g", "ingredient": "split red lentils (masoor dal), rinsed"}, {"quantity": "1", "measurement": "tsp", "ingredient": "turmeric, 1 tsp ground cumin, salt"}, {"quantity": "750", "measurement": "ml", "ingredient": "water or broth"}, {"quantity": "", "measurement": "", "ingredient": "Tadka tempering: 2 tbsp ghee, 1 tsp cumin seeds, 3 cloves sliced garlic, dried red chilies"}, {"quantity": "", "measurement": "", "ingredient": "Fresh cilantro & warm garlic naan"}]'::jsonb,
    array['Simmer rinsed lentils with water, turmeric, and salt for 20 minutes until creamy and collapsed.', 'Whisk dal lightly to achieve desired smooth texture.', 'In a small frying pan, heat ghee until hot. Add cumin seeds, sliced garlic, and chilies.', 'Fry until garlic is golden brown and fragrant (60 seconds).', 'Pour sizzling tadka directly over the lentils with a hiss. Stir in fresh cilantro.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000029', 'b1111111-1111-1111-1111-111111111111', 'Greek Lemon Oregano Roast Chicken', 'lemon oregano chicken', array['chicken', 'greek', 'roast', 'comfort-food'], 'greek', 2, true,
    '[{"quantity": "1.5", "measurement": "kg", "ingredient": "bone-in chicken thighs and drumsticks"}, {"quantity": "800", "measurement": "g", "ingredient": "Yukon gold potatoes, cut into wedges"}, {"quantity": "", "measurement": "", "ingredient": "Juice of 3 large lemons"}, {"quantity": "100", "measurement": "ml", "ingredient": "Greek extra virgin olive oil"}, {"quantity": "4", "measurement": "cloves", "ingredient": "garlic, crushed"}, {"quantity": "2", "measurement": "tbsp", "ingredient": "dried wild oregano & sea salt"}]'::jsonb,
    array['Toss chicken and potatoes in a roasting pan with lemon juice, olive oil, garlic, oregano, and salt.', 'Pour 150ml chicken broth into the pan around the edges.', 'Roast at 200°C for 50-60 minutes, turning potatoes once halfway.', 'Chicken skin should be golden crisp and potatoes creamy inside with crispy lemon edges.', 'Garnish with more wild oregano and serve with crusty bread.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000030', 'b1111111-1111-1111-1111-111111111111', 'Souvlaki Skewers with Homemade Tzatziki', 'souvlaki skewers', array['grill', 'greek', 'bbq', 'skewers'], 'greek', 1, true,
    '[{"quantity": "600", "measurement": "g", "ingredient": "pork tenderloin or chicken breast, cubed"}, {"quantity": "", "measurement": "", "ingredient": "Marinade: olive oil, lemon juice, garlic, oregano, thyme, salt"}, {"quantity": "", "measurement": "", "ingredient": "Wooden skewers soaked in water"}, {"quantity": "", "measurement": "", "ingredient": "Tzatziki: grated cucumber (squeezed dry), Greek yogurt, garlic, dill, olive oil"}, {"quantity": "", "measurement": "", "ingredient": "Warm pita flatbreads"}]'::jsonb,
    array['Thread marinated meat cubes snugly onto skewers.', 'Whisk drained grated cucumber, Greek yogurt, crushed garlic, olive oil, and dill.', 'Grill skewers over hot charcoal or cast iron grill for 3-4 min per side until charred and juicy.', 'Warm pita flatbreads over grill.', 'Assemble pitas with skewers, tomatoes, red onions, and abundant cool tzatziki.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000031', 'a1111111-1111-1111-1111-111111111111', 'Traditional Spanish Seafood Paella', 'spanish seafood paella', array['rice', 'spanish', 'seafood', 'crowd-pleaser'], 'spanish', 3, true,
    '[{"quantity": "400", "measurement": "g", "ingredient": "Bomba paella rice"}, {"quantity": "12", "measurement": "", "ingredient": "mussels & 12 clams, scrubbed"}, {"quantity": "8", "measurement": "", "ingredient": "large tiger prawns"}, {"quantity": "200", "measurement": "g", "ingredient": "calamari rings"}, {"quantity": "1", "measurement": "liter", "ingredient": "rich fish stock infused with a pinch of saffron"}, {"quantity": "", "measurement": "", "ingredient": "Sofrito: grated tomatoes, onions, garlic, sweet smoked paprika"}]'::jsonb,
    array['Sear prawns in olive oil in a 36cm paella pan; set aside.', 'Build sofrito in remaining oil until dark and jammy (10 min).', 'Stir in Bomba rice to coat with sofrito. Pour in hot saffron fish stock.', 'Cook over medium-high heat for 10 min without stirring, then lower heat.', 'Arrange seafood on top, cover with foil, cook 8 min until rice forms a crispy bottom socarrat crust.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000032', 'a1111111-1111-1111-1111-111111111111', 'Sizzling Gambas al Ajillo', 'gambas al ajillo', array['tapas', 'spanish', 'seafood', 'quick'], 'spanish', 0, true,
    '[{"quantity": "400", "measurement": "g", "ingredient": "raw peeled prawns"}, {"quantity": "8", "measurement": "", "ingredient": "garlic cloves, thinly sliced"}, {"quantity": "1", "measurement": "", "ingredient": "dried red chili pepper, sliced"}, {"quantity": "100", "measurement": "ml", "ingredient": "Spanish extra virgin olive oil"}, {"quantity": "2", "measurement": "tbsp", "ingredient": "dry sherry or white wine"}, {"quantity": "", "measurement": "", "ingredient": "Chopped flat-leaf parsley & crusty baguette"}]'::jsonb,
    array['Heat olive oil in a shallow clay cazuela or skillet over medium-low heat.', 'Add sliced garlic and chili, cooking gently until garlic turns pale golden (do not burn).', 'Raise heat to high, add prawns, and sauté 2 minutes until pink and curled.', 'Splash in dry sherry and toss with chopped fresh parsley.', 'Serve immediately while oil is still vigorously sizzling with fresh crusty bread for dipping.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000033', 'a3333333-3333-3333-3333-333333333333', 'Mediterranean Shakshuka with Feta', 'mediterranean shakshuka', array['eggs', 'mediterranean', 'brunch', 'vegetarian'], 'mediterranean', 1, true,
    '[{"quantity": "1", "measurement": "", "ingredient": "sliced red bell pepper & 1 yellow bell pepper"}, {"quantity": "1", "measurement": "", "ingredient": "onion & 3 garlic cloves"}, {"quantity": "1", "measurement": "tsp", "ingredient": "cumin, 1 tsp smoked paprika"}, {"quantity": "600", "measurement": "g", "ingredient": "ripe crushed tomatoes"}, {"quantity": "4-5", "measurement": "", "ingredient": "fresh large eggs"}, {"quantity": "100", "measurement": "g", "ingredient": "Greek feta cheese, crumbled"}, {"quantity": "", "measurement": "", "ingredient": "Fresh cilantro or parsley & toasted sourdough"}]'::jsonb,
    array['Sauté peppers and onions in olive oil until sweet and tender (10 min).', 'Add garlic and ground spices; cook 1 minute until fragrant.', 'Pour in crushed tomatoes, season with salt and pepper, and simmer 10 min into a thick sauce.', 'Make small wells in the sauce with a spoon and crack an egg into each well.', 'Cover pan and cook on low heat 5-7 minutes until whites are set but yolks are runny. Crumble feta over top.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000034', 'a3333333-3333-3333-3333-333333333333', 'Crispy Falafel & Hummus Mezze', 'falafel hummus mezze', array['mezze', 'falafel', 'vegetarian', 'middle-eastern'], 'middle_eastern', 2, true,
    '[{"quantity": "250", "measurement": "g", "ingredient": "dried chickpeas (soaked overnight, NOT canned)"}, {"quantity": "1", "measurement": "cup", "ingredient": "fresh parsley & cilantro"}, {"quantity": "4", "measurement": "cloves", "ingredient": "garlic, 1 onion, 1 tbsp cumin, 1 tbsp coriander"}, {"quantity": "1", "measurement": "tsp", "ingredient": "baking powder & 2 tbsp chickpea flour"}, {"quantity": "", "measurement": "", "ingredient": "Hummus, pickled turnips, tahini sauce, warm pita"}]'::jsonb,
    array['Pulse soaked drained chickpeas, herbs, onion, garlic, and spices in food processor to a coarse meal.', 'Chill mixture 30 min, then stir in baking powder.', 'Form into small walnut-sized balls.', 'Deep fry in 180°C oil for 3-4 minutes until deep golden brown and crunchy.', 'Serve atop creamy hummus drizzled with tahini, warm pita, and pickles.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000035', 'a3333333-3333-3333-3333-333333333333', 'Slow-Roasted Lamb Shawarma', 'lamb shawarma', array['lamb', 'middle-eastern', 'slow-cook', 'bbq'], 'middle_eastern', 3, true,
    '[{"quantity": "1.5", "measurement": "kg", "ingredient": "bone-in lamb shoulder"}, {"quantity": "", "measurement": "", "ingredient": "Shawarma rub: cumin, coriander, cardamom, cinnamon, smoked paprika, garlic, lemon juice, olive oil"}, {"quantity": "", "measurement": "", "ingredient": "Diced cucumbers and tomatoes with mint"}, {"quantity": "", "measurement": "", "ingredient": "Garlic toum sauce & warm flatbreads"}]'::jsonb,
    array['Rub lamb shoulder all over with spiced shawarma marinade.', 'Wrap tightly in parchment paper and foil.', 'Slow roast at 140°C for 4.5 hours until bone slips out effortlessly.', 'Unwrap, shred tender succulent meat, and crisp under a hot broiler for 5 minutes.', 'Pile shredded lamb into flatbreads with garlic sauce, pickled red onions, and fresh tomato mint salad.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000036', 'a1111111-1111-1111-1111-111111111111', 'French Boeuf Bourguignon', 'boeuf bourguignon', array['beef', 'french', 'stew', 'slow-cook'], 'french', 3, true,
    '[{"quantity": "1", "measurement": "kg", "ingredient": "beef chuck, cut into 5cm chunks"}, {"quantity": "150", "measurement": "g", "ingredient": "smoked bacon lardons"}, {"quantity": "1", "measurement": "", "ingredient": "bottle good Burgundy red wine"}, {"quantity": "2", "measurement": "", "ingredient": "carrots, 1 onion, 2 garlic cloves, bouquet garni"}, {"quantity": "250", "measurement": "g", "ingredient": "cremini mushrooms & 15 pearl onions browned in butter"}, {"quantity": "500", "measurement": "ml", "ingredient": "beef stock & 2 tbsp tomato paste"}]'::jsonb,
    array['Sauté lardons in Dutch oven; remove. Pat beef dry and brown deeply in batches.', 'Sauté onions and carrots; stir in tomato paste and flour.', 'Pour in Burgundy wine and beef stock, add bouquet garni and browned meat.', 'Simmer covered in oven at 150°C for 3 hours until meltingly tender.', 'Fold in glazed pearl onions and sautéed mushrooms for the last 15 minutes. Serve with buttered potatoes.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000037', 'a1111111-1111-1111-1111-111111111111', 'Coq au Vin with Pearl Onions', 'coq au vin', array['chicken', 'french', 'stew', 'wine'], 'french', 3, true,
    '[{"quantity": "1.2", "measurement": "kg", "ingredient": "chicken thighs and legs"}, {"quantity": "150", "measurement": "g", "ingredient": "diced thick-cut bacon"}, {"quantity": "750", "measurement": "ml", "ingredient": "dry red wine (Pinot Noir)"}, {"quantity": "250", "measurement": "g", "ingredient": "small button mushrooms"}, {"quantity": "15", "measurement": "", "ingredient": "pearl onions, peeled"}, {"quantity": "2", "measurement": "", "ingredient": "carrots, sliced & 2 cloves garlic"}, {"quantity": "", "measurement": "", "ingredient": "Butter, flour, fresh thyme and bay leaf"}]'::jsonb,
    array['Crisp bacon in a heavy pot; remove. Sear chicken pieces in bacon fat until golden.', 'Brown pearl onions and mushrooms; set aside.', 'Sauté carrots and garlic, sprinkle flour, and pour in red wine and chicken stock.', 'Return chicken and bacon, add fresh thyme and bay leaf.', 'Simmer gently 45 minutes until chicken is tender. Fold in mushrooms and onions; simmer 10 minutes to thicken.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000038', 'a1111111-1111-1111-1111-111111111111', 'Classic Ratatouille Provençale', 'ratatouille', array['french', 'vegetables', 'vegetarian', 'healthy'], 'french', 2, true,
    '[{"quantity": "2", "measurement": "", "ingredient": "zucchini & 2 yellow summer squash"}, {"quantity": "1", "measurement": "", "ingredient": "large eggplant"}, {"quantity": "4", "measurement": "", "ingredient": "Roma tomatoes"}, {"quantity": "", "measurement": "", "ingredient": "Piperade base: 2 bell peppers, 1 onion, 3 garlic cloves, crushed tomatoes, olive oil, thyme"}]'::jsonb,
    array['Sauté peppers, onions, garlic, and herbs with crushed tomatoes to make a rich piperade sauce.', 'Spread piperade evenly over bottom of a round baking dish.', 'Thinly slice zucchini, yellow squash, eggplant, and tomatoes into uniform rounds.', 'Arrange alternating vegetable slices in concentric spirals over the sauce.', 'Drizzle with olive oil, sprinkle thyme, cover with parchment, and bake at 180°C for 45 minutes until tender and caramelized.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000039', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 'Double Smash Burgers with Secret Sauce', 'smash burgers', array['burgers', 'american', 'beef', 'comfort-food'], 'american', 1, true,
    '[{"quantity": "600", "measurement": "g", "ingredient": "ground beef chuck (80/20 fat ratio), portioned into 8 balls"}, {"quantity": "4", "measurement": "", "ingredient": "potato burger buns, buttered and toasted"}, {"quantity": "8", "measurement": "slices", "ingredient": "American cheese"}, {"quantity": "", "measurement": "", "ingredient": "Thinly shaved sweet white onion"}, {"quantity": "", "measurement": "", "ingredient": "Secret sauce: mayonnaise, yellow mustard, pickle relish, smoked paprika, garlic powder"}, {"quantity": "", "measurement": "", "ingredient": "Dill pickle chips"}]'::jsonb,
    array['Heat a cast iron griddle until smoking hot.', 'Place beef balls on griddle, top with shaved onions, and smash paper-thin with a heavy press.', 'Season heavily with salt and black pepper; cook 2 min until edges are intensely charred and crispy.', 'Flip patties, immediately top each with American cheese, and stack two patties together.', 'Spread secret sauce on toasted buns, add pickle chips, and crown with double cheesy patties.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;

insert into public.dishes (id, owner_id, name, normalized_name, tags, cuisine, effort, is_public, ingredients, instructions)
values ('e0000000-0000-0000-0000-000000000040', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '12-Hour Texas Smoked Pulled Pork', 'texas pulled pork', array['pork', 'bbq', 'american', 'slow-cook'], 'american', 3, true,
    '[{"quantity": "2.5", "measurement": "kg", "ingredient": "bone-in pork shoulder (Boston butt)"}, {"quantity": "", "measurement": "", "ingredient": "Texas rub: coarse kosher salt, coarse black pepper, smoked paprika, brown sugar, garlic powder"}, {"quantity": "", "measurement": "", "ingredient": "Apple cider vinegar spritz"}, {"quantity": "", "measurement": "", "ingredient": "Brioche slider buns, coleslaw & tangy BBQ sauce"}]'::jsonb,
    array['Coat pork shoulder evenly with mustard binder and heavy Texas spice rub.', 'Smoke over hickory or oak wood at 110°C (225°F) for 6 hours, spritzing hourly with apple cider vinegar.', 'Wrap tightly in peach butcher paper when dark bark forms.', 'Return to smoker or oven until internal temperature reaches 96°C (approx. 5 more hours).', 'Rest 1 hour, shred into juicy strands, and toss with pan drippings. Serve on toasted brioche with tangy slaw.'])
on conflict (id) do update set
    name = excluded.name,
    normalized_name = excluded.normalized_name,
    tags = excluded.tags,
    cuisine = excluded.cuisine,
    effort = excluded.effort,
    is_public = excluded.is_public,
    ingredients = excluded.ingredients,
    instructions = excluded.instructions;


-- 6. Meals & Ratings
insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-09-05', 'Inaugural Friday feast! Homemade pizza night with extra crispy crust.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000001', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000001', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000001', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000001', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-09-12', 'Silky carbonara. Marcus brought great wine.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000002', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000002', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000002', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000002', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000002', 'a3333333-3333-3333-3333-333333333333', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000007', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-09-19', 'Baja fish tacos on the patio before autumn chills set in.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000003', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000003', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000003', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000003', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000003', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000011', 'a1111111-1111-1111-1111-111111111111', '2025-09-26', 'Classic comfort: Swedish meatballs with extra lingonberries.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000004', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000004', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000004', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000004', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000004', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000014', 'a2222222-2222-2222-2222-222222222222', '2025-10-03', 'Yellow coconut curry warmed everybody up.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000005', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000005', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000005', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000005', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000005', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000006', 'e0000000-0000-0000-0000-000000000015', 'a2222222-2222-2222-2222-222222222222', '2025-10-10', 'Pad thai with huge tiger prawns.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000006', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000006', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000006', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000006', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000006', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000007', 'e0000000-0000-0000-0000-000000000018', 'a2222222-2222-2222-2222-222222222222', '2025-10-17', 'Katsu curry night. Panko was ultra crunchy.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000007', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000007', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000007', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000007', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000007', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000008', 'e0000000-0000-0000-0000-000000000021', 'a3333333-3333-3333-3333-333333333333', '2025-10-24', 'Spicy kung pao chicken! Lots of Sichuan peppercorns.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000008', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000008', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000008', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000008', 'a2222222-2222-2222-2222-222222222222', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000008', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000009', 'e0000000-0000-0000-0000-000000000023', 'a3333333-3333-3333-3333-333333333333', '2025-10-31', 'Halloween dumpling folding party! Made over 60 dumplings.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000009', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000009', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000009', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000009', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000009', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000026', 'b1111111-1111-1111-1111-111111111111', '2025-11-07', 'Butter chicken with homemade garlic naan.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000010', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000010', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000010', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000010', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000010', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000011', 'e0000000-0000-0000-0000-000000000029', 'b1111111-1111-1111-1111-111111111111', '2025-11-14', 'Greek roast chicken with lots of lemon.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000011', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000011', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000011', 'a1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000011', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000011', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000012', 'e0000000-0000-0000-0000-000000000033', 'a3333333-3333-3333-3333-333333333333', '2025-11-21', 'Cozy Friday brunch-for-dinner shakshuka.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000012', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000012', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000012', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000012', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000012', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000013', 'e0000000-0000-0000-0000-000000000039', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-11-28', 'Smash burgers on the flat iron. Cheesy and crispy.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000013', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000013', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000013', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000013', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000013', 'a3333333-3333-3333-3333-333333333333', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000014', 'e0000000-0000-0000-0000-000000000003', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-12-05', 'Slow simmered bolognese ragu after a cold week.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000014', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000014', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000014', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000014', 'a2222222-2222-2222-2222-222222222222', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000014', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000015', 'e0000000-0000-0000-0000-000000000005', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-12-12', 'Wild mushroom and truffle risotto. Rich and decadent.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000015', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000015', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000015', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000015', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000015', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000016', 'e0000000-0000-0000-0000-000000000006', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-12-19', 'Pre-holiday birria taco feast! The consommé was so rich.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000016', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000016', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000016', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000016', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000016', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000017', 'e0000000-0000-0000-0000-000000000012', 'a1111111-1111-1111-1111-111111111111', '2026-01-09', 'First feast of the new year: seared salmon and dill potatoes.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000017', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000017', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000017', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000017', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000017', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000018', 'e0000000-0000-0000-0000-000000000017', 'a2222222-2222-2222-2222-222222222222', '2026-01-16', 'Tonkotsu ramen night! 10-hour broth was worth every minute.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000018', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000018', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000018', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000018', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000018', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000019', 'e0000000-0000-0000-0000-000000000024', 'a3333333-3333-3333-3333-333333333333', '2026-01-23', 'Bulgogi beef bowls with extra homemade kimchi.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000019', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000019', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000019', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000019', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000019', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000020', 'e0000000-0000-0000-0000-000000000027', 'b1111111-1111-1111-1111-111111111111', '2026-02-06', 'Chicken tikka masala and basmati rice.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000020', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000020', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000020', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000020', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000020', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000021', 'e0000000-0000-0000-0000-000000000030', 'b1111111-1111-1111-1111-111111111111', '2026-02-20', 'Souvlaki skewers with cool cucumber tzatziki.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000021', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000021', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000021', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000021', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000021', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000022', 'e0000000-0000-0000-0000-000000000036', 'a1111111-1111-1111-1111-111111111111', '2026-03-06', 'Boeuf bourguignon with creamy mash.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000022', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000022', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000022', 'a1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000022', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000022', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000023', 'e0000000-0000-0000-0000-000000000001', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-03-20', 'Friday pizza remake! Cold fermented dough for 48 hours.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000023', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000023', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000023', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000023', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000023', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000024', 'e0000000-0000-0000-0000-000000000002', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-04-03', 'Carbonara perfection. Perfect glossy sauce.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000024', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000024', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000024', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000024', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000024', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000025', 'e0000000-0000-0000-0000-000000000008', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-04-17', 'Chicken tinga bowls with pickled onions and avocado.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000025', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000025', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000025', 'a1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000025', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000025', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000026', 'e0000000-0000-0000-0000-000000000014', 'a2222222-2222-2222-2222-222222222222', '2026-05-01', 'Spring curry night with sugar snap peas.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000026', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000026', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000026', 'a1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000026', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000026', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000027', 'e0000000-0000-0000-0000-000000000019', 'a2222222-2222-2222-2222-222222222222', '2026-05-15', 'Teriyaki salmon bowls with edamame.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000027', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000027', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000027', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000027', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000027', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000028', 'e0000000-0000-0000-0000-000000000022', 'a3333333-3333-3333-3333-333333333333', '2026-05-29', 'Cantonese beef and broccoli stir fry.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000028', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000028', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000028', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000028', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000028', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000029', 'e0000000-0000-0000-0000-000000000031', 'a1111111-1111-1111-1111-111111111111', '2026-06-12', 'Seafood paella in the garden. Got the socarrat crust just right.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000029', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000029', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000029', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000029', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000029', 'a3333333-3333-3333-3333-333333333333', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000030', 'e0000000-0000-0000-0000-000000000039', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-06-26', 'Midsummer weekend smash burger cookout.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000030', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000030', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000030', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000030', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000030', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000031', 'e0000000-0000-0000-0000-000000000007', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-07-13', 'Summer retreat day 1: Baja crispy fish tacos.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000031', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000031', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000031', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000031', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000031', 'a3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000032', 'e0000000-0000-0000-0000-000000000010', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-07-14', 'Summer retreat day 2: Fresh guacamole and pico bar.', 0, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000032', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000032', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000032', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000032', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000032', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000033', 'e0000000-0000-0000-0000-000000000032', 'a1111111-1111-1111-1111-111111111111', '2026-07-15', 'Summer retreat day 3: Sizzling gambas al ajillo with crusty bread.', 0, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000033', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000033', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000033', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000033', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000033', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000034', 'e0000000-0000-0000-0000-000000000039', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-07-16', 'Summer retreat day 4: Double smash burgers on the grill.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000034', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000034', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000034', 'a1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000034', 'a2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000034', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000035', 'e0000000-0000-0000-0000-000000000012', 'a1111111-1111-1111-1111-111111111111', '2026-07-17', 'Summer retreat day 5: Pan-seared salmon with fresh garden dill.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000035', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000035', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000035', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000035', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000035', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000036', 'e0000000-0000-0000-0000-000000000004', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-08-07', 'Fresh basil pesto penne from homegrown basil.', 0, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000036', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000036', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000036', 'a1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000036', 'a2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000036', 'a3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000037', 'e0000000-0000-0000-0000-000000000006', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-08-21', 'Birria tacos return. Everyone''s favorite crowd-pleaser.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000037', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000037', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000037', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000037', 'a2222222-2222-2222-2222-222222222222', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000037', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000038', 'e0000000-0000-0000-0000-000000000001', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-08-28', 'End of summer pizza night on the deck.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000038', 'd1111111-1111-1111-1111-111111111111')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000038', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000038', 'a1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000038', 'a2222222-2222-2222-2222-222222222222', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000038', 'a3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000039', 'e0000000-0000-0000-0000-000000000003', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-09-14', 'First Sunday supper: slow-simmered bolognese.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000039', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000039', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000039', 'b1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000039', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000039', 'b3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000040', 'e0000000-0000-0000-0000-000000000011', 'a1111111-1111-1111-1111-111111111111', '2025-10-05', 'Sunday meatballs with mash and pickled cucumbers.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000040', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000040', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000040', 'b1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000040', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000040', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000041', 'e0000000-0000-0000-0000-000000000037', 'a1111111-1111-1111-1111-111111111111', '2025-10-26', 'Classic coq au vin with pearl onions and red wine.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000041', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000041', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000041', 'b1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000041', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000041', 'b3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000042', 'e0000000-0000-0000-0000-000000000005', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-11-16', 'Truffle risotto on a chilly Sunday evening.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000042', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000042', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000042', 'b1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000042', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000042', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000043', 'e0000000-0000-0000-0000-000000000036', 'a1111111-1111-1111-1111-111111111111', '2025-12-07', 'Boeuf bourguignon cooked all afternoon.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000043', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000043', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000043', 'b1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000043', 'b2222222-2222-2222-2222-222222222222', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000043', 'b3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000044', 'e0000000-0000-0000-0000-000000000040', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-12-28', 'Smoked pulled pork sliders for post-holiday gathering.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000044', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000044', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000044', 'b1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000044', 'b2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000044', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000045', 'e0000000-0000-0000-0000-000000000017', 'a2222222-2222-2222-2222-222222222222', '2026-01-18', 'Sunday ramen night. Deep, comforting tonkotsu broth.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000045', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000045', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000045', 'b1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000045', 'b2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000045', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000046', 'e0000000-0000-0000-0000-000000000026', 'b1111111-1111-1111-1111-111111111111', '2026-02-08', 'Butter chicken with fragrant cumin rice.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000046', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000046', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000046', 'b1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000046', 'b2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000046', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000047', 'e0000000-0000-0000-0000-000000000029', 'b1111111-1111-1111-1111-111111111111', '2026-03-01', 'Greek lemon roast chicken and potatoes.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000047', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000047', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000047', 'b1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000047', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000047', 'b3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000048', 'e0000000-0000-0000-0000-000000000038', 'a1111111-1111-1111-1111-111111111111', '2026-03-22', 'Classic layered ratatouille provençale.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000048', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000048', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000048', 'b1111111-1111-1111-1111-111111111111', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000048', 'b2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000048', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000049', 'e0000000-0000-0000-0000-000000000031', 'a1111111-1111-1111-1111-111111111111', '2026-04-12', 'Sunday seafood paella with fresh mussels and prawns.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000049', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000049', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000049', 'b1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000049', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000049', 'b3333333-3333-3333-3333-333333333333', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000050', 'e0000000-0000-0000-0000-000000000009', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-05-03', 'Black bean and sweet corn enchiladas.', 2, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000050', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000050', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000050', 'b1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000050', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000050', 'b3333333-3333-3333-3333-333333333333', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000051', 'e0000000-0000-0000-0000-000000000035', 'a3333333-3333-3333-3333-333333333333', '2026-05-24', 'Slow-roasted lamb shawarma feast.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000051', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000051', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000051', 'b1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000051', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000051', 'b3333333-3333-3333-3333-333333333333', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000052', 'e0000000-0000-0000-0000-000000000018', 'a2222222-2222-2222-2222-222222222222', '2026-06-14', 'Chicken katsu curry with Japanese pickles.', 2, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000052', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000052', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000052', 'b1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000052', 'b2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000052', 'b3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000053', 'e0000000-0000-0000-0000-000000000039', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-07-19', 'Summer Sunday smash burgers in the backyard.', 1, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000053', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000053', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000053', 'b1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000053', 'b2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000053', 'b3333333-3333-3333-3333-333333333333', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000054', 'e0000000-0000-0000-0000-000000000003', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2026-08-23', 'End of summer bolognese tradition.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000054', 'd2222222-2222-2222-2222-222222222222')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000054', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000054', 'b1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000054', 'b2222222-2222-2222-2222-222222222222', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000054', 'b3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000055', 'e0000000-0000-0000-0000-000000000006', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', '2025-10-18', 'Autumn taco feast: slow braised birria beef tacos with rich consommé.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000055', 'd3333333-3333-3333-3333-333333333333')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000055', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000055', 'c1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000055', 'c2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000055', 'c3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000056', 'e0000000-0000-0000-0000-000000000033', 'a3333333-3333-3333-3333-333333333333', '2026-01-24', 'Winter tapas session: spicy shakshuka and warm flatbread.', 1, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000056', 'd3333333-3333-3333-3333-333333333333')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000056', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000056', 'c1111111-1111-1111-1111-111111111111', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000056', 'c2222222-2222-2222-2222-222222222222', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000056', 'c3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000057', 'e0000000-0000-0000-0000-000000000032', 'a1111111-1111-1111-1111-111111111111', '2026-04-25', 'Spring tapas night: sizzling gambas al ajillo and crusty baguettes.', 0, 1)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000057', 'd3333333-3333-3333-3333-333333333333')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000057', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000057', 'c1111111-1111-1111-1111-111111111111', 3)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000057', 'c2222222-2222-2222-2222-222222222222', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000057', 'c3333333-3333-3333-3333-333333333333', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meals (id, dish_id, created_by, eaten_on, notes, effort, repeat_desire)
values ('ba000000-0000-0000-0000-000000000058', 'e0000000-0000-0000-0000-000000000031', 'a1111111-1111-1111-1111-111111111111', '2026-07-25', 'Summer grand paella: seafood paella cooked over outdoor burner.', 3, 2)
on conflict (id) do update set
    dish_id = excluded.dish_id,
    eaten_on = excluded.eaten_on,
    notes = excluded.notes,
    effort = excluded.effort,
    repeat_desire = excluded.repeat_desire;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000058', 'd3333333-3333-3333-3333-333333333333')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000058', 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000058', 'c1111111-1111-1111-1111-111111111111', 4)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000058', 'c2222222-2222-2222-2222-222222222222', 2)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('ba000000-0000-0000-0000-000000000058', 'c3333333-3333-3333-3333-333333333333', 5)
on conflict (meal_id, rater_id) where rater_id is not null do update set reaction = excluded.reaction;

-- Also attach Pasta meals to Pasta & Vino Society
insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000002', 'd4444444-4444-4444-4444-444444444444')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000009', 'd4444444-4444-4444-4444-444444444444')
on conflict (meal_id, party_id) do nothing;

-- And Nordic meals to Nordic Hearth & Ferments
insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000006', 'd5555555-5555-5555-5555-555555555555')
on conflict (meal_id, party_id) do nothing;

insert into public.meal_parties (meal_id, party_id)
values ('ba000000-0000-0000-0000-000000000010', 'd5555555-5555-5555-5555-555555555555')
on conflict (meal_id, party_id) do nothing;


-- 7. Mark historical notifications as read to avoid inbox clutter
update public.notifications set read_at = now() where read_at is null;
