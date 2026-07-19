import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AgesApp());
}

const packAssetPath = '../data/biblical_ages_core/pack.json';
const lightswordBaseUrl = 'https://lightsword.app/';

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
        colorScheme: ColorScheme.fromSeed(seedColor: cedar, primary: cedar, secondary: fig, surface: const Color(0xfffffdf8)),
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
  late final Future<AgesPack> _packFuture = AgesPack.loadFromAsset(packAssetPath);
  String _query = '';
  String? _selectedPersonId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AgesPack>(
      future: _packFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Unable to load Ages pack: ${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final pack = snapshot.data!;
        final selectedPersonId = _selectedPersonId ?? pack.persons.first.id;
        final selectedPerson = pack.personById[selectedPersonId] ?? pack.persons.first;
        final matchingPeople = pack.searchPeople(_query);

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 920;
                final sidebar = _PeopleSidebar(
                  people: matchingPeople,
                  selectedPersonId: selectedPerson.id,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onPersonSelected: (personId) => setState(() => _selectedPersonId = personId),
                );
                final workspace = _ExplorerWorkspace(pack: pack, person: selectedPerson);
                final details = _DetailPanel(pack: pack, person: selectedPerson);

                if (isNarrow) {
                  return ListView(padding: const EdgeInsets.all(12), children: [sidebar, const SizedBox(height: 12), SizedBox(height: 640, child: workspace), const SizedBox(height: 12), details]);
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

class _PeopleSidebar extends StatelessWidget {
  const _PeopleSidebar({required this.people, required this.selectedPersonId, required this.onQueryChanged, required this.onPersonSelected});

  final List<PersonRecord> people;
  final String selectedPersonId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onPersonSelected;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('LightSword Ages'),
          Text('Explorer', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          TextField(
            onChanged: onQueryChanged,
            decoration: const InputDecoration(labelText: 'Search people', hintText: 'Abraham, David, Jesus', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: ListView.separated(
              itemCount: people.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final person = people[index];
                final selected = person.id == selectedPersonId;
                return FilledButton.tonal(
                  style: FilledButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(14), backgroundColor: selected ? Theme.of(context).colorScheme.primaryContainer : null),
                  onPressed: () => onPersonSelected(person.id),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(person.primaryName, style: const TextStyle(fontWeight: FontWeight.w800)), Text(person.roles.map(formatToken).join(', '), overflow: TextOverflow.ellipsis)]),
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
  const _ExplorerWorkspace({required this.pack, required this.person});

  final AgesPack pack;
  final PersonRecord person;

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _Eyebrow('Selected person'), Text(person.primaryName, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900))])),
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
              itemBuilder: (context, index) => SizedBox(width: 230, child: _RecordCard(title: ages[index].title, subtitle: ages[index].date.label, leadingColor: const Color(0xffb9852f))),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _RelationshipList(pack: pack, relationships: relationships)),
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
              return _RecordCard(title: '${from.primaryName} -> ${to.primaryName}', subtitle: '${formatToken(relationship.type)} · ${relationship.certainty}', leadingColor: Theme.of(context).colorScheme.primary);
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
            itemBuilder: (context, index) => _RecordCard(title: events[index].title, subtitle: '${formatToken(events[index].kind)} · ${events[index].date.label}', leadingColor: const Color(0xff8b4f3d)),
          ),
        ),
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.pack, required this.person});

  final AgesPack pack;
  final PersonRecord person;

  @override
  Widget build(BuildContext context) {
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
            child: Wrap(spacing: 6, runSpacing: 6, children: [...person.aliases.map((alias) => Chip(label: Text(alias))), ...person.roles.map((role) => Chip(label: Text(formatToken(role)))), ...person.tribes.map((tribe) => Chip(label: Text(tribe)))]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: person.keyReferences.map((reference) => _LightSwordChip(reference: reference)).toList()),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Related prophecy', count: prophecies.length),
          const SizedBox(height: 8),
          ...prophecies.map((prophecy) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _RecordCard(title: prophecy.title, subtitle: '${formatToken(prophecy.fulfillmentStatus)} · ${prophecy.certainty}', leadingColor: const Color(0xff8b4f3d)))),
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
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94), border: Border.all(color: const Color(0xffd9d0c1)), boxShadow: const [BoxShadow(color: Color(0x1f24302f), blurRadius: 40, offset: Offset(0, 18))]),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.title, required this.subtitle, required this.leadingColor, this.child});

  final String title;
  final String subtitle;
  final Color leadingColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xfffffaf0), border: Border(left: BorderSide(color: leadingColor, width: 4), top: const BorderSide(color: Color(0xffd9d0c1)), right: const BorderSide(color: Color(0xffd9d0c1)), bottom: const BorderSide(color: Color(0xffd9d0c1))), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), if (child != null) ...[const SizedBox(height: 10), child!]]),
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
    return Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))), if (count != null) Badge(label: Text('$count'))]);
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0));
  }
}

class _LightSwordChip extends StatelessWidget {
  const _LightSwordChip({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return ActionChip(avatar: const Icon(Icons.open_in_new, size: 16), label: Text(reference), onPressed: () {}, tooltip: '$lightswordBaseUrl?r=$reference');
  }
}

String formatToken(String value) => value.replaceAll('_', ' ').replaceAll('-', ' ');

class AgesPack {
  AgesPack({required this.persons, required this.relationships, required this.events, required this.ages, required this.prophecies}) : personById = {for (final person in persons) person.id: person};

