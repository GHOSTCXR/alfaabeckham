-- Create the monitoring and chat schema for the new Supabase project.
-- Run this in Supabase SQL editor after creating the project.

create extension if not exists pgcrypto;
create extension if not exists citext;

create table if not exists public.product_stock (
  id text primary key,
  stock integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  visitor_name text,
  visitor_email text,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender text not null check (sender in ('visitor','admin')),
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.app_admins (
  id uuid primary key default gen_random_uuid(),
  email citext not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.error_logs (
  id uuid primary key default gen_random_uuid(),
  dedupe_key text not null unique,
  error_type text not null default 'unknown',
  error_message text not null default 'Unknown error',
  stack_trace text,
  page_url text,
  route text,
  timestamp timestamptz not null default now(),
  browser text,
  browser_version text,
  operating_system text,
  device_type text,
  screen_width integer,
  screen_height integer,
  request_url text,
  request_method text,
  http_status integer,
  response_time_ms integer,
  user_agent text,
  occurrence_count integer not null default 1,
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  status text not null default 'open' check (status in ('open','investigating','resolved')),
  additional_metadata jsonb not null default '{}'::jsonb,
  site_url text
);

create table if not exists public.customer_reports (
  id uuid primary key default gen_random_uuid(),
  description text not null,
  page_url text,
  route text,
  browser text,
  device_type text,
  screen_width integer,
  screen_height integer,
  timestamp timestamptz not null default now(),
  additional_metadata jsonb not null default '{}'::jsonb
);

create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.app_admins a
    where lower(a.email) = lower(auth.email())
      and a.active = true
  );
$$;

alter table public.product_stock enable row level security;
alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;
alter table public.app_admins enable row level security;
alter table public.error_logs enable row level security;
alter table public.customer_reports enable row level security;

-- Public product stock access for the public storefront.
drop policy if exists "product_stock_select_public" on public.product_stock;
create policy "product_stock_select_public"
on public.product_stock
for select
using (true);

-- Public chat insert for visitors; admin reads/writes own chat thread.
drop policy if exists "chat_conversations_insert_public" on public.chat_conversations;
create policy "chat_conversations_insert_public"
on public.chat_conversations
for insert
with check (true);

drop policy if exists "chat_conversations_admin_read" on public.chat_conversations;
create policy "chat_conversations_admin_read"
on public.chat_conversations
for select
using (public.is_admin_user());

drop policy if exists "chat_conversations_admin_update" on public.chat_conversations;
create policy "chat_conversations_admin_update"
on public.chat_conversations
for update
using (public.is_admin_user())
with check (public.is_admin_user());

drop policy if exists "chat_messages_insert_public" on public.chat_messages;
create policy "chat_messages_insert_public"
on public.chat_messages
for insert
with check (true);

drop policy if exists "chat_messages_admin_read" on public.chat_messages;
create policy "chat_messages_admin_read"
on public.chat_messages
for select
using (public.is_admin_user());

drop policy if exists "chat_messages_admin_update" on public.chat_messages;
create policy "chat_messages_admin_update"
on public.chat_messages
for update
using (public.is_admin_user())
with check (public.is_admin_user());

-- Admin-only monitoring and reports.
drop policy if exists "app_admins_admin_only" on public.app_admins;
create policy "app_admins_admin_only"
on public.app_admins
for all
using (public.is_admin_user())
with check (public.is_admin_user());

drop policy if exists "error_logs_insert_anyone" on public.error_logs;
create policy "error_logs_insert_anyone"
on public.error_logs
for insert
with check (true);

drop policy if exists "error_logs_admin_only" on public.error_logs;
create policy "error_logs_admin_only"
on public.error_logs
for select
using (public.is_admin_user());

drop policy if exists "error_logs_update_admin_only" on public.error_logs;
create policy "error_logs_update_admin_only"
on public.error_logs
for update
using (public.is_admin_user())
with check (public.is_admin_user());

drop policy if exists "error_logs_delete_admin_only" on public.error_logs;
create policy "error_logs_delete_admin_only"
on public.error_logs
for delete
using (public.is_admin_user());

drop policy if exists "customer_reports_insert_anyone" on public.customer_reports;
create policy "customer_reports_insert_anyone"
on public.customer_reports
for insert
with check (true);

drop policy if exists "customer_reports_admin_only" on public.customer_reports;
create policy "customer_reports_admin_only"
on public.customer_reports
for select
using (public.is_admin_user());

drop policy if exists "customer_reports_update_admin_only" on public.customer_reports;
create policy "customer_reports_update_admin_only"
on public.customer_reports
for update
using (public.is_admin_user())
with check (public.is_admin_user());

drop policy if exists "customer_reports_delete_admin_only" on public.customer_reports;
create policy "customer_reports_delete_admin_only"
on public.customer_reports
for delete
using (public.is_admin_user());

-- Replace with your real admin email.
insert into public.app_admins (email)
values ('alfabeckham74@gmail.com')
on conflict (email) do nothing;

-- Seed initial stock row used by the storefront app.
insert into public.product_stock (id, stock)
values ('breakthrough-eyonu-agba', 200)
on conflict (id) do nothing;
