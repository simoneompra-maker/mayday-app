-- MAYDAY v2.0 — tabelle personali nel progetto ompra-magazzino.
-- Solo tabelle nuove con prefisso mayday_: nessuna tabella esistente viene toccata.
-- cliente_id è il futuro collegamento a public.clienti(id), volutamente senza foreign key.

create table public.mayday_appuntamenti (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  legacy_id   text,
  cliente     text not null default '',
  cliente_id  uuid,
  data        date,
  ora         time,
  luogo       text not null default '',
  descrizione text not null default '',
  calendario  jsonb,
  creato      timestamptz not null default now(),
  aggiornato  timestamptz not null default now(),
  unique (user_id, legacy_id)
);

create table public.mayday_task (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  legacy_id   text,
  cliente     text not null default '',
  cliente_id  uuid,
  descrizione text not null default '',
  scadenza    date,
  priorita    text not null default 'media' check (priorita in ('alta','media','bassa')),
  completato  boolean not null default false,
  creato      timestamptz not null default now(),
  aggiornato  timestamptz not null default now(),
  unique (user_id, legacy_id)
);

create table public.mayday_note (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  legacy_id   text,
  cliente     text not null default '',
  cliente_id  uuid,
  descrizione text not null default '',
  creato      timestamptz not null default now(),
  aggiornato  timestamptz not null default now(),
  unique (user_id, legacy_id)
);

create index mayday_appuntamenti_user_data_idx on public.mayday_appuntamenti (user_id, data);
create index mayday_task_user_completato_idx   on public.mayday_task (user_id, completato);
create index mayday_note_user_creato_idx       on public.mayday_note (user_id, creato desc);
create index mayday_appuntamenti_cliente_idx   on public.mayday_appuntamenti (cliente_id) where cliente_id is not null;
create index mayday_task_cliente_idx           on public.mayday_task (cliente_id) where cliente_id is not null;
create index mayday_note_cliente_idx           on public.mayday_note (cliente_id) where cliente_id is not null;

-- RLS: ogni riga visibile e modificabile solo dal proprietario, nessun accesso anonimo
do $$
declare t text;
begin
  foreach t in array array['mayday_appuntamenti','mayday_task','mayday_note'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('create policy %I on public.%I for select to authenticated using ((select auth.uid()) = user_id)', t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check ((select auth.uid()) = user_id)', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using ((select auth.uid()) = user_id)', t || '_delete', t);
  end loop;
end $$;
