# Seed Data Notes

The starter pack is intentionally small and curated. It exists to prove the
combined people, relationships, ages, events, timeline, and prophecy model before
the app attempts broad biblical coverage.

## First coverage

- patriarchal family anchors from Genesis 11-50
- Ruth 4 as a bridge toward David
- Matthew 1 and Luke 3 as separate genealogy records
- promise and fulfillment anchors for Genesis 3, Genesis 12, 2 Samuel 7, Luke 1,
  and Revelation 21

## Data posture

- Every claim should include source references.
- Compressed genealogies should use `ancestor_descendant`, not `parent_child`.
- Concubine relationships should use `concubine`, while birth relationships
  should still use explicit `parent_child` edges for both parents where the text
  identifies them.
- Matthew 1 and Luke 3 remain separate named genealogies.
- Approximate chronology should use relative labels until a chronology pack is
  deliberately chosen.
- Prophecy records should describe relationships to passages and ages without
  forcing a complete interpretive timeline.

## Validation expectations

Run `npm test` after editing the pack. The validator checks duplicate IDs,
missing references, malformed LightSword passage references, and relationship
endpoints.