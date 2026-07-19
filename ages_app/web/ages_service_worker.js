'use strict';

const CACHE_VERSION = '__AGES_CACHE_VERSION__';
const APP_SHELL_CACHE = 'ages-app-shell-' + CACHE_VERSION;
const DATA_CACHE = 'ages-data-' + CACHE_VERSION;
const RUNTIME_CACHE = 'ages-runtime-' + CACHE_VERSION;

const APP_SHELL_URLS = [
  './',
  '.last_build_id',
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'pwa.js',
  'version.json',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/NOTICES',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'assets/shaders/ink_sparkle.frag',
  'assets/shaders/stretch_effect.frag',
  'assets/assets/fonts/DejaVuSerif.ttf',
  'assets/assets/fonts/DejaVuSerif-Bold.ttf',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'favicon.png',
  'canvaskit/canvaskit.js',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/experimental_webparagraph/canvaskit.js',
  'canvaskit/skwasm.js',
  'canvaskit/skwasm_heavy.js',
  'canvaskit/wimp.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.wasm',
  'canvaskit/experimental_webparagraph/canvaskit.wasm',
  'canvaskit/skwasm.wasm',
  'canvaskit/skwasm_heavy.wasm',
  'canvaskit/wimp.wasm',
];

const DATA_URLS = [
  'data/biblical_ages_core/pack.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const shellCache = await caches.open(APP_SHELL_CACHE);
      await shellCache.addAll(APP_SHELL_URLS);

      const dataCache = await caches.open(DATA_CACHE);
      await dataCache.addAll(DATA_URLS);

      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const activeCaches = new Set([
        APP_SHELL_CACHE,
        DATA_CACHE,
        RUNTIME_CACHE,
      ]);
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter((cacheName) => cacheName.startsWith('ages-') && !activeCaches.has(cacheName))
          .map((cacheName) => caches.delete(cacheName)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(event.request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (event.request.mode === 'navigate') {
    event.respondWith(handleNavigationRequest(event.request));
    return;
  }

  event.respondWith(handleStaticRequest(event.request));
});

self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type !== 'GET_CACHE_STATUS') {
    return;
  }

  event.waitUntil(
    getCacheStatus().then((status) => {
      event.source?.postMessage({
        type: 'CACHE_STATUS_RESULT',
        status,
      });
    }),
  );
});

async function handleNavigationRequest(request) {
  try {
    const networkResponse = await fetch(request);
    if (shouldPreferCachedResponse(request, networkResponse)) {
      throw createRedirectMigrationError(request, networkResponse);
    }

    if (networkResponse && networkResponse.ok) {
      const runtimeCache = await caches.open(RUNTIME_CACHE);
      await runtimeCache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const runtimeCache = await caches.open(RUNTIME_CACHE);
    const cachedResponse = await runtimeCache.match(request, { ignoreSearch: true });
    if (cachedResponse) {
      return cachedResponse;
    }

    const shellCache = await caches.open(APP_SHELL_CACHE);
    for (const fallbackUrl of navigationFallbackUrls()) {
      const fallbackResponse = await shellCache.match(fallbackUrl);
      if (fallbackResponse) {
        return fallbackResponse;
      }
    }

    throw error;
  }
}

async function handleStaticRequest(request) {
  const cachedResponse = await matchCachedRequest(request);
  if (cachedResponse) {
    return cachedResponse;
  }

  const runtimeCache = await caches.open(RUNTIME_CACHE);
  try {
    const networkResponse = await fetch(request);
    if (shouldPreferCachedResponse(request, networkResponse)) {
      throw createRedirectMigrationError(request, networkResponse);
    }

    if (networkResponse && networkResponse.ok) {
      await runtimeCache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const runtimeResponse = await runtimeCache.match(request, { ignoreSearch: true });
    if (runtimeResponse) {
      return runtimeResponse;
    }
    throw error;
  }
}

async function matchCachedRequest(request) {
  const shellCache = await caches.open(APP_SHELL_CACHE);
  const shellResponse = await shellCache.match(request, { ignoreSearch: true });
  if (shellResponse) {
    return shellResponse;
  }

  const dataCache = await caches.open(DATA_CACHE);
  return dataCache.match(request, { ignoreSearch: true });
}

function navigationFallbackUrls() {
  const scopeUrl = new URL('./', self.registration.scope);
  const indexUrl = new URL('index.html', scopeUrl);

  return [
    scopeUrl.href,
    indexUrl.href,
    scopeUrl.pathname,
    indexUrl.pathname,
    './',
    'index.html',
  ];
}

function shouldPreferCachedResponse(request, response) {
  if (!response) {
    return false;
  }

  if (response.type === 'opaqueredirect') {
    return true;
  }

  if (!response.redirected || !response.url) {
    return false;
  }

  try {
    const requestUrl = new URL(request.url);
    const responseUrl = new URL(response.url, self.location.origin);
    return requestUrl.origin !== responseUrl.origin;
  } catch (_) {
    return false;
  }
}

function createRedirectMigrationError(request, response) {
  const requestOrigin = safeOriginFromUrl(request.url);
  const responseOrigin = safeOriginFromUrl(response?.url);

  return new Error(
    'redirected_off_origin:' +
      (requestOrigin || 'unknown') +
      '->' +
      (responseOrigin || 'unknown')
  );
}

function safeOriginFromUrl(url) {
  if (!url) {
    return null;
  }

  try {
    return new URL(url, self.location.origin).origin;
  } catch (_) {
    return null;
  }
}

async function getCacheStatus() {
  return {
    shell: {
      cacheName: APP_SHELL_CACHE,
      total: APP_SHELL_URLS.length,
      cached: await countCachedEntries(APP_SHELL_CACHE, APP_SHELL_URLS),
    },
    data: {
      cacheName: DATA_CACHE,
      total: DATA_URLS.length,
      cached: await countCachedEntries(DATA_CACHE, DATA_URLS),
    },
  };
}

async function countCachedEntries(cacheName, urls) {
  const cache = await caches.open(cacheName);
  let cached = 0;
  for (const url of urls) {
    if (await cache.match(url, { ignoreSearch: true })) {
      cached += 1;
    }
  }
  return cached;
}
