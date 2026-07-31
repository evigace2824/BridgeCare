-- Storage bucket and policies for voice notes.

insert into storage.buckets (id, name, public)
values ('messages', 'messages', true)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Authenticated users can upload message audio'
  ) then
    create policy "Authenticated users can upload message audio"
      on storage.objects
      for insert
      to authenticated
      with check (bucket_id = 'messages');
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Message audio is publicly readable'
  ) then
    create policy "Message audio is publicly readable"
      on storage.objects
      for select
      to public
      using (bucket_id = 'messages');
  end if;
end $$;

