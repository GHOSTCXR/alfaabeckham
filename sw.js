// This site is no longer a PWA. This file exists only to clean up
// the OLD service worker + caches on devices that installed it before,
// so they stop being served stale/cached data (like old stock counts).
// It installs itself, deletes every cache, unregisters, and forces any
// open tabs to reload with a fresh copy of the real page.

self.addEventListener('install', () => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        (async () => {
            const cacheNames = await caches.keys();
            await Promise.all(cacheNames.map((name) => caches.delete(name)));

            await self.registration.unregister();

            const clientsList = await self.clients.matchAll({ type: 'window' });
            clientsList.forEach((client) => client.navigate(client.url));
        })()
    );
});
