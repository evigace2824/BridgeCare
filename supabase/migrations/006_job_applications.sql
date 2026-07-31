-- Volunteer applications to premium family job posts.
-- TODO: Add RLS policies before production.

create table if not exists public.job_applications (
  id text primary key,
  job_post_id text not null references public.job_posts (id) on delete cascade,
  volunteer_id text not null,
  volunteer_name text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected')),
  rating double precision default 4.5,
  trust_level text default 'Verified',
  completed_tasks integer default 0,
  skills text[] default '{}',
  distance_km double precision default 2.0,
  message text,
  verification_status text default 'Verified',
  transport_method text default 'On foot',
  availability_confirmed boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists job_applications_post_idx
  on public.job_applications (job_post_id);

-- Allow confirmed status on job posts.
alter table public.job_posts
  drop constraint if exists job_posts_status_check;

alter table public.job_posts
  add constraint job_posts_status_check
  check (status in (
    'active',
    'accepted',
    'in_progress',
    'completed',
    'confirmed',
    'expired'
  ));
