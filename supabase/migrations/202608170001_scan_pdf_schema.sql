create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  subscription_status text not null default 'free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  default_scan_mode text not null default 'document',
  default_filter text not null default 'autoColor',
  auto_capture_enabled boolean not null default false,
  ocr_language_bundle text not null default 'latin',
  auto_ocr_enabled boolean not null default true,
  default_export_format text not null default 'pdf',
  default_file_name_format text not null default 'Scan yyyy-MM-dd HH.mm',
  app_icon text not null default 'default',
  sync_enabled boolean not null default false,
  auto_upload_enabled boolean not null default false,
  default_email_subject text not null default 'Scanned document: {title}',
  default_email_body text not null default 'Please find {title} attached.',
  default_email_signature text not null default '',
  email_attachment_format text not null default 'pdf',
  include_document_date boolean not null default true,
  diagnostic_logs_enabled boolean not null default false,
  create_searchable_pdf boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  app_store_transaction_id text,
  status text not null default 'free',
  plan_id text,
  source text,
  trial_start timestamptz,
  trial_end timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.usage_limits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  ocr_pages_used integer not null default 0 check (ocr_pages_used >= 0),
  export_conversions_used integer not null default 0 check (export_conversions_used >= 0),
  ai_messages_used integer not null default 0 check (ai_messages_used >= 0),
  folders_created integer not null default 0 check (folders_created >= 0),
  workflows_created integer not null default 0 check (workflows_created >= 0),
  signatures_created integer not null default 0 check (signatures_created >= 0),
  period_start timestamptz not null default date_trunc('month', now()),
  period_end timestamptz not null default date_trunc('month', now()) + interval '1 month',
  updated_at timestamptz not null default now()
);

create table if not exists public.folders (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  parent_folder_id uuid references public.folders(id) on delete set null,
  name text not null check (length(trim(name)) between 1 and 120),
  sort_index integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.documents (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  folder_id uuid references public.folders(id) on delete set null,
  title text not null check (length(trim(title)) between 1 and 240),
  thumbnail_url text,
  local_path text,
  pdf_url text,
  file_type text not null default 'scan',
  file_size bigint not null default 0 check (file_size >= 0),
  page_count integer not null default 0 check (page_count >= 0),
  full_ocr_text text not null default '',
  is_favorite boolean not null default false,
  is_locked boolean not null default false,
  is_synced boolean not null default false,
  cloud_provider text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.document_pages (
  id uuid primary key,
  document_id uuid not null references public.documents(id) on delete cascade,
  page_index integer not null check (page_index >= 0),
  original_image_url text,
  processed_image_url text,
  local_original_path text,
  local_processed_path text,
  crop_data jsonb not null default '{}'::jsonb,
  filter_type text not null default 'autoColor',
  rotation integer not null default 0,
  ocr_text text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(document_id, page_index)
);

create table if not exists public.ocr_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  document_id uuid references public.documents(id) on delete cascade,
  status text not null default 'queued',
  language_bundle text,
  pages_count integer not null default 0,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz
);

create table if not exists public.export_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  document_id uuid references public.documents(id) on delete cascade,
  export_type text not null,
  status text not null default 'queued',
  output_url text,
  error_message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.signatures (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  image_url text,
  local_path text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workflows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  template_key text not null,
  name text not null,
  steps jsonb not null default '[]'::jsonb,
  is_enabled boolean not null default true,
  is_plus_only boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, template_key)
);

create table if not exists public.cloud_services (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  provider text not null,
  status text not null default 'disconnected',
  auto_upload_enabled boolean not null default false,
  upload_folder_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, provider)
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject text not null,
  message text not null,
  priority text not null default 'standard',
  status text not null default 'open',
  attachment_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists folders_user_idx on public.folders(user_id, deleted_at);
create index if not exists documents_user_idx on public.documents(user_id, updated_at desc);
create index if not exists documents_folder_idx on public.documents(folder_id, deleted_at);
create index if not exists document_pages_document_idx on public.document_pages(document_id, page_index);
create index if not exists ocr_jobs_user_idx on public.ocr_jobs(user_id, status);
create index if not exists export_jobs_user_idx on public.export_jobs(user_id, status);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users(id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  ) on conflict (id) do update set
    email = excluded.email,
    display_name = coalesce(excluded.display_name, public.users.display_name),
    avatar_url = coalesce(excluded.avatar_url, public.users.avatar_url),
    updated_at = now();
  insert into public.user_settings(user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.usage_limits(user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.subscriptions(user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert or update on auth.users
for each row execute procedure public.handle_new_user();

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'users','user_settings','subscriptions','usage_limits','folders','documents',
    'document_pages','ocr_jobs','export_jobs','signatures','workflows',
    'cloud_services','support_tickets'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end $$;

create policy "users_select_own" on public.users for select using (id = auth.uid());
create policy "users_update_own" on public.users for update using (id = auth.uid()) with check (id = auth.uid());

create policy "settings_own" on public.user_settings for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "subscriptions_select_own" on public.subscriptions for select using (user_id = auth.uid());
create policy "usage_select_own" on public.usage_limits for select using (user_id = auth.uid());

create policy "folders_own" on public.folders for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "documents_own" on public.documents for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "pages_own" on public.document_pages for all
using (exists(select 1 from public.documents d where d.id = document_id and d.user_id = auth.uid()))
with check (exists(select 1 from public.documents d where d.id = document_id and d.user_id = auth.uid()));
create policy "ocr_jobs_own" on public.ocr_jobs for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "export_jobs_own" on public.export_jobs for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "signatures_own" on public.signatures for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "workflows_own" on public.workflows for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cloud_services_own" on public.cloud_services for all
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "support_select_own" on public.support_tickets for select using (user_id = auth.uid());
create policy "support_insert_own" on public.support_tickets for insert with check (user_id = auth.uid());
do $$
declare table_name text;
begin
  foreach table_name in array array[
    'users','user_settings','subscriptions','usage_limits','folders','documents',
    'document_pages','signatures','workflows','cloud_services','support_tickets'
  ] loop
    execute format('drop trigger if exists set_%I_updated_at on public.%I', table_name, table_name);
    execute format(
      'create trigger set_%I_updated_at before update on public.%I for each row execute procedure public.set_updated_at()',
      table_name,
      table_name
    );
  end loop;
end $$;

insert into storage.buckets(id, name, public) values
  ('scanned-documents', 'scanned-documents', false),
  ('original-pages', 'original-pages', false),
  ('processed-pages', 'processed-pages', false),
  ('thumbnails', 'thumbnails', false),
  ('exports', 'exports', false),
  ('signatures', 'signatures', false),
  ('support-attachments', 'support-attachments', false)
on conflict (id) do update set public = false;

create policy "storage_select_own" on storage.objects for select to authenticated
using ((storage.foldername(name))[1] = auth.uid()::text);
create policy "storage_insert_own" on storage.objects for insert to authenticated
with check ((storage.foldername(name))[1] = auth.uid()::text);
create policy "storage_update_own" on storage.objects for update to authenticated
using ((storage.foldername(name))[1] = auth.uid()::text)
with check ((storage.foldername(name))[1] = auth.uid()::text);
create policy "storage_delete_own" on storage.objects for delete to authenticated
using ((storage.foldername(name))[1] = auth.uid()::text);
