alter table public.party_insights
add column if not exists top_ingredients jsonb,
add column if not exists ways_of_cooking jsonb,
add column if not exists health_analysis text,
add column if not exists member_matches jsonb;
