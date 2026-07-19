# LightSword Ages Development Plan

**Status:** Draft development reference  
**Audience:** Contributors planning or implementing the biblical ages companion app  
**Canonical app URL:** `https://ages.lightsword.app`  
**Implementation target:** Independent Flutter web PWA first, with desktop and
mobile Flutter targets kept open

## 1. Product thesis

LightSword Ages is a companion app for exploring biblical ages, people,
genealogies, events, timelines, and prophecies across the full Scriptural arc.
It should answer questions that are awkward inside a chapter reader: who is this
person, how are they related to others, where do they appear in the story, what
happens before or after them, and how do past events and future promises fit
together?

Genealogy, timeline, events, and prophecy should ship as one product surface. A
family tree without time becomes a static chart, a timeline without people
becomes a list of events, and prophecy without an age/era model becomes hard to
locate in the wider biblical storyline. Biblical genealogies are often doing
more than ancestry: they locate covenant history across generations and ages.
Combining these categories avoids separate companion apps fighting over the same
people, events, dates, prophecies, and route contracts.

The useful distinction is:

- **LightSword** is the reading and study surface.
- **LightSword Ages** is the age, person, lineage, event, and prophecy surface.
- **Future atlas and writing apps** can consume the same person, event, date,
  prophecy, age, and passage links for maps, sermons, lessons, and visuals.

## 2. Viability summary

This is viable, and it is probably more viable as one Ages companion than as
separate genealogy, timeline, event, people, and prophecy apps. The existing
LightSword direction already supports independent companion apps, deep links,
and shared data packs. An ages app can start with a curated dataset and remain
useful before broader atlas, sync, or cloud features exist.

The main risk is data quality, not UI. Biblical people are frequently ambiguous:
many names repeat, some genealogies compress generations, dates are approximate,
different traditions disagree on chronology, and future events may be promised
without a simple timestamp. The app should model uncertainty explicitly instead
of pretending every person has a precise date, every prophecy has a settled
sequence, or every genealogy is a complete tree.

Recommendation: build an MVP around curated canonical anchors, not automatic
extraction. Start with clearly bounded genealogical passages and major events,
then expand through versioned data packs.

## 3. Why this should be a companion app

Age, genealogy, timeline, event, and prophecy views need dense graph rendering,
filtering, search, event cards, date scales, era bands, maybe maps later, and a
larger read-only dataset than the main reader should carry by default. Keeping
this outside the main LightSword app protects the fast reading experience while
still enabling rich study workflows through links.

The app is mostly read-only at first, so it is less dependent on account sync
than a writing or notes app. That makes it a strong early companion candidate:
it can prove shared route contracts, pack manifests, offline data loading, and
cross-app workflows without requiring collaboration or cloud storage.

## 4. Target users and jobs

Primary users:

- Readers trying to understand family relationships in Genesis, Chronicles,
  Ruth, the Gospels, and kingship narratives.
- Teachers preparing lessons that need visual lineage or historical sequence.
- Students comparing genealogies, dynasties, covenants, and major biblical eras.
- Writers and sermon planners who need insertable charts or event sequences.
- Readers tracing prophetic promises, fulfillments, and future events across
  Scripture.

Core jobs:

- Open a person from a Bible passage and see identity, relationships, events,
  and key references.
- Trace a lineage between two people where the data supports it.
- Compare Matthew 1 and Luke 3 without flattening their theological and textual
  differences.
- Move between a family tree and timeline without losing context.
- Locate prophecy and fulfillment records within broader ages and timelines.
- Filter by covenant line, tribe, dynasty, book, age, era, role, prophecy type,
  fulfillment status, or confidence level.
- Copy or export a small chart, timeline slice, age overview, prophecy trail, or
  person summary for teaching.

## 5. Recommended product shape

Use one app with coordinated views:

1. **Ages view**
  Shows major biblical ages, eras, covenants, kingdoms, and future horizons as
  navigable bands that can contain people, events, genealogies, and prophecies.

