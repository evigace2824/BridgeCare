-- BridgeCare — Stripe subscription ledger (source of truth via webhooks).
-- Run in Supabase SQL Editor after deploying Edge Functions.
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE where possible.

-- ---------------------------------------------------------------------------
-- 0. Helper (from 001_initial_profiles — included in case 001 was not run)
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

-- ---------------------------------------------------------------------------
-- 1. Stripe customer mapping (one per user)
-- ---------------------------------------------------------------------------
create table if not exists public.stripe_customers (
  user_id uuid primary key references auth.users (id) on delete cascade,
  stripe_customer_id text not null unique,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stripe_customers_stripe_id_idx
  on public.stripe_customers (stripe_customer_id);

-- ---------------------------------------------------------------------------
-- 2. Subscriptions (mirrors Stripe subscription object)
-- ---------------------------------------------------------------------------
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  stripe_subscription_id text not null unique,
  stripe_customer_id text not null,
  status text not null default 'incomplete'
    check (status in (
      'active', 'trialing', 'past_due', 'canceled', 'unpaid',
      'incomplete', 'incomplete_expired', 'paused'
    )),
  plan_role text not null check (plan_role in ('family', 'volunteer')),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  stripe_price_id text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  canceled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subscriptions_user_id_idx on public.subscriptions (user_id);
create index if not exists subscriptions_status_idx on public.subscriptions (status);

-- ---------------------------------------------------------------------------
-- 3. Payment events audit log (optional receipts)
-- ---------------------------------------------------------------------------
create table if not exists public.subscription_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  stripe_invoice_id text unique,
  stripe_payment_intent_id text,
  amount_cents integer not null,
  currency text not null default 'usd',
  status text not null,
  created_at timestamptz not null default now()
);

create index if not exists subscription_payments_user_idx
  on public.subscription_payments (user_id);

-- ---------------------------------------------------------------------------
-- 4. updated_at triggers
-- ---------------------------------------------------------------------------
drop trigger if exists stripe_customers_updated_at on public.stripe_customers;
create trigger stripe_customers_updated_at
  before update on public.stripe_customers
  for each row execute function public.set_updated_at();

drop trigger if exists subscriptions_updated_at on public.subscriptions;
create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. Sync profiles.extras from active subscription (called by webhook)
-- ---------------------------------------------------------------------------
create or replace function public.sync_profile_subscription(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  sub record;
  extras jsonb;
  v_status text;
  v_cycle text;
  v_expires timestamptz;
begin
  select *
  into sub
  from public.subscriptions s
  where s.user_id = p_user_id
    and s.status in ('active', 'trialing')
  order by s.current_period_end desc nulls last
  limit 1;

  select extras into extras from public.profiles where id = p_user_id;
  extras := coalesce(extras, '{}'::jsonb);

  if sub.id is null then
    extras := extras
      || jsonb_build_object(
        'subscription_status', 'free',
        'subscription_updated_at', now()
      )
      - 'premium_expires_at';
  else
    v_status := 'premium';
    v_cycle := sub.billing_cycle;
    v_expires := sub.current_period_end;
    extras := extras || jsonb_build_object(
      'subscription_status', v_status,
      'billing_cycle', v_cycle,
      'premium_expires_at', v_expires,
      'subscription_updated_at', now(),
      'stripe_subscription_id', sub.stripe_subscription_id
    );
  end if;

  update public.profiles
  set extras = extras, updated_at = now()
  where id = p_user_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Row Level Security
-- ---------------------------------------------------------------------------
alter table public.stripe_customers enable row level security;
alter table public.subscriptions enable row level security;
alter table public.subscription_payments enable row level security;

drop policy if exists "stripe_customers_select_own" on public.stripe_customers;
create policy "stripe_customers_select_own"
  on public.stripe_customers for select
  using (auth.uid() = user_id);

drop policy if exists "subscriptions_select_own" on public.subscriptions;
create policy "subscriptions_select_own"
  on public.subscriptions for select
  using (auth.uid() = user_id);

drop policy if exists "subscription_payments_select_own" on public.subscription_payments;
create policy "subscription_payments_select_own"
  on public.subscription_payments for select
  using (auth.uid() = user_id);

-- Writes only via service role (Edge Functions / webhooks).
