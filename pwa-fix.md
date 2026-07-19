# Ages iOS PWA Blank Page Fix Handoff

This handoff is for fixing the iOS installed-PWA blank white page in `moddestlabs/ages` by carrying over the relevant LightSword PWA fixes.

## Symptom

`https://ages.lightsword.app` works in the browser, but after using iOS Safari `Add to Home Screen`, launching the installed PWA opens to a blank white page.

This matches the earlier LightSword failure before the PWA refactor/fixes.

## High-Confidence Root Cause

Ages is missing the LightSword bootstrap fix from commit `ef14a72 PWA bug fixed again`.

LightSword explicitly configures Flutter to load CanvasKit from the local deployed `canvaskit/` directory:

```js
config: {
  canvasKitBaseUrl: 'canvaskit/'
}
```

Ages currently deploys a `flutter_bootstrap.js` that registers `ages_service_worker.js`, but does not provide this `config`. In production, this allows Flutter to choose the hosted `gstatic` CanvasKit path. That can break installed/offline-style iOS PWA startup and present as a blank shell.

## Primary Patch

Patch this file in Ages:

```text
ages_app/web/flutter_bootstrap.js
```

Current shape:

```js
{{flutter_js}}
{{flutter_build_config}}

const serviceWorkerVersion = {{flutter_service_worker_version}};

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion,
    serviceWorkerUrl: `ages_service_worker.js?v=${serviceWorkerVersion}`,
  },
});
```

Change it to:

```js
{{flutter_js}}
{{flutter_build_config}}

const serviceWorkerVersion = {{flutter_service_worker_version}};

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion,
    serviceWorkerUrl: `ages_service_worker.js?v=${serviceWorkerVersion}`,
  },
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
```

## Secondary Patch: iOS Meta Tag

Patch this file in Ages:

```text
ages_app/web/index.html
```

Ages currently has:

```html
<!-- iOS meta tags & icons -->
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black">
<meta name="apple-mobile-web-app-title" content="Ages">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

Add the missing iOS standalone flag:

```html
<!-- iOS meta tags & icons -->
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black">
<meta name="apple-mobile-web-app-title" content="Ages">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

## Secondary Patch: Redirect-Aware Service Worker Fallback

LightSword later added protection for custom-domain/GitHub Pages redirects. Ages is deployed at `ages.lightsword.app`, so it should carry over this behavior too.

Patch this file in Ages:

```text
ages_app/web/ages_service_worker.js
```

### Navigation Requests

Current Ages logic:

```js
async function handleNavigationRequest(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse && networkResponse.ok) {
      const runtimeCache = await caches.open(RUNTIME_CACHE);
      await runtimeCache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    // fallback logic...
  }
}
```

Change the beginning to prefer cached app-shell fallback when the network response is an off-origin redirect:

```js
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
    // fallback logic...
  }
}
```

### Static Requests

Current Ages logic:

```js
try {
  const networkResponse = await fetch(request);
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
```

Change it to:

```js
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
```

### Helper Functions

Add these helper functions near the other service-worker helper functions, before `matchCachedRequest` or after `navigationFallbackUrls`:

```js
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
```

## Build And Deploy Check

In the Ages repo, run:

```bash
cd ages_app
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /
cd ..
bash scripts/finalize-flutter-web.sh
```

Then inspect the generated file:

```bash
grep -n "canvasKitBaseUrl" ages_app/build/web/flutter_bootstrap.js
grep -n "shouldPreferCachedResponse" ages_app/build/web/ages_service_worker.js
```

Both should return matches.

## Production Verification

After deployment, verify production has the fixes:

```bash
curl -L -s https://ages.lightsword.app/flutter_bootstrap.js | grep -n "canvasKitBaseUrl"
curl -L -s https://ages.lightsword.app/ages_service_worker.js | grep -n "shouldPreferCachedResponse"
```

Also verify the key precache assets still exist:

```bash
for path in \
  .last_build_id \
  version.json \
  assets/shaders/ink_sparkle.frag \
  assets/shaders/stretch_effect.frag \
  canvaskit/canvaskit.js \
  canvaskit/skwasm.js \
  canvaskit/skwasm_heavy.js \
  canvaskit/wimp.js \
  data/biblical_ages_core/pack.json
do
  code=$(curl -L -s -o /dev/null -w '%{http_code}' "https://ages.lightsword.app/$path")
  printf '%s %s\n' "$code" "$path"
done
```

Expected result: every listed URL returns `200`.

## iOS Test Procedure

1. On iOS Safari, delete the existing Ages home-screen icon.
2. Open Safari settings for the site if needed and clear stale website data for `ages.lightsword.app`.
3. Open `https://ages.lightsword.app` in Safari.
4. Wait until the app fully loads.
5. Use Share > Add to Home Screen.
6. Launch the installed icon.
7. Confirm it opens past the white page into the Flutter app.

If it still opens white after these changes, the next debugging step is to temporarily add a LightSword-style startup shell/boot-state logger to `ages_app/web/index.html` and `ages_app/web/flutter_bootstrap.js` so iOS can persist the failing boot step in `localStorage`.