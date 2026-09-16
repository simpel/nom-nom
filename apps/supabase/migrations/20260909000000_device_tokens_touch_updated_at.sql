-- ===========================================================================
-- Keep public.device_tokens.updated_at current.
--
-- The app re-registers its APNs token on every launch via an upsert with
-- `on conflict (user_id, apns_token)`, which resolves to an UPDATE for a token
-- Apple has already handed us before. Without a trigger that UPDATE leaves
-- `updated_at` at its original value, so the column can't answer "when did we
-- last hear from this device" — the one question that lets a cleanup job prune
-- tokens for apps that were deleted without APNs ever returning 410.
--
-- Reuses the baseline's public.touch_updated_at(). BEFORE UPDATE, same as the
-- dishes/meals/meal_ratings triggers next to it.
-- ===========================================================================

create trigger device_tokens_touch
    before update on public.device_tokens
    for each row execute function public.touch_updated_at();
