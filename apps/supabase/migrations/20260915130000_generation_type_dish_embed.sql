-- 20260915130000_generation_type_dish_embed.sql
-- Recipe embedding generation (embed-dish edge function) now logs to generation_logs too.

alter type public.generation_type add value if not exists 'dish_embed';