2. **Person view**
   Shows the selected person, aliases, key references, relationships, life
   events, and confidence notes.

3. **Genealogy view**
   Shows parent/child, spouse, sibling, descendant, and dynasty relationships.
   It should support both strict family tree mode and broader relationship graph
   mode.

4. **Timeline and events view**
   Shows events and life spans as ranges with uncertainty. Selecting a person in
   the tree highlights that person's events in time; selecting an event in time
   highlights related people in the tree.

5. **Prophecy view**
  Shows prophetic passages, promised or future events, fulfillment claims where
  appropriate, and links back to the ages, people, places, and passages they
  touch.

The first screen should be the usable explorer, not a marketing page: search on
the left, tree/timeline in the center, and a detail panel on the right.

## 6. MVP scope

The first version should prove the combined model, route handoff, and useful
visual exploration with a limited dataset.

### 6.1 MVP features

- Person search with aliases and disambiguation.
- Person detail pages with references, relationships, events, and notes.
- Genealogy graph for curated passages and families.
- Timeline lane for selected person, family, age, prophecy, or passage range.
- Basic age/era bands for organizing people, events, and future prophecies.
- Toggle between tree-first and timeline-first layouts.
- Deep links from LightSword passages to ages, people, events, genealogies, and
  prophecies.
- Deep links back to LightSword passages using the current `?r=` route format.
- Offline bundled starter pack.
- Export selected chart or timeline slice as PNG/SVG and JSON.
- PWA deployment at `ages.lightsword.app`.

### 6.2 Deliberately out of scope for MVP

- Full whole-Bible person graph.
- Precise universal Bible chronology.
- A complete eschatology system.
- User-created family trees.
- Collaboration or account-backed sync.
- Automatic entity extraction from every Bible text.
- Claims that compressed genealogies always represent direct parentage.
- Harmonizing Matthew and Luke into a single forced lineage.
- Forcing all prophetic passages into one interpretive timeline.

## 7. Starter dataset recommendation

Start with a high-quality curated seed pack instead of a large generated graph.
Suggested first coverage:

- Genesis 4-5: Adam through Noah, including Cainite and Sethite lines.
- Genesis 10-11: Table of Nations and Shem through Abram.
- Genesis 12-50: Abraham, Sarah, Hagar, Isaac, Rebekah, Jacob, Esau, and the
  twelve sons.
- Ruth 4: Perez to David.
- 1 Chronicles 1-9: selected lineage anchors, not every edge at first.
- Matthew 1 and Luke 3: separate genealogy traditions with shared person IDs
  only where justified.
- Selected promise/fulfillment anchors such as Genesis 3:15, 2 Samuel 7,
  Isaiah 9, Jeremiah 31, Daniel 7, Luke 1, Acts 2, Romans 8, 1 Corinthians 15,
  and Revelation 21-22.

Every record should carry source references and confidence metadata. The app
should make uncertainty inspectable but not visually noisy.

## 8. Data model

Use a stable data schema from the beginning. The visualization can change, but
person and event IDs should remain portable.

Suggested top-level pack:

```json
{
  "schemaVersion": 1,
  "packId": "biblical-ages-core",
  "title": "Biblical Ages Core",
  "version": "0.1.0",
  "license": "TBD",
  "persons": [],
  "relationships": [],
  "events": [],
  "ages": [],
  "prophecies": [],
  "sources": []
}
```

Suggested age model:

```json
{
  "id": "age.patriarchs",
  "title": "Patriarchs",
  "date": {
    "kind": "relative",
    "label": "Genesis 12-50",
    "confidence": "medium"
  },
  "referenceRange": ["gen12.1", "gen50.26"],
  "personIds": ["person.abraham", "person.isaac", "person.jacob"],
  "eventIds": ["event.call-of-abram"],
  "notes": []
}
```

Suggested person model:

