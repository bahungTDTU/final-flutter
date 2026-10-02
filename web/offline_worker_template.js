// Build script replaces these literals from the actual release directory.
const CACHE_NAME = '__CACHE_NAME__';
const RESOURCES = __RESOURCES__;
const allowed = new Set(RESOURCES);
self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(RESOURCES);
    await self.skipWaiting();
  })());
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const name of await caches.keys()) {
      if ((name.startsWith('notetogether-static-') && name !== CACHE_NAME) ||
          ['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest'].includes(name)) {
        await caches.delete(name);
      }
    }
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  const base = new URL(self.registration.scope);
  if (request.method !== 'GET' || url.origin !== base.origin) return;
  const relative = url.pathname.substring(base.pathname.length);
  if (request.mode === 'navigate') {
    event.respondWith(fetch(request).catch(async () =>
      (await caches.open(CACHE_NAME)).match('index.html')));
  } else if (allowed.has(relative)) {
    // Static allowlist only: no API, session, note or user-file responses.
    event.respondWith((async () => {
      const cached = await (await caches.open(CACHE_NAME)).match(relative);
      return cached || fetch(request);
    })());
  }
});
