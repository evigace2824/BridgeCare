-- CareBridge — initial schema for Flutter auth (profiles + RLS + optional auth trigger).
-- Run in Supabase: SQL Editor → New query → paste → Run.
-- Role values must match the app: elderly | family | volunteer

-- ---------------------------------------------------------------------------
-- 1. profiles (linked to auth.users)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null default 'elderly'
    check (role in ('elderly', 'family', 'volunteer')),
  phone text,
  extras jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles (role);

-- ---------------------------------------------------------------------------
-- 2. updated_at
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 3. Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- 4. Auto-create / merge profile when a user signs up (recommended)
--     - Works when email confirmation is ON (no client session yet).
--     - Reads full_name, role, phone, signup_extras from raw_user_meta_data.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  extra jsonb;
  v_role text;
begin
  begin
    extra := coalesce((meta->>'signup_extras')::jsonb, '{}'::jsonb);
  exception
    when others then
      extra := '{}'::jsonb;
  end;

  v_role := coalesce(nullif(lower(trim(meta->>'role')), ''), 'elderly');
  if v_role not in ('elderly', 'family', 'volunteer') then
    v_role := 'elderly';
  end if;

  insert into public.profiles (id, full_name, role, phone, extras)
  values (
    new.id,
    nullif(trim(meta->>'full_name'), ''),
    v_role,
    nullif(trim(meta->>'phone'), ''),
    extra
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    role = excluded.role,
    phone = coalesce(excluded.phone, public.profiles.phone),
    extras = case
      when excluded.extras = '{}'::jsonb then public.profiles.extras
      else excluded.extras
    end;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
