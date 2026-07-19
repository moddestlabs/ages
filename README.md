# LightSword Ages

Bible-focused charting for people, events, genealogies, timelines, ages, and
prophecy.

This repository is the starting point for **LightSword Ages**, a companion app
for the LightSword ecosystem. The product direction lives in [AGES.md](AGES.md).

## Current milestone

Phase 0 is focused on contracts and seed data before UI polish:

- stable IDs for people, relationships, events, ages, prophecies, and sources
- a bundled starter pack that can be loaded offline
- explicit confidence and source metadata for claims
- LightSword passage links using the production `https://lightsword.app/?r=...`
	format
- validation that catches broken cross-references early

## Repository layout

```text
docs/
	ROUTES.md
	SEED_DATA.md
data/
	biblical_ages_core/
		pack.json
schemas/
	biblical-ages-pack.schema.json
scripts/
	serve.mjs
	validate-pack.mjs
prototype/
	index.html
	styles.css
	app.js
```

## Validate the starter pack

```bash
npm test
```

The validator uses only Node's standard library so the data contract can be
checked before the Flutter/Dart app scaffold exists.

## Flutter setup

Install the repo-local Flutter SDK:

```bash
scripts/bootstrap-flutter.sh
export PATH="$PWD/.tool/flutter/bin:$PATH"
```

Run the Flutter app checks:

```bash
cd ages_app
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /
```

The generated web build is written to `ages_app/build/web/`.

## GitHub Pages deployment

Commits pushed to `main` run `.github/workflows/deploy-web.yml`. The workflow
validates the seed pack, analyzes and tests the Flutter app, builds Flutter web,
and publishes `ages_app/build/web/` to GitHub Pages.

## Run the explorer prototype

Flutter is the intended implementation target, but this repo includes a tiny
dependency-free browser prototype so the seed pack can be explored immediately:

```bash
npm run dev
```

Then open `http://localhost:4173/prototype/`.
