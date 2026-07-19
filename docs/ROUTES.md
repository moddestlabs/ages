# LightSword Ages Routes

This file records the first route contract for the Ages companion app. It should
eventually become shared code, but the written contract comes first so seed data,
UI links, and LightSword handoff all use the same vocabulary.

## Canonical hosts

- Ages: `https://ages.lightsword.app`
- LightSword reader: `https://lightsword.app`

## Incoming Ages routes

| Entity | Route | Example |
|---|---|---|
| Age | `/age/:ageId` | `/age/age.patriarchs` |
| Person | `/person/:personId` | `/person/person.abraham` |
| Event | `/event/:eventId` | `/event/event.call-of-abram` |
| Prophecy | `/prophecy/:prophecyId` | `/prophecy/prophecy.seed-promise` |
| Timeline | `/timeline` | `/timeline?person=person.abraham` |
| Genealogy | `/genealogy` | `/genealogy?root=person.jacob&depth=2` |
| Compare | `/compare` | `/compare?left=genealogy.matthew1&right=genealogy.luke3` |

Entity IDs are passed exactly as stored in the data pack. Query parameters must
be URL encoded by app code.

## Outgoing LightSword routes

Ages links back to LightSword passages with the current production format:

```text
https://lightsword.app/?r=<reference>
https://lightsword.app/?r=<reference>&mode=interlinear
```

Examples:

```text
https://lightsword.app/?r=gen12.1-9
https://lightsword.app/?r=gen15.6&mode=interlinear
```

## Initial route fields in data

Records should not store full Ages URLs. Store stable IDs and passage references;
route builders can derive URLs from them.

```json
{
  "personId": "person.abraham",
  "references": ["gen12.1-9"]
}
```