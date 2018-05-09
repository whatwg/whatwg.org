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

// From https://github.com/jakearchibald/async-waituntil-polyfill
// Apache 2 License: https://github.com/jakearchibald/async-waituntil-polyfill/blob/master/LICENSE
{
  const waitUntil = ExtendableEvent.prototype.waitUntil;
  const respondWith = FetchEvent.prototype.respondWith;
  const promisesMap = new WeakMap();

  ExtendableEvent.prototype.waitUntil = function(promise) {
    const extendableEvent = this;
    let promises = promisesMap.get(extendableEvent);

    if (promises) {
      promises.push(Promise.resolve(promise));
      return;
    }

    promises = [Promise.resolve(promise)];
    promisesMap.set(extendableEvent, promises);

    // call original method
    return waitUntil.call(extendableEvent, Promise.resolve().then(function processPromises() {
      const len = promises.length;

      // wait for all to settle
      return Promise.all(promises.map(p => p.catch(()=>{}))).then(() => {
        // have new items been added? If so, wait again
        if (promises.length != len) return processPromises();
        // we're done!
        promisesMap.delete(extendableEvent);
        // reject if one of the promises rejected
        return Promise.all(promises);
      });
    }));
  };

  FetchEvent.prototype.respondWith = function(promise) {
    this.waitUntil(promise);
    return respondWith.call(this, promise);
  };
}
