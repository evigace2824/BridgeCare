-- Premium family job posts (48-hour active window).
-- TODO: Add RLS policies matching your auth model before production.

create table if not exists public.job_posts (
  id text primary key,
  title text not null,
  care_type text not null default 'Home care',
  description text not null,
  location text not null,
  preferred_at timestamptz not null,
  duration_label text not null default 'Flexible',
  urgency text not null default 'medium',
  budget text,
  created_by uuid references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  linked_elderly_user_id uuid,
  linked_elderly_name text,
  status text not null default 'active'
    check (status in ('active', 'accepted', 'in_progress', 'completed', 'expired')),
  accepted_by text
);

create index if not exists job_posts_created_by_idx on public.job_posts (created_by);
create index if not exists job_posts_expires_at_idx on public.job_posts (expires_at);

-- Optional notifications table for volunteer alerts.
-- TODO: Add user_id column + RLS so volunteers only see their notifications.
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  type text not null default 'general',
  title text not null,
  body text not null,
  related_id text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);
