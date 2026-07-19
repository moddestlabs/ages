const packUrl = '../data/biblical_ages_core/pack.json';
const lightswordBaseUrl = 'https://lightsword.app/';

const state = {
  pack: null,
  selectedPersonId: null,
  view: 'tree',
  query: '',
};

const elements = {
  search: document.querySelector('#person-search'),
  results: document.querySelector('#person-results'),
  selectedName: document.querySelector('#selected-name'),
  primaryReference: document.querySelector('#primary-reference'),
  ageList: document.querySelector('#age-list'),
  ageCount: document.querySelector('#age-count'),
  relationshipGraph: document.querySelector('#relationship-graph'),
  relationshipCount: document.querySelector('#relationship-count'),
  timelineList: document.querySelector('#timeline-list'),
  eventCount: document.querySelector('#event-count'),
  details: document.querySelector('#details'),
  filterButtons: document.querySelectorAll('[data-view]'),
};

function byId(collection) {
  return new Map(collection.map((record) => [record.id, record]));
}

function normalize(value) {
  return value.toLowerCase().trim();
}

function formatType(value) {
  return value.replaceAll('_', ' ').replaceAll('-', ' ');
}

function lightswordUrl(reference) {
  const url = new URL(lightswordBaseUrl);
  url.searchParams.set('r', reference);
  return url.toString();
}

function routeToPerson(personId) {
  const url = new URL(window.location.href);
  url.searchParams.set('person', personId);
  window.history.replaceState({}, '', url);
}

function currentPerson() {
  return state.pack.index.persons.get(state.selectedPersonId);
}

function personMatches(person) {
  const query = normalize(state.query);
  if (!query) return true;

  const fields = [person.primaryName, ...person.aliases, ...person.roles, ...person.tribes];
  return fields.some((field) => normalize(field).includes(query));
}

function relatedRelationships(personId) {
  return state.pack.relationships.filter(
    (relationship) => relationship.fromPersonId === personId || relationship.toPersonId === personId,
  );
}

function relatedAges(personId) {
  return state.pack.ages.filter((age) => age.personIds.includes(personId));
}

function relatedEvents(personId) {
  return state.pack.events.filter((event) => event.personIds.includes(personId));
}

function relatedProphecies(personId) {
  const ageIds = new Set(relatedAges(personId).map((age) => age.id));
  const eventIds = new Set(relatedEvents(personId).map((event) => event.id));

  return state.pack.prophecies.filter((prophecy) => (
    prophecy.relatedAgeIds.some((ageId) => ageIds.has(ageId))
    || prophecy.relatedEventIds.some((eventId) => eventIds.has(eventId))
  ));
}

function renderSearchResults() {
  const people = state.pack.persons.filter(personMatches);

  elements.results.innerHTML = people.map((person) => `
    <li>
      <button class="person-button ${person.id === state.selectedPersonId ? 'is-selected' : ''}" type="button" data-person-id="${person.id}">
        <span class="person-name">${person.primaryName}</span>
        <span class="person-meta">${person.roles.map(formatType).join(', ') || 'person'}</span>
      </button>
    </li>
  `).join('');
}

function renderAges(personId) {
  const ages = relatedAges(personId);
  elements.ageCount.textContent = ages.length;
  elements.ageList.innerHTML = ages.length ? ages.map((age) => `
    <article class="age-chip">
      <span class="record-title">${age.title}</span>
      <span class="record-meta">${age.date.label}</span>
    </article>
  `).join('') : '<p class="empty-state">No related ages in this seed pack.</p>';
}

function renderRelationships(personId) {
  const relationships = relatedRelationships(personId);
  elements.relationshipCount.textContent = relationships.length;

  elements.relationshipGraph.innerHTML = relationships.length ? relationships.map((relationship) => {
    const from = state.pack.index.persons.get(relationship.fromPersonId);
    const to = state.pack.index.persons.get(relationship.toPersonId);

    return `
      <article class="relationship-card">
        <span class="record-title">${from.primaryName}</span>
        <span class="relationship-type">${formatType(relationship.type)}</span>
        <span class="record-title">${to.primaryName}</span>
        <span class="record-meta">${relationship.certainty}</span>
        <span></span>
        <span class="record-meta">${relationship.references.join(', ')}</span>
      </article>
    `;
  }).join('') : '<p class="empty-state">No relationships in this seed pack.</p>';
}

