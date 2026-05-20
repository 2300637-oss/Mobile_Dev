-- Run this in Supabase SQL Editor to enable realtime chat access.
-- It creates the chat tables, keeps RLS enabled, and adds the policies
-- the Flutter app expects.

create extension if not exists pgcrypto;

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  last_message_text text not null default '',
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null default '',
  attachment_url text not null default '',
  attachment_name text not null default '',
  attachment_type text not null default '',
  seen_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.typing_status (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  is_typing boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.chat_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  body text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.conversations add column if not exists last_message_text text not null default '';
alter table public.conversations add column if not exists last_message_at timestamptz;
alter table public.conversations add column if not exists created_at timestamptz not null default now();
alter table public.conversations add column if not exists updated_at timestamptz not null default now();

alter table public.conversation_participants add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
alter table public.conversation_participants add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.conversation_participants add column if not exists display_name text not null default '';
alter table public.conversation_participants add column if not exists joined_at timestamptz not null default now();

alter table public.messages add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
alter table public.messages add column if not exists sender_id uuid references auth.users(id) on delete cascade;
alter table public.messages add column if not exists body text not null default '';
alter table public.messages add column if not exists attachment_url text not null default '';
alter table public.messages add column if not exists attachment_name text not null default '';
alter table public.messages add column if not exists attachment_type text not null default '';
alter table public.messages add column if not exists seen_at timestamptz;
alter table public.messages add column if not exists created_at timestamptz not null default now();

alter table public.typing_status add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
alter table public.typing_status add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.typing_status add column if not exists is_typing boolean not null default false;
alter table public.typing_status add column if not exists updated_at timestamptz not null default now();

alter table public.chat_notifications add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.chat_notifications add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
alter table public.chat_notifications add column if not exists sender_id uuid references auth.users(id) on delete cascade;
alter table public.chat_notifications add column if not exists title text not null default '';
alter table public.chat_notifications add column if not exists body text not null default '';
alter table public.chat_notifications add column if not exists read_at timestamptz;
alter table public.chat_notifications add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.conversation_participants'::regclass
    and contype = 'p'
  ) then
    alter table public.conversation_participants
    add constraint conversation_participants_pkey
    primary key (conversation_id, user_id);
  end if;
end $$;

create index if not exists conversation_participants_user_id_idx
on public.conversation_participants (user_id);

create index if not exists messages_conversation_created_at_idx
on public.messages (conversation_id, created_at);

create index if not exists chat_notifications_user_created_at_idx
on public.chat_notifications (user_id, created_at desc);

create or replace function public.is_lnu_email()
returns boolean
language sql
stable
as $$
  select auth.jwt() ->> 'email' like '%@lnu.edu.ph'
$$;

create or replace function public.is_conversation_participant(target_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = target_conversation_id
    and cp.user_id = auth.uid()
  )
$$;

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.typing_status enable row level security;
alter table public.chat_notifications enable row level security;

drop policy if exists "conversations participant read" on public.conversations;
create policy "conversations participant read"
on public.conversations
for select
using (
  public.is_lnu_email()
  and public.is_conversation_participant(id)
);

drop policy if exists "conversations lnu create" on public.conversations;
create policy "conversations lnu create"
on public.conversations
for insert
with check (public.is_lnu_email());

drop policy if exists "conversations participant update" on public.conversations;
create policy "conversations participant update"
on public.conversations
for update
using (
  public.is_lnu_email()
  and public.is_conversation_participant(id)
)
with check (
  public.is_lnu_email()
  and public.is_conversation_participant(id)
);

drop policy if exists "conversation participants read own conversations" on public.conversation_participants;
create policy "conversation participants read own conversations"
on public.conversation_participants
for select
using (
  public.is_lnu_email()
  and public.is_conversation_participant(conversation_id)
);

drop policy if exists "conversation participants create" on public.conversation_participants;
create policy "conversation participants create"
on public.conversation_participants
for insert
with check (public.is_lnu_email());

drop policy if exists "messages participant read" on public.messages;
create policy "messages participant read"
on public.messages
for select
using (
  public.is_lnu_email()
  and public.is_conversation_participant(conversation_id)
);

drop policy if exists "messages participant create" on public.messages;
create policy "messages participant create"
on public.messages
for insert
with check (
  public.is_lnu_email()
  and sender_id = auth.uid()
  and public.is_conversation_participant(conversation_id)
);

drop policy if exists "messages receiver seen update" on public.messages;
create policy "messages receiver seen update"
on public.messages
for update
using (
  public.is_lnu_email()
  and sender_id <> auth.uid()
  and public.is_conversation_participant(conversation_id)
)
with check (
  public.is_lnu_email()
  and sender_id <> auth.uid()
  and public.is_conversation_participant(conversation_id)
);

drop policy if exists "typing participant read" on public.typing_status;
create policy "typing participant read"
on public.typing_status
for select
using (
  public.is_lnu_email()
  and public.is_conversation_participant(conversation_id)
);

drop policy if exists "typing owner upsert" on public.typing_status;
create policy "typing owner upsert"
on public.typing_status
for all
using (public.is_lnu_email() and user_id = auth.uid())
with check (
  public.is_lnu_email()
  and user_id = auth.uid()
  and public.is_conversation_participant(conversation_id)
);

drop policy if exists "chat notifications owner read" on public.chat_notifications;
create policy "chat notifications owner read"
on public.chat_notifications
for select
using (public.is_lnu_email() and user_id = auth.uid());

drop policy if exists "chat notifications participant create" on public.chat_notifications;
create policy "chat notifications participant create"
on public.chat_notifications
for insert
with check (
  public.is_lnu_email()
  and sender_id = auth.uid()
  and public.is_conversation_participant(conversation_id)
);

do $$
begin
  alter publication supabase_realtime add table public.conversations;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.conversation_participants;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.typing_status;
exception when duplicate_object then null;
end $$;