```json
{
  "id": "person.abraham",
  "primaryName": "Abraham",
  "aliases": ["Abram"],
  "gender": "male",
  "tribes": [],
  "roles": ["patriarch"],
  "keyReferences": ["gen12.1", "gen15.6", "rom4.3"],
  "notes": [],
  "confidence": "high"
}
```

Suggested relationship model:

```json
{
  "id": "rel.abraham.isaac.parent",
  "type": "parent_child",
  "fromPersonId": "person.abraham",
  "toPersonId": "person.isaac",
  "references": ["gen21.3"],
  "certainty": "explicit",
  "notes": []
}
```

Suggested event model:

```json
{
  "id": "event.call-of-abram",
  "title": "Call of Abram",
  "kind": "calling",
  "date": {
    "kind": "relative",
    "label": "Patriarchal period",
    "confidence": "low"
  },
  "personIds": ["person.abraham", "person.sarah"],
  "ageIds": ["age.patriarchs"],
  "references": ["gen12.1-9"],
  "locationIds": ["place.haran", "place.canaan"]
}
```

Suggested prophecy model:

```json
{
  "id": "prophecy.new-covenant",
  "title": "New covenant promised",
  "kind": "covenant_promise",
  "references": ["jer31.31-34"],
  "relatedEventIds": [],
  "relatedAgeIds": ["age.exile", "age.new-covenant"],
  "fulfillmentStatus": "partially_fulfilled",
  "certainty": "interpretive",
  "notes": []
}
```

## 9. Date and uncertainty model

Dates need to support imprecision as a first-class concept. Do not require every
event to have a year.

Recommended date types:

- `none`: no useful date claim.
- `relative`: ordered by narrative or era without assigning an absolute year.
- `range`: approximate absolute range, such as `-2100` to `-1900`.
- `point`: exact or traditional date where supported by the source pack.
- `lifespan`: birth/death or active range for a person.
- `future`: promised, prophetic, or eschatological ordering without assigning
  an absolute date.

Each date should carry:

- `confidence`: `high`, `medium`, `low`, or `tradition`.
- `basis`: `explicit_text`, `derived`, `traditional`, or `scholarly_model`.
- `sourceIds`: references to source notes.

This lets the app display a clear timeline and age structure without pretending
all chronology, fulfillment, or future sequence is equally certain.

## 10. Shared LightSword contracts

The Ages app should reuse or track these ecosystem contracts:

| Contract | Needed for Ages | Notes |
|---|---|---|
| Reference parsing | Yes | Link every age, person, event, genealogy, and prophecy back to passages. |
| Route builder/parser | Yes | Required for `age`, `person`, `event`, `timeline`, `genealogy`, `prophecy`, and `passage` links. |
| Pack manifests | Yes | Age/person/event/prophecy datasets should be versioned offline packs. |
| Atlas/place IDs | Later | Events should be ready to link to maps without owning map rendering. |
| User-content model | Later | Useful for saved charts, teaching exports, and custom notes. |

The app should not import LightSword's reader UI. It should consume portable
domain code from `bible_core` or future shared packages.

## 11. Deep links and routes

The app should support incoming and outgoing links.

Incoming routes:

- `/person/person.abraham`
- `/person/person.david?view=timeline`
- `/age/age.patriarchs`
- `/timeline?person=person.abraham`
- `/timeline?age=age.patriarchs`
- `/timeline?ref=gen12.1-9`
- `/genealogy?root=person.abraham&depth=4`
- `/event/event.call-of-abram`
- `/prophecy/prophecy.new-covenant`
- `/compare?left=genealogy.matthew1&right=genealogy.luke3`

Outgoing LightSword routes should use the current production format until a
shared route library replaces it:

- Passage: `https://lightsword.app/?r=gen12.1-9`
- Interlinear passage: `https://lightsword.app/?r=gen12.1&mode=interlinear`

Future shared routes should include canonical `age`, `person`, `event`,
`timeline`, `genealogy`, `prophecy`, `location`, `strongs`, `lemma`, and
`passage` builders so companion apps do not handcraft URLs independently.

## 12. Visualization strategy