function renderTimeline(personId) {
  const events = relatedEvents(personId);
  elements.eventCount.textContent = events.length;

  elements.timelineList.innerHTML = events.length ? events.map((event) => `
    <article class="event-card">
      <span class="record-title">${event.title}</span>
      <span class="record-meta">${formatType(event.kind)} · ${event.date.label}</span>
      <div class="reference-list">
        ${event.references.map((reference) => `<a class="reference-pill" href="${lightswordUrl(reference)}" target="_blank" rel="noreferrer">${reference}</a>`).join('')}
      </div>
    </article>
  `).join('') : '<p class="empty-state">No events in this seed pack.</p>';
}

function renderDetails(person) {
  const prophecies = relatedProphecies(person.id);

  elements.details.innerHTML = `
    <div class="detail-stack">
      <article class="detail-card">
        <span class="record-title">${person.primaryName}</span>
        <span class="record-meta">Confidence: ${person.confidence}</span>
        <div class="tag-list">
          ${person.aliases.map((alias) => `<span class="tag">${alias}</span>`).join('')}
          ${person.roles.map((role) => `<span class="tag">${formatType(role)}</span>`).join('')}
          ${person.tribes.map((tribe) => `<span class="tag">${tribe}</span>`).join('')}
        </div>
        <div class="reference-list">
          ${person.keyReferences.map((reference) => `<a class="reference-pill" href="${lightswordUrl(reference)}" target="_blank" rel="noreferrer">${reference}</a>`).join('')}
        </div>
      </article>
      ${prophecies.map((prophecy) => `
        <article class="prophecy-card">
          <span class="record-title">${prophecy.title}</span>
          <span class="record-meta">${formatType(prophecy.fulfillmentStatus)} · ${prophecy.certainty}</span>
          <div class="reference-list">
            ${prophecy.references.map((reference) => `<a class="reference-pill" href="${lightswordUrl(reference)}" target="_blank" rel="noreferrer">${reference}</a>`).join('')}
          </div>
        </article>
      `).join('')}
    </div>
  `;
}

function renderSelectedPerson() {
  const person = currentPerson();
  if (!person) return;

  elements.selectedName.textContent = person.primaryName;
  elements.primaryReference.href = lightswordUrl(person.keyReferences[0]);
  elements.primaryReference.textContent = `Open ${person.keyReferences[0]}`;

  renderAges(person.id);
  renderRelationships(person.id);
  renderTimeline(person.id);
  renderDetails(person);
  renderSearchResults();
}

function selectPerson(personId) {
  state.selectedPersonId = personId;
  routeToPerson(personId);
  renderSelectedPerson();
}

async function loadPack() {
  const response = await fetch(packUrl);
  if (!response.ok) {
    throw new Error(`Unable to load pack: ${response.status}`);
  }

  const pack = await response.json();
  pack.index = {
    persons: byId(pack.persons),
    relationships: byId(pack.relationships),
    events: byId(pack.events),
    ages: byId(pack.ages),
    prophecies: byId(pack.prophecies),
  };

  state.pack = pack;
}

function bindEvents() {
  elements.search.addEventListener('input', (event) => {
    state.query = event.target.value;
    renderSearchResults();
  });

  elements.results.addEventListener('click', (event) => {
    const button = event.target.closest('[data-person-id]');
    if (!button) return;
    selectPerson(button.dataset.personId);
  });

  for (const button of elements.filterButtons) {
    button.addEventListener('click', () => {
      state.view = button.dataset.view;
      for (const candidate of elements.filterButtons) {
        candidate.classList.toggle('is-active', candidate === button);
      }
    });
  }
}

async function start() {
  await loadPack();
  bindEvents();

  const params = new URLSearchParams(window.location.search);
  const requestedPersonId = params.get('person');
  const firstPersonId = state.pack.persons[0]?.id;
  state.selectedPersonId = state.pack.index.persons.has(requestedPersonId) ? requestedPersonId : firstPersonId;

  renderSearchResults();
  renderSelectedPerson();
}

start().catch((error) => {
  elements.selectedName.textContent = 'Unable to load prototype';
  elements.details.innerHTML = `<p class="empty-state">${error.message}</p>`;
});