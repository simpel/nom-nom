-- ===========================================================================
-- Add health index (score, verdict, rationale, breakdown) to dishes
-- ===========================================================================

alter table public.dishes
    add column if not exists health_score integer,
    add column if not exists health_verdict text,
    add column if not exists health_rationale text,
    add column if not exists health_breakdown jsonb;
