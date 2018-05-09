"use strict";
/* USAGE:

  self.cacheKey = "v1";
  self.toCache = "...";
  importScripts("https://resources.whatwg.org/website-service-worker.js");

*/

const cacheKey = "v1";
const toCache = [
  "/",
  "https://whatwg.org/style/shared.css",
  "https://whatwg.org/style/subpages.css",
  "https://resources.whatwg.org/logo.svg"
];

self.oninstall = e => {
  e.waitUntil(caches.open(self.cacheKey).then(cache => cache.addAll(self.toCache)));
};

self.onactivate = e => {
  e.waitUntil(caches.keys().then(keys => {
    return Promise.all(keys.filter(key => key !== self.cacheKey).map(key => caches.delete(key)));
  }));
};

self.onfetch = e => {
  if (e.request.method !== "GET") {
    return;
  }

  // Cache-then-network strategy
  e.respondWith(
    caches.match(e.request).then(cachedResponse => {
      const networkFetchPromise = fetch(e.request);

      // Ignore network fetch or caching errors; they just mean we won't be able to refresh the cache.
      e.waitUntil(
        networkFetchPromise
          .then(res => refreshCacheFromNetworkResponse(e.request, res))
          .catch(() => {})
      );

      return cachedResponse || networkFetchPromise;
    })
  );
};

function refreshCacheFromNetworkResponse(req, res) {
  if (!res.ok) {
    throw new Error(`${res.url} is responding with ${res.status}`);
  }

  const resForCache = res.clone();

  return caches.open(self.cacheKey).then(cache => cache.put(req, resForCache));
}
