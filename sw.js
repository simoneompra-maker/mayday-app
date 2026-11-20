const CACHE = 'mayday-v13';
const ASSETS = ['./'];

// Stesso archivio del telefono usato dall'app (index.html): versione e archivi devono coincidere
const IDB_VER = 3;
function idb() {
  return new Promise((res, rej) => {
    const r = indexedDB.open('mayday', IDB_VER);
    r.onupgradeneeded = () => {
      for (const s of ['rec', 'foto', 'tx'])
        if (!r.result.objectStoreNames.contains(s)) r.result.createObjectStore(s, { keyPath: 'id' });
    };
    r.onsuccess = () => res(r.result);
    r.onerror   = () => rej(r.error);
  });
}

// File audio condivisi con MAYDAY (es. dal Registratore vocale Samsung → Condividi):
// si salvano sul telefono tra le registrazioni da elaborare e si apre l'app, che li riassume da sola
async function riceviCondivisi(req) {
  const back = q => new URL('./?go=riunione' + q, self.registration.scope).href;
  try {
    const fd = await req.formData();
    const files = fd.getAll('audio').filter(f => f && typeof f !== 'string' && f.size);
    if (!files.length) return Response.redirect(back('&vuoto=1'), 303);
    const db = await idb();
    await new Promise((res, rej) => {
      const tx = db.transaction('rec', 'readwrite');
      const st = tx.objectStore('rec');
      const ora = Date.now();
      files.forEach((f, i) => st.put({
        id: self.crypto.randomUUID(),
        blob: f, mime: f.type || '', nome: f.name || '',
        creato: new Date(f.lastModified || ora).toISOString(),
        riunione: { modello: 'auto' },
        condiviso: true, ricevuto: ora + i,
      }));
      tx.oncomplete = res;
      tx.onerror = () => rej(tx.error);
    });
    db.close();
    return Response.redirect(back(''), 303);
  } catch {
    return Response.redirect(back('&errore=1'), 303);
  }
}

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  // Never intercept API calls — only cache the app shell
  // (la libreria supabase-js dal CDN invece resta in cache, così l'app si apre anche offline)
  const url = new URL(e.request.url);
  if (e.request.method === 'POST' && url.pathname.endsWith('/share-target')) {
    e.respondWith(riceviCondivisi(e.request));
    return;
  }
  if (
    e.request.method !== 'GET' ||
    url.hostname.endsWith('supabase.co') ||
    url.hostname.includes('groq.com') ||
    url.hostname.includes('googleapis.com') ||
    url.hostname.includes('google.com') ||
    url.hostname.includes('accounts.google.com')
  ) {
    return;
  }

  // Page: network first, so updates arrive immediately; cache only when offline.
  // cache:'no-cache' chiede sempre a GitHub se la pagina è cambiata, invece di
  // riusare per 10 minuti la copia del browser (GitHub Pages manda max-age=600)
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request.url, { cache: 'no-cache' }).then(resp => {
        if (resp.ok) {
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return resp;
      }).catch(() => caches.match(e.request).then(c => c || caches.match('./')))
    );
    return;
  }

  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(resp => {
        if (resp.ok && e.request.method === 'GET') {
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return resp;
      }).catch(() => cached);
    })
  );
});
