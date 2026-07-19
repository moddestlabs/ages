import { readFile } from 'node:fs/promises';

const [packPath = 'data/biblical_ages_core/pack.json'] = process.argv.slice(2);

const passagePattern = /^[1-3]?[a-z]{2,3}[0-9]+(\.[0-9]+(-[0-9]+)?)?$/;
const idPattern = /^[a-z]+\.[a-z0-9]+(?:-[a-z0-9]+)*(?:\.[a-z0-9]+(?:-[a-z0-9]+)*)*$/;

const requiredCollections = [
  'persons',
  'relationships',
  'events',
  'ages',
  'prophecies',
  'genealogies',
  'sources',
];

const pack = JSON.parse(await readFile(packPath, 'utf8'));
const errors = [];

function requireArray(name) {
  if (!Array.isArray(pack[name])) {
    errors.push(`${name} must be an array`);
    return [];
  }
  return pack[name];
}

function collectIds(name) {
  const seen = new Set();
  const ids = new Set();

  for (const record of requireArray(name)) {
    if (!record || typeof record !== 'object') {
      errors.push(`${name} contains a non-object record`);
      continue;
    }

    if (typeof record.id !== 'string' || !idPattern.test(record.id)) {
      errors.push(`${name} has invalid id: ${record.id}`);
      continue;
    }

    if (seen.has(record.id)) {
      errors.push(`${name} has duplicate id: ${record.id}`);
    }

    seen.add(record.id);
    ids.add(record.id);
  }

  return ids;
}

function checkRefs(ownerId, refs) {
  if (!Array.isArray(refs)) {
    errors.push(`${ownerId} references must be an array`);
    return;
  }

  for (const ref of refs) {
    if (typeof ref !== 'string' || !passagePattern.test(ref)) {
      errors.push(`${ownerId} has invalid passage reference: ${ref}`);
    }
  }
}

function checkIds(ownerId, field, values, ids) {
  if (!Array.isArray(values)) {
    errors.push(`${ownerId} ${field} must be an array`);
    return;
  }

  for (const value of values) {
    if (!ids.has(value)) {
      errors.push(`${ownerId} ${field} references missing id: ${value}`);
    }
  }
}

for (const collection of requiredCollections) {
  requireArray(collection);
}

const personIds = collectIds('persons');
const relationshipIds = collectIds('relationships');
const eventIds = collectIds('events');
const ageIds = collectIds('ages');
collectIds('prophecies');
collectIds('genealogies');
const sourceIds = collectIds('sources');

const allReferenceOwners = [
  ...pack.persons.map((record) => [record.id, record.keyReferences]),
  ...pack.relationships.map((record) => [record.id, record.references]),
  ...pack.events.map((record) => [record.id, record.references]),
  ...pack.ages.map((record) => [record.id, record.referenceRange]),
  ...pack.prophecies.map((record) => [record.id, record.references]),
  ...pack.genealogies.map((record) => [record.id, record.references]),
  ...pack.sources.map((record) => [record.id, record.references]),
];

for (const [ownerId, refs] of allReferenceOwners) {
  checkRefs(ownerId, refs);
}

for (const relationship of pack.relationships) {
  if (!personIds.has(relationship.fromPersonId)) {
    errors.push(`${relationship.id} fromPersonId missing: ${relationship.fromPersonId}`);
  }
  if (!personIds.has(relationship.toPersonId)) {
    errors.push(`${relationship.id} toPersonId missing: ${relationship.toPersonId}`);
  }
}

for (const event of pack.events) {
  checkIds(event.id, 'personIds', event.personIds, personIds);
  checkIds(event.id, 'ageIds', event.ageIds, ageIds);
  checkIds(event.id, 'date.sourceIds', event.date?.sourceIds ?? [], sourceIds);
}

for (const age of pack.ages) {
  checkIds(age.id, 'personIds', age.personIds, personIds);
  checkIds(age.id, 'eventIds', age.eventIds, eventIds);
  checkIds(age.id, 'date.sourceIds', age.date?.sourceIds ?? [], sourceIds);
}

for (const prophecy of pack.prophecies) {
  checkIds(prophecy.id, 'relatedEventIds', prophecy.relatedEventIds, eventIds);
  checkIds(prophecy.id, 'relatedAgeIds', prophecy.relatedAgeIds, ageIds);
}

for (const genealogy of pack.genealogies) {
  checkIds(genealogy.id, 'relationshipIds', genealogy.relationshipIds, relationshipIds);
  checkIds(genealogy.id, 'personIds', genealogy.personIds, personIds);
}

if (errors.length > 0) {
  console.error(`Pack validation failed for ${packPath}:`);
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(`Pack validation passed for ${packPath}`);
console.log(`persons=${pack.persons.length} relationships=${pack.relationships.length} events=${pack.events.length} ages=${pack.ages.length} prophecies=${pack.prophecies.length} genealogies=${pack.genealogies.length}`);