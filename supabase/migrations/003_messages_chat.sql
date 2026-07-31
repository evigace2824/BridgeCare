-- Family chat backend for CareBridge.
-- Creates a messages table used by the Flutter family chat screen.

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  content text not null default '',
  type text not null default 'text' check (type in ('text', 'voice')),
  voice_duration integer,
  voice_url text,
  created_at timestamptz not null default now()
);

create index if not exists messages_sender_receiver_created_idx
  on public.messages (sender_id, receiver_id, created_at);

alter table public.messages enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'messages'
      and policyname = 'Messages can be read by sender/receiver'
  ) then
    create policy "Messages can be read by sender/receiver"
      on public.messages
      for select
      to authenticated
      using (auth.uid() = sender_id or auth.uid() = receiver_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'messages'
      and policyname = 'Authenticated users can send messages'
  ) then
    create policy "Authenticated users can send messages"
      on public.messages
      for insert
      to authenticated
      with check (auth.uid() = sender_id);
  end if;
end $$;

