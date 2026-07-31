-- Lets caregivers validate a patient's family link code during sign-up
-- (before they have a session). Run in Supabase SQL Editor.

create or replace function public.validate_family_link_code(link_code text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.family_verification_code = nullif(trim(link_code), '')
      and lower(coalesce(u.role, '')) in ('elderly', 'patient', 'user')
  );
$$;

revoke all on function public.validate_family_link_code(text) from public;
grant execute on function public.validate_family_link_code(text) to anon, authenticated;
