-- LNU SkillHub profile feature additive schema.
-- Run manually after reviewing existing Supabase policies. This file is
-- intentionally additive: it does not drop tables, rename columns, or reset data.

alter table public.profiles
  add column if not exists avatar_url text not null default '',
  add column if not exists cover_url text not null default '',
  add column if not exists cv_url text not null default '',
  add column if not exists profile_visibility text not null default 'lnu_public',
  add column if not exists contact_preference text not null default 'Message on SkillHub',
  add column if not exists portfolio_links text[] not null default '{}',
  add column if not exists verified boolean not null default true;

alter table public.posts
  add column if not exists visibility text not null default 'lnu_public',
  add column if not exists is_pinned boolean not null default false,
  add column if not exists saved_count integer not null default 0 check (saved_count >= 0),
  add column if not exists source_profile_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'posts_visibility_check'
      and conrelid = 'public.posts'::regclass
  ) then
    alter table public.posts
      add constraint posts_visibility_check
      check (visibility in ('private', 'connections', 'lnu_public'));
  end if;
end $$;

create table if not exists public.profile_services (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  title text not null default '',
  description text not null default '',
  category text not null default '',
  price_range text not null default '',
  delivery_time text not null default '',
  availability text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_portfolio_items (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  title text not null default '',
  description text not null default '',
  file_url text not null default '',
  external_url text not null default '',
  item_type text not null default 'project',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_reviews (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  commission_id uuid,
  service_title text not null default '',
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now(),
  constraint profile_reviews_no_self_review check (profile_id <> reviewer_id)
);

create table if not exists public.saved_posts (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null default 'reported_from_profile',
  details text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists profile_services_profile_idx
on public.profile_services (profile_id, created_at desc);

create index if not exists profile_portfolio_items_profile_idx
on public.profile_portfolio_items (profile_id, created_at desc);

create index if not exists profile_reviews_profile_idx
on public.profile_reviews (profile_id, created_at desc);

create index if not exists posts_author_visibility_idx
on public.posts (author_id, visibility, created_at desc);

create index if not exists posts_pinned_idx
on public.posts (author_id, is_pinned desc, created_at desc);

create index if not exists post_reports_post_idx
on public.post_reports (post_id, created_at desc);

alter table public.profile_services enable row level security;
alter table public.profile_portfolio_items enable row level security;
alter table public.profile_reviews enable row level security;
alter table public.saved_posts enable row level security;
alter table public.post_reports enable row level security;

comment on column public.posts.visibility is
'private = owner only; connections = accepted student connections only; lnu_public = all verified LNU students.';
comment on column public.posts.is_pinned is
'Only the post owner should be able to pin or unpin their own posts.';
comment on table public.profile_reviews is
'Student profile reviews are append-only for normal users. Admin or moderator moderation should hide/remove abusive reviews outside the student profile page.';

drop policy if exists "profile services lnu read" on public.profile_services;
create policy "profile services lnu read"
on public.profile_services
for select
using (public.is_lnu_email());

drop policy if exists "profile services owner write" on public.profile_services;
create policy "profile services owner write"
on public.profile_services
for all
using (public.is_lnu_email() and auth.uid() = profile_id)
with check (public.is_lnu_email() and auth.uid() = profile_id);

drop policy if exists "profile portfolio lnu read" on public.profile_portfolio_items;
create policy "profile portfolio lnu read"
on public.profile_portfolio_items
for select
using (public.is_lnu_email());

drop policy if exists "profile portfolio owner write" on public.profile_portfolio_items;
create policy "profile portfolio owner write"
on public.profile_portfolio_items
for all
using (public.is_lnu_email() and auth.uid() = profile_id)
with check (public.is_lnu_email() and auth.uid() = profile_id);

drop policy if exists "profile reviews lnu read" on public.profile_reviews;
create policy "profile reviews lnu read"
on public.profile_reviews
for select
using (public.is_lnu_email());

drop policy if exists "profile reviews completed commission insert" on public.profile_reviews;
create policy "profile reviews completed commission insert"
on public.profile_reviews
for insert
with check (
  public.is_lnu_email()
  and auth.uid() = reviewer_id
  and reviewer_id <> profile_id
  and commission_id is not null
);

-- No normal-user UPDATE or DELETE policy is created for profile_reviews.
-- Admin/moderator review moderation should be implemented in a separate admin
-- surface with admin-scoped RLS claims, not in the student profile page.

drop policy if exists "saved posts owner access" on public.saved_posts;
create policy "saved posts owner access"
on public.saved_posts
for all
using (public.is_lnu_email() and auth.uid() = user_id)
with check (public.is_lnu_email() and auth.uid() = user_id);

drop policy if exists "post reports owner insert" on public.post_reports;
create policy "post reports owner insert"
on public.post_reports
for insert
with check (public.is_lnu_email() and auth.uid() = reporter_id);

drop policy if exists "post reports reporter read" on public.post_reports;
create policy "post reports reporter read"
on public.post_reports
for select
using (public.is_lnu_email() and auth.uid() = reporter_id);

-- Policy draft for replacing the older broad "posts lnu read" policy when
-- accepted-connections data exists. Keep lnu_public readable by verified LNU
-- students while restricting private and connections posts.
--
-- drop policy if exists "posts lnu read" on public.posts;
-- create policy "posts visibility read"
-- on public.posts
-- for select
-- using (
--   public.is_lnu_email()
--   and (
--     visibility = 'lnu_public'
--     or auth.uid() = author_id
--     or (
--       visibility = 'connections'
--       and exists (
--         select 1
--         from public.student_connections c
--         where c.status = 'accepted'
--           and (
--             (c.requester_id = auth.uid() and c.addressee_id = posts.author_id)
--             or (c.addressee_id = auth.uid() and c.requester_id = posts.author_id)
--           )
--       )
--     )
--   )
-- );
--
-- drop policy if exists "posts owner update" on public.posts;
-- create policy "posts owner update"
-- on public.posts
-- for update
-- using (public.is_lnu_email() and auth.uid() = author_id)
-- with check (public.is_lnu_email() and auth.uid() = author_id);
--
-- drop policy if exists "posts owner delete" on public.posts;
-- create policy "posts owner delete"
-- on public.posts
-- for delete
-- using (public.is_lnu_email() and auth.uid() = author_id);
