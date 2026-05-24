const CACHE = 'vores-have-v3';
const SHELL = ['/manifest.json', '/icons/icon-192.png', '/icons/icon-512.png'];
const HTML = ['/', '/index.html'];

self.addEventListener('install', e => {
    e.waitUntil(caches.open(CACHE).then(c => c.addAll([...SHELL, ...HTML])));
    // Ingen skipWaiting — ny SW venter til næste gang appen åbnes,
    // så igangværende uploads ikke afbrydes midt i
});

self.addEventListener('activate', e => {
    e.waitUntil(caches.keys().then(keys =>
        Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ));
    self.clients.claim();
});

self.addEventListener('fetch', e => {
    if (e.request.method !== 'GET') return;
    const url = new URL(e.request.url);
    const isHTML = HTML.some(p => url.pathname === p || url.pathname === '');

    if (isHTML) {
        // Network first for HTML — sikrer altid nyeste version ved online
        e.respondWith(
            fetch(e.request).then(res => {
                const clone = res.clone();
                caches.open(CACHE).then(c => c.put(e.request, clone));
                return res;
            }).catch(() => caches.match(e.request))
        );
    } else {
        // Cache first for statiske filer (ikoner, manifest)
        e.respondWith(
            caches.match(e.request).then(cached => cached || fetch(e.request).then(res => {
                const clone = res.clone();
                caches.open(CACHE).then(c => c.put(e.request, clone));
                return res;
            }))
        );
    }
});
