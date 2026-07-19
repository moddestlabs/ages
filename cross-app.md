# Cross-App Awareness

LightSword-family apps should treat cross-app awareness as a shared ecosystem
contract, not as one-off detection logic inside each app. Ages, LightSword, and
future companion apps should all keep canonical HTTPS links as the reliable
baseline, then layer install awareness on top where browsers support it.

## Goals

- Let Ages open LightSword passages with the best available installed-app
  experience.
- Let LightSword open Ages people, events, timelines, genealogies, and other
  companion views.
- Preserve normal web URLs as the fallback for every route.
- Keep route builders, app IDs, capabilities, and install hints consistent
  across the LightSword ecosystem.

## Browser Constraints

Web apps cannot reliably ask whether an arbitrary PWA is installed. Browsers
limit that information for privacy reasons. Installed PWA handoff is also
browser, operating system, and user-setting dependent.

That means Ages cannot force a link to open inside the installed LightSword PWA.
The most durable behavior is:

1. Build the canonical HTTPS route.
2. Open that route.
3. Let the browser decide whether the matching installed PWA should capture it.
4. Fall back to a normal browser tab when PWA capture is unavailable.

## Canonical Routes

Canonical HTTPS routes remain the source of truth:

```text
https://lightsword.app/?r=gen12.1-9
https://lightsword.app/?r=gen12.1&mode=interlinear
https://ages.lightsword.app/person/person.abraham
https://ages.lightsword.app/event/event.call-of-abram
```

Every app should be usable from these URLs even when nothing is installed.

## Manifest Identity

Each PWA should declare a stable manifest identity. This gives browsers and
future shared tooling a consistent way to recognize each app.

LightSword reader:

```json
{
  "id": "https://lightsword.app/",
  "name": "LightSword - Bible Study",
  "short_name": "LightSword",
  "start_url": "/",
  "scope": "/",
  "display": "standalone"
}
```

LightSword Ages:

```json
{
  "id": "https://ages.lightsword.app/",
  "name": "LightSword Ages",
  "short_name": "Ages",
  "start_url": "/",
  "scope": "/",
  "display": "standalone"
}
```

## Related Apps

Where supported, PWAs can use `related_applications` plus
`navigator.getInstalledRelatedApps()` as a progressive enhancement. This should
be treated as a hint, not a guarantee.

Example Ages manifest relationship to LightSword:

```json
{
  "related_applications": [
    {
      "platform": "webapp",
      "url": "https://lightsword.app/manifest.json",
      "id": "https://lightsword.app/"
    }
  ],
  "prefer_related_applications": false
}
```

Example detection helper:

```js
export async function getInstalledLightSwordApps() {
  if (!("getInstalledRelatedApps" in navigator)) {
    return [];
  }

  return navigator.getInstalledRelatedApps();
}
```

The launch code should still open the canonical HTTPS URL. Detection can adjust
labels, tooltips, or UX hints, but it should not be required for navigation.

## Shared App Registry

Host a small registry that every app can consume, for example:

```text
https://lightsword.app/.well-known/lightsword-apps.json
```

Suggested shape:

```json
{
  "version": 1,
  "apps": [
    {
      "id": "lightsword.reader",
      "name": "LightSword",
      "origin": "https://lightsword.app",
      "manifest": "https://lightsword.app/manifest.json",
      "scope": "https://lightsword.app/",
      "capabilities": ["passage.read", "interlinear.open"],
      "routes": {
        "passage": "https://lightsword.app/?r={reference}",
        "interlinear": "https://lightsword.app/?r={reference}&mode=interlinear"
      }
    },
    {
      "id": "lightsword.ages",
      "name": "LightSword Ages",
      "origin": "https://ages.lightsword.app",
      "manifest": "https://ages.lightsword.app/manifest.json",
      "scope": "https://ages.lightsword.app/",
      "capabilities": ["person.open", "event.open", "timeline.open"],
      "routes": {
        "person": "https://ages.lightsword.app/person/{personId}",
        "event": "https://ages.lightsword.app/event/{eventId}",
        "timeline": "https://ages.lightsword.app/timeline?person={personId}"
      }
    }
  ]
}
```

This registry does not prove install state. Its job is to keep app metadata,
route templates, and capability names synchronized.

## Launch Algorithm

All LightSword-family apps should use the same launch behavior:

```text
1. Resolve the target capability from the shared registry.
2. Build the canonical HTTPS URL from the route template.
3. Optionally check navigator.getInstalledRelatedApps().
4. Open the canonical HTTPS URL.
5. Let the browser route the URL into an installed PWA when supported.
6. Otherwise, continue in the normal browser tab or window.
```

Example:

```js
export async function openLightSwordPassage(reference) {
  const url = new URL("https://lightsword.app/");
  url.searchParams.set("r", reference);

  window.open(url.toString(), "_blank", "noopener,noreferrer");
}
```

## Optional Protocol Handlers

Future apps may add custom protocol handlers for richer app-like launches:

```json
{
  "protocol_handlers": [
    {
      "protocol": "web+lightsword",
      "url": "/?launch=%s"
    }
  ]
}
```

Protocol handlers should remain optional. They require browser support and user
permission, and they are less transparent than canonical HTTPS routes.

## Recommendation

Use canonical HTTPS routes as the required contract. Add stable manifest `id`
fields, declare related LightSword-family PWAs, and centralize app metadata in a
shared registry. Treat install detection as a progressive enhancement for UX,
not as a dependency for navigation.