-- MAYDAY v2.5 — foto allegate ad appuntamenti, task e note.
-- Il file sta nel bucket privato mayday-foto, in <user_id>/<nome>; nome = data italiana (es. 12-11-2026_09-40-15_ab12.jpg).
-- item_id è il collegamento all'elemento, volutamente senza foreign key (come cliente_id).

create table public.mayday_allegati (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  item_tipo   text not null check (item_tipo in ('appuntamento','task','nota')),
  item_id     uuid not null,
  nome        text not null,
  creato      timestamptz not null default now(),
  aggiornato  timestamptz not null default now()
);

create index mayday_allegati_item_idx on public.mayday_allegati (item_id);

alter table public.mayday_allegati enable row level security;
revoke all on public.mayday_allegati from anon;
create policy mayday_allegati_select on public.mayday_allegati for select to authenticated using ((select auth.uid()) = user_id);
create policy mayday_allegati_insert on public.mayday_allegati for insert to authenticated with check ((select auth.uid()) = user_id);
create policy mayday_allegati_update on public.mayday_allegati for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy mayday_allegati_delete on public.mayday_allegati for delete to authenticated using ((select auth.uid()) = user_id);

-- Bucket privato: solo JPEG (le foto vengono ridotte sul telefono), massimo 3 MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('mayday-foto', 'mayday-foto', false, 3145728, array['image/jpeg']);

-- Ognuno vede e gestisce solo la propria cartella <user_id>/
create policy mayday_foto_select on storage.objects for select to authenticated
  using (bucket_id = 'mayday-foto' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy mayday_foto_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'mayday-foto' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy mayday_foto_update on storage.objects for update to authenticated
  using (bucket_id = 'mayday-foto' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'mayday-foto' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy mayday_foto_delete on storage.objects for delete to authenticated
  using (bucket_id = 'mayday-foto' and (storage.foldername(name))[1] = (select auth.uid())::text);