  final List<PersonRecord> persons;
  final List<RelationshipRecord> relationships;
  final List<EventRecord> events;
  final List<AgeRecord> ages;
  final List<ProphecyRecord> prophecies;
  final Map<String, PersonRecord> personById;

  static Future<AgesPack> loadFromAsset(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    return AgesPack.fromJson(jsonDecode(source) as Map<String, Object?>);
  }

  factory AgesPack.fromJson(Map<String, Object?> json) {
    return AgesPack(persons: records(json['persons'], PersonRecord.fromJson), relationships: records(json['relationships'], RelationshipRecord.fromJson), events: records(json['events'], EventRecord.fromJson), ages: records(json['ages'], AgeRecord.fromJson), prophecies: records(json['prophecies'], ProphecyRecord.fromJson));
  }

  List<PersonRecord> searchPeople(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return persons;
    return persons.where((person) => [person.primaryName, ...person.aliases, ...person.roles, ...person.tribes].any((field) => field.toLowerCase().contains(normalizedQuery))).toList();
  }

  List<RelationshipRecord> relationshipsFor(String personId) => relationships.where((relationship) => relationship.fromPersonId == personId || relationship.toPersonId == personId).toList();

  List<EventRecord> eventsFor(String personId) => events.where((event) => event.personIds.contains(personId)).toList();

  List<AgeRecord> agesFor(String personId) => ages.where((age) => age.personIds.contains(personId)).toList();

  List<ProphecyRecord> propheciesFor(String personId) {
    final relatedAgeIds = agesFor(personId).map((age) => age.id).toSet();
    final relatedEventIds = eventsFor(personId).map((event) => event.id).toSet();
    return prophecies.where((prophecy) => prophecy.relatedAgeIds.any(relatedAgeIds.contains) || prophecy.relatedEventIds.any(relatedEventIds.contains)).toList();
  }
}

class PersonRecord {
  PersonRecord({required this.id, required this.primaryName, required this.aliases, required this.roles, required this.tribes, required this.keyReferences, required this.confidence});

  final String id;
  final String primaryName;
  final List<String> aliases;
  final List<String> roles;
  final List<String> tribes;
  final List<String> keyReferences;
  final String confidence;

  factory PersonRecord.fromJson(Map<String, Object?> json) => PersonRecord(id: json.string('id'), primaryName: json.string('primaryName'), aliases: json.strings('aliases'), roles: json.strings('roles'), tribes: json.strings('tribes'), keyReferences: json.strings('keyReferences'), confidence: json.string('confidence'));
}

class RelationshipRecord {
  RelationshipRecord({required this.id, required this.type, required this.fromPersonId, required this.toPersonId, required this.certainty});

  final String id;
  final String type;
  final String fromPersonId;
  final String toPersonId;
  final String certainty;

  factory RelationshipRecord.fromJson(Map<String, Object?> json) => RelationshipRecord(id: json.string('id'), type: json.string('type'), fromPersonId: json.string('fromPersonId'), toPersonId: json.string('toPersonId'), certainty: json.string('certainty'));
}

class EventRecord {
  EventRecord({required this.id, required this.title, required this.kind, required this.date, required this.personIds});

  final String id;
  final String title;
  final String kind;
  final DateClaim date;
  final List<String> personIds;

  factory EventRecord.fromJson(Map<String, Object?> json) => EventRecord(id: json.string('id'), title: json.string('title'), kind: json.string('kind'), date: DateClaim.fromJson(json.object('date')), personIds: json.strings('personIds'));
}

class AgeRecord {
  AgeRecord({required this.id, required this.title, required this.date, required this.personIds});

  final String id;
  final String title;
  final DateClaim date;
  final List<String> personIds;

  factory AgeRecord.fromJson(Map<String, Object?> json) => AgeRecord(id: json.string('id'), title: json.string('title'), date: DateClaim.fromJson(json.object('date')), personIds: json.strings('personIds'));
}

class ProphecyRecord {
  ProphecyRecord({required this.id, required this.title, required this.fulfillmentStatus, required this.certainty, required this.relatedEventIds, required this.relatedAgeIds});

  final String id;
  final String title;
  final String fulfillmentStatus;
  final String certainty;
  final List<String> relatedEventIds;
  final List<String> relatedAgeIds;

  factory ProphecyRecord.fromJson(Map<String, Object?> json) => ProphecyRecord(id: json.string('id'), title: json.string('title'), fulfillmentStatus: json.string('fulfillmentStatus'), certainty: json.string('certainty'), relatedEventIds: json.strings('relatedEventIds'), relatedAgeIds: json.strings('relatedAgeIds'));
}

class DateClaim {
  DateClaim({required this.kind, required this.label});

  final String kind;
  final String label;

  factory DateClaim.fromJson(Map<String, Object?> json) => DateClaim(kind: json.string('kind'), label: json.string('label'));
}

List<T> records<T>(Object? value, T Function(Map<String, Object?>) fromJson) => (value as List<Object?>).cast<Map<String, Object?>>().map(fromJson).toList();

extension JsonRead on Map<String, Object?> {
  String string(String key) => this[key] as String;

  List<String> strings(String key) => (this[key] as List<Object?>).cast<String>();

  Map<String, Object?> object(String key) => this[key] as Map<String, Object?>;
}
