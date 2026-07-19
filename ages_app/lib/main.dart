import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const AgesApp());
}

const packAssetPath = '../data/biblical_ages_core/pack.json';
const lightswordBaseUrl = 'https://lightsword.app/';

enum _ExplorerMode { people, events }

String? initialPersonIdFromUri([Uri? uri]) {
  final source = uri ?? Uri.base;
  final queryPersonId = source.queryParameters['person'];
  if (queryPersonId != null && queryPersonId.isNotEmpty) return queryPersonId;

  final segments = source.pathSegments;
  final personSegmentIndex = segments.indexOf('person');
  if (personSegmentIndex >= 0 && personSegmentIndex + 1 < segments.length) {
    return segments[personSegmentIndex + 1];
  }

  return null;
}

String? initialEventIdFromUri([Uri? uri]) {
  final source = uri ?? Uri.base;
  final queryEventId = source.queryParameters['event'];
  if (queryEventId != null && queryEventId.isNotEmpty) return queryEventId;

  final segments = source.pathSegments;
  final eventSegmentIndex = segments.indexOf('event');
  if (eventSegmentIndex >= 0 && eventSegmentIndex + 1 < segments.length) {
    return segments[eventSegmentIndex + 1];
  }

  return null;
}

String? initialReferenceFromUri([Uri? uri]) {
  final reference = (uri ?? Uri.base).queryParameters['r'];
  if (reference == null || reference.isEmpty) return null;
  return reference;
}

Uri agesPersonUri(String personId) => Uri(path: '/person/$personId');

Uri agesEventUri(String eventId) => Uri(path: '/event/$eventId');

Uri lightswordUri(String reference) {
  return Uri.parse(
    lightswordBaseUrl,
  ).replace(queryParameters: {'r': reference});
}

Future<void> openLightSwordReference(
  BuildContext context,
  String reference,
) async {
  final uri = lightswordUri(reference);
  final launched = await launchUrl(uri, webOnlyWindowName: '_blank');

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to open $uri')));
  }
}

class AgesApp extends StatelessWidget {
  const AgesApp({super.key});

  @override
  Widget build(BuildContext context) {
    const cedar = Color(0xff3d6f64);
    const fig = Color(0xff8b4f3d);
    const paper = Color(0xfff8f5ee);

    return MaterialApp(
      title: 'LightSword Ages',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: cedar,
          primary: cedar,
          secondary: fig,
          surface: const Color(0xfffffdf8),
        ),
        scaffoldBackgroundColor: paper,
        useMaterial3: true,
      ),
      home: const AgesExplorerScreen(),
    );
  }
}

class AgesExplorerScreen extends StatefulWidget {
  const AgesExplorerScreen({super.key});

  @override
  State<AgesExplorerScreen> createState() => _AgesExplorerScreenState();
}

class _AgesExplorerScreenState extends State<AgesExplorerScreen> {
  late final Future<AgesPack> _packFuture = AgesPack.loadFromAsset(
    packAssetPath,
  );
  late final String? _initialPersonId = initialPersonIdFromUri();
  late final String? _initialEventId = initialEventIdFromUri();
  late final String? _initialReference = initialReferenceFromUri();
  late _ExplorerMode _mode = _initialEventId == null
      ? _ExplorerMode.people
      : _ExplorerMode.events;
  String _query = '';
  String? _selectedPersonId;
  String? _selectedEventId;

  void _selectPerson(String personId) {
    setState(() {
      _mode = _ExplorerMode.people;
      _selectedPersonId = personId;
      _selectedEventId = null;
    });
    unawaited(
      SystemNavigator.routeInformationUpdated(
        uri: agesPersonUri(personId),
        state: {'person': personId},
      ),
    );
  }

