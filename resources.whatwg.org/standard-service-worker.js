"use strict";
/* USAGE:

  self.extraResources = ["https://example.com/..."]; // optional
  importScripts("https://resources.whatwg.org/standard-service-worker.js");

*/

const standardShortname = location.host.split(".")[0];

const cacheKey = "v11";
const toCache = [
  location.origin + "/",
  "https://resources.whatwg.org/spec.css",
  "https://resources.whatwg.org/standard.css",
  "https://resources.whatwg.org/standard-shared-with-dev.css",
  "https://resources.whatwg.org/file-issue.js",
  "https://resources.whatwg.org/commit-snapshot-shortcut-key.js",
  standardShortname === "html" ? "https://resources.whatwg.org/logo.svg"
                               : "https://resources.whatwg.org/logo-" + standardShortname + ".svg"
].concat(self.extraResources || []);

self.oninstall = e => {
  const requests = toCache.map(url => new Request(url, { mode: "cors" }));
  e.waitUntil(caches.open(cacheKey).then(cache => cache.addAll(requests)));
};

self.onfetch = e => {
  if (e.request.method !== "GET") {
    return;
  }

  if (needsToBeFresh(e.request)) {
    // Since this is a Living Standard, it is imperative that you see the freshest content, so we use a
    // network-then-cache strategy for the main content.
    e.respondWith(
      fetch(e.request).then(res => {
        e.waitUntil(refreshCacheFromNetworkResponse(e.request, res));
        return res;
      })
      .catch(() => {
        return caches.match(e.request, { cacheName: cacheKey });
      })
    );
  } else {
    // For auxiliary resources, we can use a cache-then-network strategy; it is OK to not get the freshest.
    e.respondWith(
      caches.match(e.request, { cacheName: cacheKey }).then(cachedResponse => {
        const networkFetchPromise = fetch(e.request);

        // Only warn on network fetch or caching errors; they just mean we won't be able to refresh
        // the cache. (But, don't ignore them, because that could hide coding errors.)
        e.waitUntil(
          networkFetchPromise
            .then(res => refreshCacheFromNetworkResponse(e.request, res))
            .catch(err => {
              console.warn(`Could not refresh the cache for ${e.request.url}`, err);
            })
        );

        return cachedResponse || networkFetchPromise;
      })
    );
  }
};

self.onactivate = e => {
  e.waitUntil(caches.keys().then(keys => {
    return Promise.all(keys.filter(key => key !== cacheKey).map(key => caches.delete(key)));
  }));
};

function refreshCacheFromNetworkResponse(req, res) {
  if (res.type !== "opaque" && !res.ok) {
    return Promise.reject(new Error(`${res.url} is responding with ${res.status}`));
  }

  const resForCache = res.clone();

  return caches.open(cacheKey).then(cache => cache.put(req, resForCache));
}

function needsToBeFresh(req) {
  return req.mode === "navigate";
}
