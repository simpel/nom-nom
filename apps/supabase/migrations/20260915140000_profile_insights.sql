-- Per-user AI insight, mirroring party_insights but scoped to one profile's own
-- meals and ratings across every party they belong to (not just one party).
alter type public.generation_type add value if not exists 'profile_insight';