The app should avoid one giant whole-Bible graph as the default view. Large
graphs quickly become unreadable on mobile and unhelpful for study.

Recommended surfaces:

- Search-first person explorer.
- Focused ego graph around one person with adjustable depth.
- Age/era bands that can hold past events, future events, prophecies, and
  people.
- Lineage path view between two people.
- Side-by-side genealogy comparison for Matthew 1 and Luke 3.
- Timeline lanes for selected people, families, dynasties, and events.
- Prophecy/fulfillment lanes that can represent promised, fulfilled, partially
  fulfilled, disputed, or future events.
- Optional compact teaching export mode with a clean static chart.

For Flutter, a custom painter or graph layout package may be enough for MVP.
Keep the underlying graph layout separate from widgets so it can be tested in
pure Dart.

## 13. Recommended initial architecture

Start as an independent Flutter app if the goal is to keep LightSword lean while
sharing code and platform patterns. A web-first Flutter PWA is a good starting
point, with native and desktop later.

The first implementation should be created in a new repository, not inside this
repo, unless the maintainer explicitly chooses to fold it into the monorepo. In
Codespaces, a future agent should scaffold a normal Flutter project, keep the
domain logic in a pure Dart package, and copy only portable contracts or sample
data from LightSword. Do not import LightSword's reader UI.

Suggested repository layout:

```text
ages.lightsword.app/
  README.md
  docs/
    ARCHITECTURE.md
    DATA_SCHEMA.md
    ROUTES.md
    DATA_SOURCES.md
  ages_app/
    pubspec.yaml
    lib/
      main.dart
      ages/
      people/
      relationships/
      timeline/
      genealogy/
      search/
      export/
      platform/
      state/
    test/
    web/
  ages_core/
    pubspec.yaml
    lib/
      models/
      graph/
      chronology/
      prophecy/
      packs/
      search/
    test/
```

If this app joins the current monorepo, it can live beside `bible_app` and
`bible_core` as `ages_app` and `ages_core`. If it starts separately, it
should depend on shared packages by Git reference or published internal packages
once those boundaries are stable.

Suggested first scaffold commands for a separate repository:

```bash
flutter create --platforms web,linux,macos,windows ages_app
dart create -t package ages_core
```

Then wire `ages_app` to `ages_core` with a local path dependency while the app
is young. If shared LightSword packages become available later, replace local
copies with Git or package dependencies.

## 14. Required LightSword references

A future implementation agent should read these files before scaffolding or
porting contracts:

- [../companion-app-architecture.md](../companion-app-architecture.md) for the
  companion-app strategy, shared pack posture, and cross-app navigation model.
- [ARCHITECTURE.md](ARCHITECTURE.md) for the current `bible_core` / `bible_app`
  separation and platform abstraction pattern.
- [DEEP_LINKING.md](DEEP_LINKING.md) for the current production passage URL
  format and existing deep-link behavior.
- [DATA_LICENSES.md](DATA_LICENSES.md) for open-data constraints and attribution
  expectations.
- [PWA_IMPLEMENTATION.md](PWA_IMPLEMENTATION.md) and
  [PWA_QUICK_START.md](PWA_QUICK_START.md) for the current LightSword PWA
  patterns.

For the first Ages repo, the agent should treat this document as the product
brief and the files above as implementation references. The new repo should not
copy undocumented assumptions from the existing app; any shared behavior should
be represented as route specs, schema files, generated sample data, or small
portable Dart packages.

## 15. Development phases

### Phase 0 - Contracts and seed data

- Define age, person, relationship, event, prophecy, date, and source schemas.
- Define canonical route names for age, person, event, timeline, genealogy,
  prophecy, and passage handoff.
- Create the first curated seed dataset with source references.
- Decide pack manifest fields and license/source tracking.

### Phase 1 - Local explorer MVP

- Person search.
- Person detail panel.
- Relationship graph around selected person.
- Age bands and timeline lanes for selected person and related events.
- Basic prophecy records tied to passages, ages, and fulfillment status.
- LightSword passage links out.
- Local bundled data pack.

