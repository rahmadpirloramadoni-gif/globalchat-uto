-- Jalankan sekali di Supabase: SQL Editor > New query > paste > Run

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 2 and 24),
  avatar_url text,
  created_at timestamptz default now()
);

create table public.messages (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null default 'text' check (kind in ('text','image','video','voice')),
  content text check (char_length(content) <= 1000),
  media_url text,
  duration int,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.messages enable row level security;

create policy "profil dibaca user login" on public.profiles for select to authenticated using (true);
create policy "profil buat sendiri" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profil ubah sendiri" on public.profiles for update to authenticated using (auth.uid() = id);

create policy "pesan dibaca user login" on public.messages for select to authenticated using (true);
create policy "pesan kirim sendiri" on public.messages for insert to authenticated with check (auth.uid() = user_id);

-- Penyimpanan foto, video, suara, avatar (maks 20 MB per file)
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', true, 20971520) on conflict (id) do nothing;

create policy "media dibaca semua" on storage.objects for select using (bucket_id = 'media');
create policy "media upload ke folder sendiri" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);

-- Real-time
alter publication supabase_realtime add table public.messages, public.profiles;
