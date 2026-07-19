import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ages_app/main.dart';

void main() {
  test('loads people and relationships from seed pack json', () {
    final pack = AgesPack.fromJson(
      jsonDecode(_seedJson) as Map<String, Object?>,
    );

    expect(pack.persons.single.primaryName, 'Abraham');
    expect(pack.searchPeople('abram').single.id, 'person.abraham');
    expect(pack.relationshipsFor('person.abraham'), hasLength(1));
    expect(pack.relationships.single.references, ['gen21.3']);
    expect(pack.events.single.references, ['gen12.1-9']);
    expect(pack.searchEvents('call').single.id, 'event.call-of-abram');
    expect(pack.ages.single.referenceRange, ['gen12.1', 'gen50.26']);
    expect(pack.agesForEvent('event.call-of-abram').single.id, 'age.patriarchs');
    expect(pack.prophecies.single.references, ['gen12.1-3']);
    expect(
      pack.propheciesForEvent('event.call-of-abram').single.id,
      'prophecy.abrahamic-blessing',
    );
    expect(pack.personIdForReference('gen12.1-9'), 'person.abraham');
    expect(pack.personIdForReference('gen21.3'), 'person.abraham');
    expect(pack.personIdForReference('gen50.26'), 'person.abraham');
    expect(pack.personIdForReference('gen12.1-3'), 'person.abraham');
  });

  test('builds LightSword reference urls', () {
    expect(
      lightswordUri('gen12.1-9').toString(),
      'https://lightsword.app/?r=gen12.1-9',
    );
  });

  test('reads initial person from Ages urls', () {
    expect(
      initialPersonIdFromUri(
        Uri.parse('https://ages.lightsword.app/?person=person.abraham'),
      ),
      'person.abraham',
    );
    expect(
      initialPersonIdFromUri(
        Uri.parse('https://ages.lightsword.app/person/person.david'),
      ),
      'person.david',
    );
  });

  test('reads initial event from Ages urls', () {
    expect(
      initialEventIdFromUri(
        Uri.parse('https://ages.lightsword.app/?event=event.call-of-abram'),
      ),
      'event.call-of-abram',
    );
    expect(
      initialEventIdFromUri(
        Uri.parse('https://ages.lightsword.app/event/event.call-of-abram'),
      ),
      'event.call-of-abram',
    );
  });

  test('reads initial reference from LightSword-style urls', () {
    expect(
      initialReferenceFromUri(
        Uri.parse('https://ages.lightsword.app/?r=gen12.1-9'),
      ),
      'gen12.1-9',
    );
  });

  test('builds Ages person urls', () {
    expect(
      agesPersonUri('person.abraham').toString(),
      '/person/person.abraham',
    );
  });

  test('builds Ages event urls', () {
    expect(
      agesEventUri('event.call-of-abram').toString(),
      '/event/event.call-of-abram',
    );
  });

  testWidgets('renders explorer shell', (tester) async {
    await tester.pumpWidget(const AgesApp());
    await tester.pumpAndSettle();

    expect(find.text('LIGHTSWORD AGES'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
  });
}

const _seedJson = '''
{
  "persons": [
    {
      "id": "person.abraham",
      "primaryName": "Abraham",
      "aliases": ["Abram"],
      "roles": ["patriarch"],
      "tribes": [],
      "keyReferences": ["gen12.1-9"],
      "confidence": "high"
    }
  ],
  "relationships": [
    {
      "id": "rel.abraham.isaac.parent",
      "type": "parent_child",
      "fromPersonId": "person.abraham",
      "toPersonId": "person.isaac",
      "references": ["gen21.3"],
      "certainty": "explicit"
    }
  ],
  "events": [
    {
      "id": "event.call-of-abram",
      "title": "Call of Abram",
      "kind": "calling",
      "date": {
        "kind": "relative",
        "label": "Patriarchal period"
      },
      "personIds": ["person.abraham"],
      "references": ["gen12.1-9"]
    }
  ],
  "ages": [
    {
      "id": "age.patriarchs",
      "title": "Patriarchs",
      "date": {
        "kind": "relative",
        "label": "Genesis 12-50"
      },
      "referenceRange": ["gen12.1", "gen50.26"],
      "personIds": ["person.abraham"],
      "eventIds": ["event.call-of-abram"]
    }
  ],
  "prophecies": [
    {
      "id": "prophecy.abrahamic-blessing",
      "title": "Nations blessed through Abraham",
      "references": ["gen12.1-3"],
      "relatedEventIds": ["event.call-of-abram"],
      "relatedAgeIds": [],
      "fulfillmentStatus": "partially_fulfilled",
      "certainty": "interpretive"
    }
  ]
}
''';
