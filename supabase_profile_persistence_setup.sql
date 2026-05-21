-- LNU Student Skills Commission - profile persistence setup/repair.
-- Run this in Supabase SQL Editor if profile picture, cover, CV,
-- portfolio links, or edit-profile changes disappear after app reload.

create extension if not exists pgcrypto;

alter table public.profiles
add column if not exists avatar_url text not null default '',
add column if not exists cover_url text not null default '',
add column if not exists cv_url text not null default '',
add column if not exists portfolio_links text[] not null default '{}',
add column if not exists availability text not null default 'open',
add column if not exists availability_status text not null default 'available',
add column if not exists profile_visibility text not null default 'lnu_public',
add column if not exists updated_at timestamptz not null default now();

create table if not exists public.profile_extras (
  user_id uuid primary key references auth.users(id) on delete cascade,
  cv_url text not null default '',
  portfolio_links text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.profile_extras (user_id, cv_url, portfolio_links)
select uid, coalesce(cv_url, ''), coalesce(portfolio_links, '{}')
from public.profiles
on conflict (user_id) do update
set cv_url = excluded.cv_url,
    portfolio_links = excluded.portfolio_links,
    updated_at = now();

alter table public.profile_extras enable row level security;

drop policy if exists "profile extras owner read" on public.profile_extras;
create policy "profile extras owner read"
on public.profile_extras
for select
using (auth.uid() = user_id);

drop policy if exists "profile extras owner write" on public.profile_extras;
create policy "profile extras owner write"
on public.profile_extras
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

update public.profiles
set avatar_url = profile_picture_url
where coalesce(avatar_url, '') = ''
and coalesce(profile_picture_url, '') <> '';

update public.profiles
set profile_picture_url = avatar_url
where coalesce(profile_picture_url, '') = ''
and coalesce(avatar_url, '') <> '';

insert into storage.buckets (id, name, public)
values ('profile-media', 'profile-media', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('profile-documents', 'profile-documents', true)
on conflict (id) do update set public = true;

drop policy if exists "profile media authenticated read" on storage.objects;
create policy "profile media authenticated read"
on storage.objects for select
using (bucket_id in ('profile-media', 'profile-documents') and auth.uid() is not null);

drop policy if exists "profile media owner upload" on storage.objects;
create policy "profile media owner upload"
on storage.objects for insert
with check (
  bucket_id in ('profile-media', 'profile-documents')
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "profile media owner update" on storage.objects;
create policy "profile media owner update"
on storage.objects for update
using (
  bucket_id in ('profile-media', 'profile-documents')
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id in ('profile-media', 'profile-documents')
  and auth.uid()::text = (storage.foldername(name))[1]
);
