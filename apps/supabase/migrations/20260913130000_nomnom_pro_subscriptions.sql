-- 0. Enable moddatetime extension
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- 1. Add subscription fields to profiles
ALTER TABLE public.profiles 
ADD COLUMN subscription_status text,
ADD COLUMN subscription_expires_at timestamptz,
ADD COLUMN revenuecat_app_user_id uuid;

-- 2. Create the recipe_insights table for AI grading
CREATE TABLE public.recipe_insights (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    recipe_id uuid NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
    health_score integer,
    flavor_profile jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

-- Ensure 1-to-1 relationship mapping
CREATE UNIQUE INDEX recipe_insights_recipe_id_idx ON public.recipe_insights(recipe_id);

-- Enable RLS
ALTER TABLE public.recipe_insights ENABLE ROW LEVEL SECURITY;

-- Everyone can read insights
CREATE POLICY "Recipe insights are readable by everyone"
    ON public.recipe_insights FOR SELECT
    USING (true);

-- Only service role (or AI backend) can insert/update insights. 
-- For now we prevent regular users from writing to it.
CREATE POLICY "Users cannot mutate recipe insights"
    ON public.recipe_insights FOR ALL
    USING (false);

-- Optional: trigger for updated_at
CREATE TRIGGER update_recipe_insights_updated_at
    BEFORE UPDATE ON public.recipe_insights
    FOR EACH ROW
    EXECUTE FUNCTION moddatetime(updated_at);
