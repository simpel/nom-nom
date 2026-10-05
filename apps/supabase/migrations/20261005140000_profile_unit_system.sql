-- ===========================================================================
-- Unit system preference on the profile: how recipe amounts are shown
-- ===========================================================================

-- null = follow the device's region until the person chooses.
alter table public.profiles
    add column if not exists unit_system text
        check (unit_system in ('metric', 'imperial'));
