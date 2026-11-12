-- Jalankan seluruh SQL ini di Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 role text not null default 'customer' check (role in ('customer','admin')),
 created_at timestamptz not null default now()
);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(),
 invoice_number text unique not null default ('INV-'||to_char(now(),'YYYY')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))),
 user_id uuid not null references auth.users(id) on delete restrict,
 customer_name text not null,
 email text not null,
 phone text not null,
 institution text,
 service text not null,
 research_type text,
 details text not null,
 deadline date,
 file_path text,
 file_name text,
 price bigint not null default 0 check(price>=0),
 status text not null default 'Menunggu pembayaran' check(status in ('Menunggu pembayaran','Pembayaran diverifikasi','Sedang diproses','Menunggu revisi','Selesai','Dibatalkan')),
 paid boolean not null default false,
 created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.orders enable row level security;

-- SECURITY DEFINER helper avoids recursive profile-policy evaluation.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin'); $$;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "profile read self or admin" on public.profiles;
create policy "profile read self or admin" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
drop policy if exists "customer insert own order" on public.orders;
create policy "customer insert own order" on public.orders for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "read own orders or admin" on public.orders;
create policy "read own orders or admin" on public.orders for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders for update to authenticated using(public.is_admin()) with check(public.is_admin());
-- Private bucket: files are not publicly accessible.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('order-files','order-files',false,10485760,array['application/pdf','application/zip','text/csv','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict(id) do update set public=false,file_size_limit=10485760;
drop policy if exists "upload own order files" on storage.objects;
create policy "upload own order files" on storage.objects for insert to authenticated with check(bucket_id='order-files' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "read own files or admin" on storage.objects;
create policy "read own files or admin" on storage.objects for select to authenticated using(bucket_id='order-files' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));
-- ADMIN SETUP: after registering your account, replace YOUR_AUTH_USER_UUID below.
-- Run: update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';
