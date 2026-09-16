ALTER TABLE public.party_insights
  DROP COLUMN IF EXISTS health_analysis;

ALTER TABLE public.party_insights
  ADD COLUMN health_analysis jsonb;
