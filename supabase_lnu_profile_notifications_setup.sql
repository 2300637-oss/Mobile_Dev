-- LNU Student Skills Commission persistence setup.
-- Run this once in Supabase SQL Editor.
-- It creates profile posts, portfolio items, follows, notifications,
-- storage buckets, and post reaction/share notification hooks.

create extension if not exists pgcrypto;

create table if not exists public.profile_posts (
  id uuid primary key default gen_random_uuid(),
  profile_id text not null,
  author_id uuid not null references auth.users(id) on delete cascade,
  content text not null default '',
  visibility text not null default 'lnu_public',
  attachment_url text not null default '',
  attachment_type text not null default '',
  attachment_label text not null default '',
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_portfolio_items (
  id uuid primary key default gen_random_uuid(),
  profile_id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null default '',
  description text not null default '',
  file_url text not null default '',
  external_url text not null default '',
  item_type text not null default 'project',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_services (
  id uuid primary key default gen_random_uuid(),
  profile_id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null default '',
  description text not null default '',
  category text not null default 'General',
  price_range text not null default '',
  delivery_time text not null default '',
  availability text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_reviews (
  id uuid primary key default gen_random_uuid(),
  profile_id text not null,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  reviewer_name text not null default '',
  reviewer_initials text not null default '',
  service_title text not null default '',
  rating integer not null default 5 check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.commission_requests (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references public.profile_services(id) on delete set null,
  service_title text not null default '',
  client_id uuid not null references auth.users(id) on delete cascade,
  client_name text not null default 'LNU student',
  provider_id uuid not null references auth.users(id) on delete cascade,
  provider_name text not null default 'LNU student',
  note text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
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

create table if not exists public.user_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint user_follows_not_self check (follower_id <> following_id)
);

create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  type text not null default 'general',
  title text not null default '',
  body text not null default '',
  target_type text not null default '',
  target_id text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles
add column if not exists avatar_url text not null default '',
add column if not exists cover_url text not null default '',
add column if not exists cv_url text not null default '',
add column if not exists portfolio_links text[] not null default '{}',
add column if not exists availability text not null default 'open',
add column if not exists profile_visibility text not null default 'lnu_public';

create index if not exists profile_posts_author_created_idx
on public.profile_posts (author_id, created_at desc);

create index if not exists profile_posts_profile_created_idx
on public.profile_posts (profile_id, created_at desc);

create index if not exists profile_portfolio_items_profile_created_idx
on public.profile_portfolio_items (profile_id, created_at desc);

create index if not exists profile_services_profile_created_idx
on public.profile_services (profile_id, created_at desc);

create index if not exists profile_reviews_profile_created_idx
on public.profile_reviews (profile_id, created_at desc);

create index if not exists commission_requests_client_created_idx
on public.commission_requests (client_id, created_at desc);

create index if not exists commission_requests_provider_created_idx
on public.commission_requests (provider_id, created_at desc);

create index if not exists user_follows_following_idx
on public.user_follows (following_id);

create index if not exists app_notifications_user_created_idx
on public.app_notifications (user_id, created_at desc);

delete from public.app_notifications a
using public.app_notifications b
where a.ctid < b.ctid
and a.user_id = b.user_id
and coalesce(a.actor_id, '00000000-0000-0000-0000-000000000000'::uuid)
  = coalesce(b.actor_id, '00000000-0000-0000-0000-000000000000'::uuid)
and a.type = b.type
and a.title = b.title
and a.body = b.body
and a.target_type = b.target_type
and a.target_id = b.target_id;

delete from public.post_shares a
using public.post_shares b
where a.ctid < b.ctid
and a.post_id = b.post_id
and a.user_id = b.user_id;

do $$
begin
  alter table public.post_shares
  add constraint post_shares_post_user_unique unique (post_id, user_id);
exception
  when duplicate_object then null;
  when duplicate_table then null;
end $$;

alter table public.profile_posts enable row level security;
alter table public.profile_portfolio_items enable row level security;
alter table public.profile_services enable row level security;
alter table public.profile_reviews enable row level security;
alter table public.commission_requests enable row level security;
alter table public.user_follows enable row level security;
alter table public.app_notifications enable row level security;

drop policy if exists "profile posts lnu read" on public.profile_posts;
create policy "profile posts lnu read"
on public.profile_posts
for select
using (auth.uid() is not null);

drop policy if exists "profile posts owner create" on public.profile_posts;
create policy "profile posts owner create"
on public.profile_posts
for insert
with check (auth.uid() = author_id);

drop policy if exists "profile posts owner update" on public.profile_posts;
create policy "profile posts owner update"
on public.profile_posts
for update
using (auth.uid() = author_id)
with check (auth.uid() = author_id);

drop policy if exists "profile posts owner delete" on public.profile_posts;
create policy "profile posts owner delete"
on public.profile_posts
for delete
using (auth.uid() = author_id);

drop policy if exists "portfolio lnu read" on public.profile_portfolio_items;
create policy "portfolio lnu read"
on public.profile_portfolio_items
for select
using (auth.uid() is not null);

drop policy if exists "portfolio owner create" on public.profile_portfolio_items;
create policy "portfolio owner create"
on public.profile_portfolio_items
for insert
with check (auth.uid() = user_id);

drop policy if exists "portfolio owner update" on public.profile_portfolio_items;
create policy "portfolio owner update"
on public.profile_portfolio_items
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "portfolio owner delete" on public.profile_portfolio_items;
create policy "portfolio owner delete"
on public.profile_portfolio_items
for delete
using (auth.uid() = user_id);

drop policy if exists "services lnu read" on public.profile_services;
create policy "services lnu read"
on public.profile_services
for select
using (auth.uid() is not null);

drop policy if exists "services owner create" on public.profile_services;
create policy "services owner create"
on public.profile_services
for insert
with check (auth.uid() = user_id);

drop policy if exists "services owner update" on public.profile_services;
create policy "services owner update"
on public.profile_services
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "services owner delete" on public.profile_services;
create policy "services owner delete"
on public.profile_services
for delete
using (auth.uid() = user_id);

drop policy if exists "reviews lnu read" on public.profile_reviews;
create policy "reviews lnu read"
on public.profile_reviews
for select
using (auth.uid() is not null);

drop policy if exists "reviews owner create" on public.profile_reviews;
create policy "reviews owner create"
on public.profile_reviews
for insert
with check (auth.uid() = reviewer_id);

drop policy if exists "commission requests participant read" on public.commission_requests;
create policy "commission requests participant read"
on public.commission_requests
for select
using (auth.uid() = client_id or auth.uid() = provider_id);

drop policy if exists "commission requests client create" on public.commission_requests;
create policy "commission requests client create"
on public.commission_requests
for insert
with check (auth.uid() = client_id);

drop policy if exists "commission requests participant update" on public.commission_requests;
create policy "commission requests participant update"
on public.commission_requests
for update
using (auth.uid() = client_id or auth.uid() = provider_id)
with check (auth.uid() = client_id or auth.uid() = provider_id);

drop policy if exists "follows lnu read" on public.user_follows;
create policy "follows lnu read"
on public.user_follows
for select
using (auth.uid() is not null);

drop policy if exists "follows owner create" on public.user_follows;
create policy "follows owner create"
on public.user_follows
for insert
with check (auth.uid() = follower_id);

drop policy if exists "follows owner delete" on public.user_follows;
create policy "follows owner delete"
on public.user_follows
for delete
using (auth.uid() = follower_id);

drop policy if exists "notifications owner read" on public.app_notifications;
create policy "notifications owner read"
on public.app_notifications
for select
using (auth.uid() = user_id);

drop policy if exists "notifications owner update" on public.app_notifications;
create policy "notifications owner update"
on public.app_notifications
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "notifications authenticated create" on public.app_notifications;
create policy "notifications authenticated create"
on public.app_notifications
for insert
with check (auth.uid() is not null);

insert into storage.buckets (id, name, public)
values ('profile-media', 'profile-media', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('profile-documents', 'profile-documents', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('chat-attachments', 'chat-attachments', true)
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

drop policy if exists "chat attachments authenticated read" on storage.objects;
create policy "chat attachments authenticated read"
on storage.objects for select
using (bucket_id = 'chat-attachments' and auth.uid() is not null);

drop policy if exists "chat attachments owner upload" on storage.objects;
create policy "chat attachments owner upload"
on storage.objects for insert
with check (
  bucket_id = 'chat-attachments'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "chat attachments owner update" on storage.objects;
create policy "chat attachments owner update"
on storage.objects for update
using (
  bucket_id = 'chat-attachments'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'chat-attachments'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create or replace function public.notify_user(
  target_user_id uuid,
  actor_user_id uuid,
  notification_type text,
  notification_title text,
  notification_body text,
  notification_target_type text default '',
  notification_target_id text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_user_id is null or target_user_id = actor_user_id then
    return;
  end if;

  if exists (
    select 1
    from public.app_notifications
    where user_id = target_user_id
    and coalesce(actor_id, '00000000-0000-0000-0000-000000000000'::uuid)
      = coalesce(actor_user_id, '00000000-0000-0000-0000-000000000000'::uuid)
    and type = notification_type
    and title = notification_title
    and body = notification_body
    and target_type = notification_target_type
    and target_id = notification_target_id
    and created_at > now() - interval '1 day'
  ) then
    return;
  end if;

  insert into public.app_notifications (
    user_id, actor_id, type, title, body, target_type, target_id
  )
  values (
    target_user_id,
    actor_user_id,
    notification_type,
    notification_title,
    notification_body,
    notification_target_type,
    notification_target_id
  );
end;
$$;

create or replace function public.toggle_post_heart(target_post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  post_owner uuid;
  post_caption text;
begin
  select author_id, caption
  into post_owner, post_caption
  from public.posts
  where id = target_post_id;

  if exists (
    select 1 from public.post_reactions
    where post_id = target_post_id and user_id = auth.uid()
  ) then
    delete from public.post_reactions
    where post_id = target_post_id and user_id = auth.uid();

    update public.posts
    set heart_count = greatest(coalesce(heart_count, 0) - 1, 0),
        updated_at = now()
    where id = target_post_id;
  else
    insert into public.post_reactions (post_id, user_id, type)
    values (target_post_id, auth.uid(), 'heart')
    on conflict do nothing;

    update public.posts
    set heart_count = coalesce(heart_count, 0) + 1,
        updated_at = now()
    where id = target_post_id;

    perform public.notify_user(
      post_owner,
      auth.uid(),
      'heart',
      'New heart reaction',
      left(coalesce(post_caption, 'Someone liked your post.'), 140),
      'post',
      target_post_id::text
    );
  end if;
end;
$$;

create or replace function public.mark_post_shared(target_post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  post_owner uuid;
  post_caption text;
  inserted_count integer;
begin
  select author_id, caption
  into post_owner, post_caption
  from public.posts
  where id = target_post_id;

  insert into public.post_shares (post_id, user_id)
  values (target_post_id, auth.uid())
  on conflict on constraint post_shares_post_user_unique do nothing;

  get diagnostics inserted_count = row_count;

  if inserted_count = 0 then
    return;
  end if;

  update public.posts
  set share_count = coalesce(share_count, 0) + 1,
      updated_at = now()
  where id = target_post_id;

  perform public.notify_user(
    post_owner,
    auth.uid(),
    'share',
    'Your post was shared',
    left(coalesce(post_caption, 'Someone shared your post.'), 140),
    'post',
    target_post_id::text
  );
end;
$$;

do $$
begin
  alter publication supabase_realtime add table public.profile_posts;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.profile_portfolio_items;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.profile_services;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.profile_reviews;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.commission_requests;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.user_follows;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.app_notifications;
exception when duplicate_object then null;
end $$;
