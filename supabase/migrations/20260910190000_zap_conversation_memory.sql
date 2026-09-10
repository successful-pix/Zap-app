create table if not exists public.zap_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  persona_id text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, persona_id)
);

create table if not exists public.zap_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.zap_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (length(trim(content)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists zap_conversations_user_id_idx
  on public.zap_conversations(user_id);

create index if not exists zap_messages_conversation_created_idx
  on public.zap_messages(conversation_id, created_at);

alter table public.zap_conversations enable row level security;
alter table public.zap_messages enable row level security;

drop policy if exists "zap conversations own rows" on public.zap_conversations;
create policy "zap conversations own rows"
  on public.zap_conversations
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "zap messages own conversations" on public.zap_messages;
create policy "zap messages own conversations"
  on public.zap_messages
  for all to authenticated
  using (
    exists (
      select 1 from public.zap_conversations c
      where c.id = zap_messages.conversation_id
        and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.zap_conversations c
      where c.id = zap_messages.conversation_id
        and c.user_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.zap_conversations to authenticated;
grant select, insert, update, delete on public.zap_messages to authenticated;