  void _selectEvent(String eventId) {
    setState(() {
      _mode = _ExplorerMode.events;
      _selectedEventId = eventId;
    });
    unawaited(
      SystemNavigator.routeInformationUpdated(
        uri: agesEventUri(eventId),
        state: {'event': eventId},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AgesPack>(
      future: _packFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Unable to load Ages pack: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pack = snapshot.data!;
        final initialPersonId = _initialPersonId;
        final initialReferencePersonId = _initialReference == null
            ? null
            : pack.personIdForReference(_initialReference);
        final effectiveInitialPersonId =
            initialPersonId ?? initialReferencePersonId;
        final selectedPersonId =
            _selectedPersonId ??
            (effectiveInitialPersonId != null &&
                    pack.personById.containsKey(effectiveInitialPersonId)
                ? effectiveInitialPersonId
                : pack.persons.first.id);
        final selectedPerson =
            pack.personById[selectedPersonId] ?? pack.persons.first;
        final matchingPeople = pack.searchPeople(_query);
        final matchingEvents = pack.searchEvents(_query);
        final selectedEventId = _selectedEventId ?? _initialEventId;
        final selectedEvent = selectedEventId == null
            ? null
          : pack.eventById[selectedEventId];

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 920;
                final sidebar = _ExplorerSidebar(
                  mode: _mode,
                  people: matchingPeople,
                  events: matchingEvents,
                  selectedPersonId: selectedPerson.id,
                  selectedEventId: selectedEvent?.id,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onQueryChanged: (value) => setState(() => _query = value),
                  onPersonSelected: _selectPerson,
                  onEventSelected: _selectEvent,
                );
                final workspace = _ExplorerWorkspace(
                  pack: pack,
                  person: selectedPerson,
                  event: selectedEvent,
                );
                final details = _DetailPanel(
                  pack: pack,
                  person: selectedPerson,
                  event: selectedEvent,
                );

                if (isNarrow) {
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      sidebar,
                      const SizedBox(height: 12),
                      SizedBox(height: 640, child: workspace),
                      const SizedBox(height: 12),
                      details,
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 292, child: sidebar),
                      const SizedBox(width: 16),
                      Expanded(child: workspace),
                      const SizedBox(width: 16),
                      SizedBox(width: 340, child: details),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ExplorerSidebar extends StatelessWidget {
  const _ExplorerSidebar({
    required this.mode,
    required this.people,
    required this.events,
    required this.selectedPersonId,
    required this.selectedEventId,
    required this.onModeChanged,
    required this.onQueryChanged,
    required this.onPersonSelected,
    required this.onEventSelected,
  });

  final _ExplorerMode mode;
  final List<PersonRecord> people;
  final List<EventRecord> events;
  final String selectedPersonId;
  final String? selectedEventId;
  final ValueChanged<_ExplorerMode> onModeChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onPersonSelected;
  final ValueChanged<String> onEventSelected;

  @override
  Widget build(BuildContext context) {
    final showingEvents = mode == _ExplorerMode.events;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('LightSword Ages'),
          Text(
            'Explorer',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          SegmentedButton<_ExplorerMode>(
            segments: const [
              ButtonSegment(
                value: _ExplorerMode.people,
                icon: Icon(Icons.people_alt_outlined),
                label: Text('People'),
              ),
              ButtonSegment(
                value: _ExplorerMode.events,
                icon: Icon(Icons.event_note_outlined),
                label: Text('Events'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => onModeChanged(selection.single),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              labelText: showingEvents ? 'Search events' : 'Search people',
              hintText: showingEvents
                  ? "Births, covenant, Rachel"
                  : 'Abraham, David, Jesus',
              prefixIcon: Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: ListView.separated(
              itemCount: showingEvents ? events.length : people.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (showingEvents) {
                  final event = events[index];
                  final selected = event.id == selectedEventId;
                  return FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(14),
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    onPressed: () => onEventSelected(event.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${formatToken(event.kind)} · ${event.date.label}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }

                final person = people[index];
                final selected = person.id == selectedPersonId;
                return FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(14),
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  onPressed: () => onPersonSelected(person.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.primaryName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        person.roles.map(formatToken).join(', '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerWorkspace extends StatelessWidget {
  const _ExplorerWorkspace({required this.pack, required this.person, this.event});

  final AgesPack pack;
  final PersonRecord person;
  final EventRecord? event;

  @override
  Widget build(BuildContext context) {
    final selectedEvent = event;
    if (selectedEvent != null) {
      return _EventWorkspace(pack: pack, event: selectedEvent);
    }

    final relationships = pack.relationshipsFor(person.id);
    final events = pack.eventsFor(person.id);
    final ages = pack.agesFor(person.id);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('Selected person'),
                    Text(
                      person.primaryName,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              _LightSwordChip(reference: person.keyReferences.first),
            ],
          ),
          const SizedBox(height: 18),
          _SectionHeader(title: 'Ages', count: ages.length),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => SizedBox(
                width: 230,
                child: _RecordCard(
                  title: ages[index].title,
                  subtitle: ages[index].date.label,
                  leadingColor: const Color(0xffb9852f),
                  child: referenceChipsOrNull(ages[index].referenceRange),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _RelationshipList(
                    pack: pack,
                    relationships: relationships,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _TimelineList(events: events)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventWorkspace extends StatelessWidget {
  const _EventWorkspace({required this.pack, required this.event});

  final AgesPack pack;
  final EventRecord event;

  @override
  Widget build(BuildContext context) {
    final people = event.personIds
        .map((personId) => pack.personById[personId])
        .whereType<PersonRecord>()
        .toList();
    final ages = pack.agesForEvent(event.id);
    final prophecies = pack.propheciesForEvent(event.id);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('Selected event'),
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (event.references.isNotEmpty)
                _LightSwordChip(reference: event.references.first),
            ],
          ),
          const SizedBox(height: 18),
          _RecordCard(
            title: formatToken(event.kind),
            subtitle: event.date.label,
            leadingColor: const Color(0xff8b4f3d),
            child: referenceChipsOrNull(event.references),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _PersonChipList(title: 'People', people: people)),
                const SizedBox(width: 16),
                Expanded(
                  child: _LinkedRecordList(
                    title: 'Context',
                    cards: [
                      ...ages.map(
                        (age) => _RecordCard(
                          title: age.title,
                          subtitle: age.date.label,
                          leadingColor: const Color(0xffb9852f),
                          child: referenceChipsOrNull(age.referenceRange),
                        ),
                      ),
                      ...prophecies.map(
                        (prophecy) => _RecordCard(
                          title: prophecy.title,
                          subtitle:
                              '${formatToken(prophecy.fulfillmentStatus)} · ${prophecy.certainty}',
                          leadingColor: const Color(0xff8b4f3d),
                          child: referenceChipsOrNull(prophecy.references),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonChipList extends StatelessWidget {
  const _PersonChipList({required this.title, required this.people});

  final String title;
  final List<PersonRecord> people;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, count: people.length),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final person = people[index];
              return _RecordCard(
                title: person.primaryName,
                subtitle: person.roles.map(formatToken).join(', '),
                leadingColor: Theme.of(context).colorScheme.primary,
                child: referenceChipsOrNull(person.keyReferences),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LinkedRecordList extends StatelessWidget {
  const _LinkedRecordList({required this.title, required this.cards});

  final String title;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, count: cards.length),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => cards[index],
          ),
        ),
      ],
    );
  }
}

class _RelationshipList extends StatelessWidget {
  const _RelationshipList({required this.pack, required this.relationships});

  final AgesPack pack;
  final List<RelationshipRecord> relationships;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Relationships', count: relationships.length),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: relationships.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final relationship = relationships[index];
              final from = pack.personById[relationship.fromPersonId]!;
              final to = pack.personById[relationship.toPersonId]!;
              return _RecordCard(
                title: '${from.primaryName} -> ${to.primaryName}',
                subtitle:
                    '${formatToken(relationship.type)} · ${relationship.certainty}',
                leadingColor: Theme.of(context).colorScheme.primary,
                child: referenceChipsOrNull(relationship.references),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<EventRecord> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Timeline', count: events.length),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _RecordCard(
              title: events[index].title,
              subtitle:
                  '${formatToken(events[index].kind)} · ${events[index].date.label}',
              leadingColor: const Color(0xff8b4f3d),
              child: referenceChipsOrNull(events[index].references),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.pack, required this.person, this.event});

  final AgesPack pack;
  final PersonRecord person;
  final EventRecord? event;

  @override
  Widget build(BuildContext context) {
    final selectedEvent = event;
    if (selectedEvent != null) {
      final people = selectedEvent.personIds
          .map((personId) => pack.personById[personId])
          .whereType<PersonRecord>()
          .toList();

      return _Panel(
        child: ListView(
          children: [
            const _SectionHeader(title: 'Event details'),
            const SizedBox(height: 12),
            _RecordCard(
              title: selectedEvent.title,
              subtitle:
                  '${formatToken(selectedEvent.kind)} · ${selectedEvent.date.label}',
              leadingColor: const Color(0xff8b4f3d),
              child: referenceChipsOrNull(selectedEvent.references),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'People', count: people.length),
            const SizedBox(height: 8),
            ...people.map(
              (person) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecordCard(
                  title: person.primaryName,
                  subtitle: person.roles.map(formatToken).join(', '),
                  leadingColor: Theme.of(context).colorScheme.primary,
                  child: referenceChipsOrNull(person.keyReferences),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final prophecies = pack.propheciesFor(person.id);

    return _Panel(
      child: ListView(
        children: [
          const _SectionHeader(title: 'Details'),
          const SizedBox(height: 12),
          _RecordCard(
            title: person.primaryName,
            subtitle: 'Confidence: ${person.confidence}',
            leadingColor: Theme.of(context).colorScheme.primary,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...person.aliases.map((alias) => Chip(label: Text(alias))),
                ...person.roles.map(
                  (role) => Chip(label: Text(formatToken(role))),
                ),
                ...person.tribes.map((tribe) => Chip(label: Text(tribe))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (person.keyReferences.isNotEmpty)
            _ReferenceChips(references: person.keyReferences),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Related prophecy', count: prophecies.length),
          const SizedBox(height: 8),
          ...prophecies.map(
            (prophecy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecordCard(
                title: prophecy.title,
                subtitle:
                    '${formatToken(prophecy.fulfillmentStatus)} · ${prophecy.certainty}',
                leadingColor: const Color(0xff8b4f3d),
                child: referenceChipsOrNull(prophecy.references),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(color: const Color(0xffd9d0c1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1f24302f),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.subtitle,
    required this.leadingColor,
    this.child,
  });

  final String title;
  final String subtitle;
  final Color leadingColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffffaf0),
        border: Border(
          left: BorderSide(color: leadingColor, width: 4),
          top: const BorderSide(color: Color(0xffd9d0c1)),
          right: const BorderSide(color: Color(0xffd9d0c1)),
          bottom: const BorderSide(color: Color(0xffd9d0c1)),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (child != null) ...[const SizedBox(height: 10), child!],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        if (count != null) Badge(label: Text('$count')),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _LightSwordChip extends StatelessWidget {
  const _LightSwordChip({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final uri = lightswordUri(reference);
    return ActionChip(
      avatar: const Icon(Icons.open_in_new, size: 16),
      label: Text(reference),
      onPressed: () => openLightSwordReference(context, reference),
      tooltip: uri.toString(),
    );
  }
}

class _ReferenceChips extends StatelessWidget {
  const _ReferenceChips({required this.references});

  final List<String> references;

  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: references
          .map((reference) => _LightSwordChip(reference: reference))
          .toList(),
    );
  }
}

Widget? referenceChipsOrNull(List<String> references) {
  if (references.isEmpty) return null;
  return _ReferenceChips(references: references);
}

String formatToken(String value) =>
    value.replaceAll('_', ' ').replaceAll('-', ' ');

class AgesPack {
  AgesPack({
    required this.persons,
    required this.relationships,
    required this.events,
    required this.ages,
    required this.prophecies,
  }) : personById = {for (final person in persons) person.id: person},
       eventById = {for (final event in events) event.id: event};

  final List<PersonRecord> persons;
  final List<RelationshipRecord> relationships;
  final List<EventRecord> events;
  final List<AgeRecord> ages;
  final List<ProphecyRecord> prophecies;
  final Map<String, PersonRecord> personById;
  final Map<String, EventRecord> eventById;

  static Future<AgesPack> loadFromAsset(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    return AgesPack.fromJson(jsonDecode(source) as Map<String, Object?>);
  }

  factory AgesPack.fromJson(Map<String, Object?> json) {
    return AgesPack(
      persons: records(json['persons'], PersonRecord.fromJson),
      relationships: records(
        json['relationships'],
        RelationshipRecord.fromJson,
      ),
      events: records(json['events'], EventRecord.fromJson),
      ages: records(json['ages'], AgeRecord.fromJson),
      prophecies: records(json['prophecies'], ProphecyRecord.fromJson),
    );
  }

  List<PersonRecord> searchPeople(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return persons;
    return persons
        .where(
          (person) => [
            person.primaryName,
            ...person.aliases,
            ...person.roles,
            ...person.tribes,
          ].any((field) => field.toLowerCase().contains(normalizedQuery)),
        )
        .toList();
  }

  List<EventRecord> searchEvents(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return events;
    return events
        .where(
          (event) => [
            event.title,
            event.kind,
            event.date.label,
            ...event.references,
          ].any((field) => field.toLowerCase().contains(normalizedQuery)),
        )
        .toList();
  }

  List<RelationshipRecord> relationshipsFor(String personId) => relationships
      .where(
        (relationship) =>
            relationship.fromPersonId == personId ||
            relationship.toPersonId == personId,
      )
      .toList();

  List<EventRecord> eventsFor(String personId) =>
      events.where((event) => event.personIds.contains(personId)).toList();

  List<AgeRecord> agesFor(String personId) =>
      ages.where((age) => age.personIds.contains(personId)).toList();

    List<AgeRecord> agesForEvent(String eventId) =>
      ages.where((age) => age.eventIds.contains(eventId)).toList();

    List<ProphecyRecord> propheciesForEvent(String eventId) => prophecies
      .where((prophecy) => prophecy.relatedEventIds.contains(eventId))
      .toList();

  String? personIdForReference(String reference) {
    final normalizedReference = reference.toLowerCase();

    for (final person in persons) {
      if (person.keyReferences.any(
        (candidate) => candidate.toLowerCase() == normalizedReference,
      )) {
        return person.id;
      }
    }

    for (final event in events) {
      if (event.references.any(
        (candidate) => candidate.toLowerCase() == normalizedReference,
      )) {
        return event.personIds.firstOrNull;
      }
    }

    for (final relationship in relationships) {
      if (relationship.references.any(
        (candidate) => candidate.toLowerCase() == normalizedReference,
      )) {
        return relationship.fromPersonId;
      }
    }

    for (final age in ages) {
      if (age.referenceRange.any(
        (candidate) => candidate.toLowerCase() == normalizedReference,
      )) {
        return age.personIds.firstOrNull;
      }
    }

    for (final prophecy in prophecies) {
      if (prophecy.references.any(
        (candidate) => candidate.toLowerCase() == normalizedReference,
      )) {
        final eventIds = prophecy.relatedEventIds.toSet();
        for (final event in events) {
          if (eventIds.contains(event.id)) return event.personIds.firstOrNull;
        }

        final ageIds = prophecy.relatedAgeIds.toSet();
        for (final age in ages) {
          if (ageIds.contains(age.id)) return age.personIds.firstOrNull;
        }
      }
    }

    return null;
  }

  List<ProphecyRecord> propheciesFor(String personId) {
    final relatedAgeIds = agesFor(personId).map((age) => age.id).toSet();
    final relatedEventIds = eventsFor(
      personId,
    ).map((event) => event.id).toSet();
    return prophecies
        .where(
          (prophecy) =>
              prophecy.relatedAgeIds.any(relatedAgeIds.contains) ||
              prophecy.relatedEventIds.any(relatedEventIds.contains),
        )
        .toList();
  }
}

class PersonRecord {
  PersonRecord({
    required this.id,
    required this.primaryName,
    required this.aliases,
    required this.roles,
    required this.tribes,
    required this.keyReferences,
    required this.confidence,
  });

  final String id;
  final String primaryName;
  final List<String> aliases;
  final List<String> roles;
  final List<String> tribes;
  final List<String> keyReferences;
  final String confidence;

  factory PersonRecord.fromJson(Map<String, Object?> json) => PersonRecord(
    id: json.string('id'),
    primaryName: json.string('primaryName'),
    aliases: json.strings('aliases'),
    roles: json.strings('roles'),
    tribes: json.strings('tribes'),
    keyReferences: json.strings('keyReferences'),
    confidence: json.string('confidence'),
  );
}

class RelationshipRecord {
  RelationshipRecord({
    required this.id,
    required this.type,
    required this.fromPersonId,
    required this.toPersonId,
    required this.references,
    required this.certainty,
  });

  final String id;
  final String type;
  final String fromPersonId;
  final String toPersonId;
  final List<String> references;
  final String certainty;

  factory RelationshipRecord.fromJson(Map<String, Object?> json) =>
      RelationshipRecord(
        id: json.string('id'),
        type: json.string('type'),
        fromPersonId: json.string('fromPersonId'),
        toPersonId: json.string('toPersonId'),
        references: json.optionalStrings('references'),
        certainty: json.string('certainty'),
      );
}

class EventRecord {
  EventRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.date,
    required this.personIds,
    required this.references,
  });

  final String id;
  final String title;
  final String kind;
  final DateClaim date;
  final List<String> personIds;
  final List<String> references;

  factory EventRecord.fromJson(Map<String, Object?> json) => EventRecord(
    id: json.string('id'),
    title: json.string('title'),
    kind: json.string('kind'),
    date: DateClaim.fromJson(json.object('date')),
    personIds: json.strings('personIds'),
    references: json.optionalStrings('references'),
  );
}

class AgeRecord {
  AgeRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.referenceRange,
    required this.personIds,
    required this.eventIds,
  });

  final String id;
  final String title;
  final DateClaim date;
  final List<String> referenceRange;
  final List<String> personIds;
  final List<String> eventIds;

  factory AgeRecord.fromJson(Map<String, Object?> json) => AgeRecord(
    id: json.string('id'),
    title: json.string('title'),
    date: DateClaim.fromJson(json.object('date')),
    referenceRange: json.optionalStrings('referenceRange'),
    personIds: json.strings('personIds'),
    eventIds: json.optionalStrings('eventIds'),
  );
}

class ProphecyRecord {
  ProphecyRecord({
    required this.id,
    required this.title,
    required this.references,
    required this.fulfillmentStatus,
    required this.certainty,
    required this.relatedEventIds,
    required this.relatedAgeIds,
  });

  final String id;
  final String title;
  final List<String> references;
  final String fulfillmentStatus;
  final String certainty;
  final List<String> relatedEventIds;
  final List<String> relatedAgeIds;

  factory ProphecyRecord.fromJson(Map<String, Object?> json) => ProphecyRecord(
    id: json.string('id'),
    title: json.string('title'),
    references: json.optionalStrings('references'),
    fulfillmentStatus: json.string('fulfillmentStatus'),
    certainty: json.string('certainty'),
    relatedEventIds: json.strings('relatedEventIds'),
    relatedAgeIds: json.strings('relatedAgeIds'),
  );
}

class DateClaim {
  DateClaim({required this.kind, required this.label});

  final String kind;
  final String label;

  factory DateClaim.fromJson(Map<String, Object?> json) =>
      DateClaim(kind: json.string('kind'), label: json.string('label'));
}

List<T> records<T>(Object? value, T Function(Map<String, Object?>) fromJson) =>
    (value as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(fromJson)
        .toList();

extension JsonRead on Map<String, Object?> {
  String string(String key) => this[key] as String;

  List<String> strings(String key) =>
      (this[key] as List<Object?>).cast<String>();

  List<String> optionalStrings(String key) =>
      ((this[key] as List<Object?>?) ?? const <Object?>[]).cast<String>();

  Map<String, Object?> object(String key) => this[key] as Map<String, Object?>;
}
