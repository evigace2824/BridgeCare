-- Family ↔ patient linking for CareBridge.
-- Run in Supabase → SQL Editor.

alter table if exists public.users
  add column if not exists linked_elderly_user_id uuid references public.users (id) on delete set null;

create index if not exists users_linked_elderly_user_id_idx
  on public.users (linked_elderly_user_id);

-- Links the signed-in family member to a patient by shareable code.
create or replace function public.link_family_to_patient(link_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  fam_id uuid := auth.uid();
  patient_id uuid;
  patient_name text;
  cleaned text := nullif(trim(link_code), '');
begin
  if fam_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if cleaned is null then
    return jsonb_build_object('ok', false, 'error', 'empty_code');
  end if;

  select u.id,
         coalesce(nullif(trim(u.name), ''), nullif(trim(u.full_name), ''), 'Patient')
  into patient_id, patient_name
  from public.users u
  where u.family_verification_code = cleaned
    and lower(coalesce(u.role, '')) in ('elderly', 'patient', 'user')
    and u.id <> fam_id
  limit 1;

  if patient_id is null then
    return jsonb_build_object('ok', false, 'error', 'code_not_found');
  end if;

  update public.users
  set family_verification_code = cleaned,
      linked_elderly_user_id = patient_id
  where id = fam_id
    and lower(coalesce(role, '')) in ('family', 'caregiver');

  return jsonb_build_object(
    'ok', true,
    'patient_id', patient_id,
    'patient_name', patient_name
  );
end;
$$;

-- Returns the patient linked to the signed-in family caregiver.
create or replace function public.get_linked_elderly_for_family_member()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  fam record;
  patient_row public.users%rowtype;
begin
  select id, role, family_verification_code, linked_elderly_user_id
  into fam
  from public.users
  where id = auth.uid();

  if fam.id is null
     or lower(coalesce(fam.role, '')) not in ('family', 'caregiver') then
    return jsonb_build_object('ok', false, 'error', 'not_family');
  end if;

  if fam.linked_elderly_user_id is not null then
    select * into patient_row
    from public.users
    where id = fam.linked_elderly_user_id
      and lower(coalesce(role, '')) in ('elderly', 'patient', 'user');
  elsif fam.family_verification_code is not null
        and trim(fam.family_verification_code) <> '' then
    select * into patient_row
    from public.users
    where family_verification_code = trim(fam.family_verification_code)
      and lower(coalesce(role, '')) in ('elderly', 'patient', 'user')
      and id <> fam.id
    limit 1;
  end if;

  if patient_row.id is null then
    return jsonb_build_object('ok', false, 'error', 'not_linked');
  end if;

  return jsonb_build_object(
    'ok', true,
    'patient', jsonb_build_object(
      'id', patient_row.id,
      'name', patient_row.name,
      'full_name', patient_row.name,
      'phone_number', patient_row.phone_number,
      'role', patient_row.role,
      'family_verification_code', patient_row.family_verification_code
    )
  );
end;
$$;

-- Returns a family member linked to the signed-in elderly patient.
create or replace function public.get_linked_family_for_elderly()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  me record;
  family_row public.users%rowtype;
begin
  select id, role, family_verification_code
  into me
  from public.users
  where id = auth.uid();

  if me.id is null
     or lower(coalesce(me.role, '')) not in ('elderly', 'patient', 'user') then
    return jsonb_build_object('ok', false, 'error', 'not_elderly');
  end if;

  if me.family_verification_code is null or trim(me.family_verification_code) = '' then
    return jsonb_build_object('ok', false, 'error', 'no_link_code');
  end if;

  select * into family_row
  from public.users
  where lower(coalesce(role, '')) in ('family', 'caregiver')
    and (
      family_verification_code = trim(me.family_verification_code)
      or linked_elderly_user_id = me.id
    )
  order by created_at desc nulls last
  limit 1;

  if family_row.id is null then
    return jsonb_build_object('ok', false, 'error', 'not_linked');
  end if;

  return jsonb_build_object(
    'ok', true,
    'family_member', jsonb_build_object(
      'id', family_row.id,
      'name', family_row.name,
      'phone_number', family_row.phone_number,
      'role', family_row.role
    )
  );
end;
$$;

revoke all on function public.link_family_to_patient(text) from public;
revoke all on function public.get_linked_elderly_for_family_member() from public;
revoke all on function public.get_linked_family_for_elderly() from public;

grant execute on function public.link_family_to_patient(text) to authenticated;
grant execute on function public.get_linked_elderly_for_family_member() to authenticated;
grant execute on function public.get_linked_family_for_elderly() to authenticated;
