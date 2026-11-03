-- MAYDAY v2.1 — schede clienti personali.
-- Solo una tabella nuova con prefisso mayday_; l'anagrafica public.clienti del magazzino non viene toccata.
-- anagrafica_id è il collegamento facoltativo a public.clienti(id), volutamente senza foreign key.

create table public.mayday_clienti (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome          text not null default '',
  localita      text not null default '',
  azienda       text not null default '',
  telefono      text not null default '',
  email         text not null default '',
  anagrafica_id uuid,
  creato        timestamptz not null default now(),
  aggiornato    timestamptz not null default now()
);
create index mayday_clienti_user_nome_idx  on public.mayday_clienti (user_id, nome);
create index mayday_clienti_anagrafica_idx on public.mayday_clienti (anagrafica_id) where anagrafica_id is not null;

alter table public.mayday_clienti enable row level security;
revoke all on public.mayday_clienti from anon;
create policy mayday_clienti_select on public.mayday_clienti for select to authenticated using ((select auth.uid()) = user_id);
create policy mayday_clienti_insert on public.mayday_clienti for insert to authenticated with check ((select auth.uid()) = user_id);
create policy mayday_clienti_update on public.mayday_clienti for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy mayday_clienti_delete on public.mayday_clienti for delete to authenticated using ((select auth.uid()) = user_id);

comment on column public.mayday_appuntamenti.cliente_id is 'Scheda in mayday_clienti.id';
comment on column public.mayday_task.cliente_id         is 'Scheda in mayday_clienti.id';
comment on column public.mayday_note.cliente_id         is 'Scheda in mayday_clienti.id';
