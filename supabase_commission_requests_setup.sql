-- LNU Student Skills Commission - commission requests setup/repair.
-- Run this in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.commission_requests (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references public.profile_services(id) on delete set null,
  service_title text not null default '',
  client_id uuid not null references auth.users(id) on delete cascade,
  client_name text not null default 'LNU student',
  provider_id uuid not null references auth.users(id) on delete cascade,
  provider_name text not null default 'LNU student',
  note text not null default '',
  status text not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.commission_requests
add column if not exists service_id uuid references public.profile_services(id) on delete set null,
add column if not exists service_title text not null default '',
add column if not exists client_id uuid references auth.users(id) on delete cascade,
add column if not exists client_name text not null default 'LNU student',
add column if not exists provider_id uuid references auth.users(id) on delete cascade,
add column if not exists provider_name text not null default 'LNU student',
add column if not exists note text not null default '',
add column if not exists status text not null default 'pending',
add column if not exists completed_at timestamptz,
add column if not exists created_at timestamptz not null default now(),
add column if not exists updated_at timestamptz not null default now();

do $$
begin
  alter table public.commission_requests
  add constraint commission_requests_status_check
  check (status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled'));
exception
  when duplicate_object then null;
end $$;

create index if not exists commission_requests_client_created_idx
on public.commission_requests (client_id, created_at desc);

create index if not exists commission_requests_provider_created_idx
on public.commission_requests (provider_id, created_at desc);

alter table public.commission_requests enable row level security;

drop policy if exists "commission requests participant read" on public.commission_requests;
create policy "commission requests participant read"
on public.commission_requests
for select
using (auth.uid() = client_id or auth.uid() = provider_id);

drop policy if exists "commission requests client create" on public.commission_requests;
create policy "commission requests client create"
on public.commission_requests
for insert
with check (auth.uid() = client_id and auth.uid() <> provider_id);

drop policy if exists "commission requests provider update" on public.commission_requests;
create policy "commission requests provider update"
on public.commission_requests
for update
using (auth.uid() = provider_id)
with check (auth.uid() = provider_id);

drop policy if exists "commission requests client update own" on public.commission_requests;
create policy "commission requests client update own"
on public.commission_requests
for update
using (auth.uid() = client_id)
with check (auth.uid() = client_id);

do $$
begin
  alter publication supabase_realtime add table public.commission_requests;
exception
  when duplicate_object then null;
end $$;
