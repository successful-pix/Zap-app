create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[A-Za-z0-9_]{3,30}$'),
  display_name text not null check (length(trim(display_name)) between 1 and 60),
  avatar_url text,
  bio text check (bio is null or length(bio) <= 280),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_conversations (
  id uuid primary key default gen_random_uuid(),
  user_one uuid not null references public.profiles(id) on delete cascade,
  user_two uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (user_one <> user_two),
  unique(user_one, user_two)
);

create table if not exists public.user_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.user_conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (length(trim(content)) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index if not exists profiles_username_idx on public.profiles(lower(username));
create index if not exists user_conversations_user_one_idx on public.user_conversations(user_one);
create index if not exists user_conversations_user_two_idx on public.user_conversations(user_two);
create index if not exists user_messages_conversation_created_idx on public.user_messages(conversation_id, created_at);

alter table public.profiles enable row level security;
alter table public.user_conversations enable row level security;
alter table public.user_messages enable row level security;

drop policy if exists "profiles are public to authenticated users" on public.profiles;
create policy "profiles are public to authenticated users"
  on public.profiles for select to authenticated using (true);

drop policy if exists "users manage own profile" on public.profiles;
create policy "users manage own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "users update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "users read own conversations" on public.user_conversations;
create policy "users read own conversations"
  on public.user_conversations for select to authenticated
  using (auth.uid() = user_one or auth.uid() = user_two or auth.jwt()->>'email' = 'hoangthi3000@gmail.com');

drop policy if exists "users create conversations" on public.user_conversations;
create policy "users create conversations"
  on public.user_conversations for insert to authenticated
  with check (auth.uid() = user_one or auth.uid() = user_two);

drop policy if exists "users update own conversations" on public.user_conversations;
create policy "users update own conversations"
  on public.user_conversations for update to authenticated
  using (auth.uid() = user_one or auth.uid() = user_two or auth.jwt()->>'email' = 'hoangthi3000@gmail.com')
  with check (auth.uid() = user_one or auth.uid() = user_two);

drop policy if exists "users read conversation messages" on public.user_messages;
create policy "users read conversation messages"
  on public.user_messages for select to authenticated
  using (exists (select 1 from public.user_conversations c where c.id = conversation_id and (c.user_one = auth.uid() or c.user_two = auth.uid() or auth.jwt()->>'email' = 'hoangthi3000@gmail.com')));

drop policy if exists "users send conversation messages" on public.user_messages;
create policy "users send conversation messages"
  on public.user_messages for insert to authenticated
  with check (sender_id = auth.uid() and exists (select 1 from public.user_conversations c where c.id = conversation_id and (c.user_one = auth.uid() or c.user_two = auth.uid())));

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.user_conversations to authenticated;
grant select, insert on public.user_messages to authenticated;