### Phase 2 - LightSword integration

- Open Ages from LightSword person/event/prophecy affordances.
- Open LightSword from Ages references.
- Share route parser/builder code.
- Support query parameters from copied links and external URLs.

### Phase 3 - Genealogy depth

- Lineage path finder.
- Matthew/Luke comparison view.
- Tribe, dynasty, and covenant-line filters.
- Export chart/timeline slice.
- Add more curated packs for kings, prophets, apostles, and major families.

### Phase 4 - Prophecy and age depth

- Add prophecy/fulfillment comparison views.
- Add future-event and eschatological age bands without forcing a single
  interpretive system.
- Add filters for fulfillment status, prophetic genre, covenant, and age.

### Phase 5 - Atlas and writing handoff

- Link event locations to a future atlas app.
- Insert selected charts or timeline slices into LightSword Write.
- Save custom teaching collections once shared user-content sync exists.

## 16. Technical decisions to make early

- Confirm **LightSword Ages** as the user-facing name.
- Use `ages.lightsword.app` as the single canonical URL.
- Whether `ages_core` is a new package or part of a future shared core.
- Initial data source and licensing strategy.
- Person ID scheme and alias normalization.
- Relationship type vocabulary.
- Date uncertainty model.
- Prophecy and fulfillment-status vocabulary.
- Graph layout strategy for desktop and mobile.
- Whether export uses SVG, PNG, PDF, or all three.
- Whether chart/report generation is an internal feature of Ages or a future
  sibling app.

## 17. Open questions

- Should the first screen emphasize ages, people, genealogies, timelines, or
  prophecy?
- Is the first real user need family trees, event chronology, or teaching
  visuals?
- Should chronology default to narrative order instead of absolute dates?
- How much traditional chronology should be bundled, if any?
- How should the app represent future events without forcing a single
  eschatological framework?
- Should Matthew 1 and Luke 3 be modeled as separate named genealogies from the
  beginning?
- Should women, unnamed persons, groups, and nations share the same entity
  model as named individuals?
- Should exported charts include source notes by default?
- Should the first release include a chart/report builder, or only static export
  from explorer views?

## 18. Recommended next step

Create a small proof-of-concept around Abraham, Isaac, Jacob, Esau, Joseph, and
the twelve sons. Commit only four product commitments at first:

1. Person records have stable IDs and source references.
2. Relationships and prophecy links carry certainty metadata.
3. Events and prophecies can appear within ages and timelines with approximate,
   relative, or future-oriented dates.
4. Every visible age, person, relationship, event, genealogy, and prophecy can
  link back to LightSword passages.

That proves the combined Ages direction while keeping the dataset small enough
to curate carefully.

## 19. GPT 5.5 implementation brief

When asking a future coding agent to start the new repository, give it this
brief:

Build **LightSword Ages** as a new Flutter web-first PWA at
`ages.lightsword.app`. Create a separate repository with `ages_app` for Flutter
UI and `ages_core` for pure Dart models, graph logic, chronology, packs, search,
and schema validation. Use local JSON seed data for the MVP. Implement a usable
explorer first: search, person detail, age bands, relationship graph, timeline
lane, prophecy records, and LightSword passage links. Keep the data model stable
and testable before polishing the UI.

Minimum first milestone:

1. Flutter app shell with responsive desktop/mobile layout.
2. Pure Dart models for age, person, relationship, event, prophecy, date, and
  source.
3. Seed data for the patriarchal family plus a few promise/fulfillment anchors.
4. In-memory repository loaded from bundled JSON.
5. Search and detail panel.
6. Basic relationship graph and timeline/age band rendering.
7. Outgoing LightSword passage links using `https://lightsword.app/?r=...`.
8. Focused unit tests for schema parsing, graph traversal, date ordering, and
  reference-link generation.

Do not start with account sync, collaboration, full Bible extraction, or a
complete prophecy system. Those are later phases.