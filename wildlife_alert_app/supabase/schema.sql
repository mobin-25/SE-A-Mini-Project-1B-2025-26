-- Required once in your database
create extension if not exists "pgcrypto";

-- Main alerts table
create table if not exists public.alerts (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  image_url text,
  user_id uuid not null references auth.users(id) on delete cascade,
  user_email text,
  priority text not null default 'Medium' check (priority in ('Low', 'Medium', 'High', 'Critical')),
  status text not null default 'Open' check (status in ('Open', 'In Progress', 'Resolved')),
  latitude float,
  longitude float,
  location_address text,
  category text default 'Other' check (category in ('Fire', 'Flood', 'Medical', 'Crime', 'Accident', 'Other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists alerts_created_at_idx on public.alerts (created_at desc);
create index if not exists alerts_user_id_idx on public.alerts (user_id);
create index if not exists alerts_priority_idx on public.alerts (priority);
create index if not exists alerts_status_idx on public.alerts (status);
create index if not exists alerts_category_idx on public.alerts (category);
create index if not exists alerts_location_idx on public.alerts using gist (point(longitude, latitude));

alter table public.alerts enable row level security;

-- Authenticated users can read all alerts
drop policy if exists "alerts_select_authenticated" on public.alerts;
create policy "alerts_select_authenticated"
on public.alerts
for select
to authenticated
using (true);

-- Users can create alerts only for themselves
drop policy if exists "alerts_insert_own" on public.alerts;
create policy "alerts_insert_own"
on public.alerts
for insert
to authenticated
with check (auth.uid() = user_id);

-- Users can edit only their own alerts
drop policy if exists "alerts_update_own" on public.alerts;
create policy "alerts_update_own"
on public.alerts
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Users can delete only their own alerts
drop policy if exists "alerts_delete_own" on public.alerts;
create policy "alerts_delete_own"
on public.alerts
for delete
to authenticated
using (auth.uid() = user_id);

-- Realtime updates for alerts stream
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'alerts'
  ) then
    alter publication supabase_realtime add table public.alerts;
  end if;
end $$;

-- Alert logs table for activity tracking
create table if not exists public.alert_logs (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.alerts(id) on delete cascade,
  changed_by uuid not null references auth.users(id) on delete cascade,
  old_value text,
  new_value text,
  changed_at timestamptz not null default now()
);

create index if not exists alert_logs_alert_id_idx on public.alert_logs (alert_id);
create index if not exists alert_logs_changed_at_idx on public.alert_logs (changed_at desc);

alter table public.alert_logs enable row level security;

-- Authenticated users can read all alert logs
drop policy if exists "alert_logs_select_authenticated" on public.alert_logs;
create policy "alert_logs_select_authenticated"
on public.alert_logs
for select
to authenticated
using (true);

-- Users can create logs only for their own alerts
drop policy if exists "alert_logs_insert_own" on public.alert_logs;
create policy "alert_logs_insert_own"
on public.alert_logs
for insert
to authenticated
with check (auth.uid() = changed_by);

-- Storage bucket for alert images
insert into storage.buckets (id, name, public)
values ('alert-images', 'alert-images', true)
on conflict (id) do nothing;

-- Anyone authenticated can read images
drop policy if exists "alert_images_select_authenticated" on storage.objects;
create policy "alert_images_select_authenticated"
on storage.objects
for select
to authenticated
using (bucket_id = 'alert-images');

-- Users can upload files to their own folder path: alerts/<user_id>/...
drop policy if exists "alert_images_insert_own_folder" on storage.objects;
create policy "alert_images_insert_own_folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'alert-images'
  and (storage.foldername(name))[1] = 'alerts'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Users can update only their own uploaded objects
drop policy if exists "alert_images_update_owner" on storage.objects;
create policy "alert_images_update_owner"
on storage.objects
for update
to authenticated
using (bucket_id = 'alert-images' and owner = auth.uid())
with check (bucket_id = 'alert-images' and owner = auth.uid());

-- Trigger to update updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_alerts_updated_at
before update on public.alerts
for each row execute function update_updated_at_column();
