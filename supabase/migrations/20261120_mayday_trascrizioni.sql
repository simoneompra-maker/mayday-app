-- MAYDAY v2.6 — trascrizioni complete delle registrazioni lunghe (sopralluoghi, colloqui, riunioni).
-- Solo una tabella nuova con prefisso mayday_; nessuna tabella esistente viene toccata.
-- cliente_id e nota_id sono collegamenti facoltativi, volutamente senza foreign key (come negli altri mayday_).
-- Il testo si scarica solo quando serve: l'app legge di solito solo i campi leggeri.

create table public.mayday_trascrizioni (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  titolo      text not null default '',
  modello     text not null default 'auto' check (modello in ('auto','sopralluogo','colloquio','riunione')),
  durata_sec  integer,
  cliente_id  uuid,
  nota_id     uuid,
  testo       text not null default '',
  creato      timestamptz not null default now(),
  aggiornato  timestamptz not null default now()
);

create index mayday_trascrizioni_user_creato_idx on public.mayday_trascrizioni (user_id, creato desc);
create index mayday_trascrizioni_cliente_idx     on public.mayday_trascrizioni (cliente_id) where cliente_id is not null;
create index mayday_trascrizioni_nota_idx        on public.mayday_trascrizioni (nota_id)    where nota_id    is not null;

alter table public.mayday_trascrizioni enable row level security;
revoke all on public.mayday_trascrizioni from anon;
create policy mayday_trascrizioni_select on public.mayday_trascrizioni for select to authenticated using ((select auth.uid()) = user_id);
create policy mayday_trascrizioni_insert on public.mayday_trascrizioni for insert to authenticated with check ((select auth.uid()) = user_id);
create policy mayday_trascrizioni_update on public.mayday_trascrizioni for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy mayday_trascrizioni_delete on public.mayday_trascrizioni for delete to authenticated using ((select auth.uid()) = user_id);
