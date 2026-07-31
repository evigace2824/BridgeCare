-- CareBridge — RLS so the Flutter app (logged-in JWT role: authenticated) can
-- read and upsert its own row in public.users.
-- Run the whole file in Supabase → SQL Editor → Run.
--
-- Fixes: "Signed in with Supabase, but there is no row in public.users and the
-- app could not create one" when RLS blocks SELECT or INSERT/UPDATE.

alter table if exists public.users enable row level security;

-- Remove old policies (safe to re-run)
drop policy if exists "users_select_own" on public.users;
drop policy if exists "users_insert_own" on public.users;
drop policy if exists "users_update_own" on public.users;
drop policy if exists "Users can view own profile" on public.users;
drop policy if exists "Users can insert own profile" on public.users;
drop policy if exists "Users can update own profile" on public.users;

-- Important: target role "authenticated" (anon key + valid session JWT)
create policy "users_select_own"
  on public.users for select
  to authenticated
  using (auth.uid() = id);

create policy "users_insert_own"
  on public.users for insert
  to authenticated
  with check (auth.uid() = id);

create policy "users_update_own"
  on public.users for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Optional: if id is TEXT storing UUID strings, use instead of the three lines above:
-- using (auth.uid()::text = id)  with check (auth.uid()::text = id)

grant select, insert, update on public.users to authenticated;

-- ---------------------------------------------------------------------------
-- volunteer_profiles: app selects users with nested volunteer_profiles(*)
-- If RLS is on here with no policy, the whole profile query can fail.
-- ---------------------------------------------------------------------------
alter table if exists public.volunteer_profiles enable row level security;

drop policy if exists "volunteer_profiles_select_own" on public.volunteer_profiles;
drop policy if exists "volunteer_profiles_insert_own" on public.volunteer_profiles;
drop policy if exists "volunteer_profiles_update_own" on public.volunteer_profiles;

create policy "volunteer_profiles_select_own"
  on public.volunteer_profiles for select
  to authenticated
  using (auth.uid() = user_id);

create policy "volunteer_profiles_insert_own"
  on public.volunteer_profiles for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "volunteer_profiles_update_own"
  on public.volunteer_profiles for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update on public.volunteer_profiles to authenticated;
