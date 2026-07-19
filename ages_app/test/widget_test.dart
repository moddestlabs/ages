import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ages_app/main.dart';

void main() {
  test('loads people and relationships from seed pack json', () {
    final pack = AgesPack.fromJson(jsonDecode(_seedJson) as Map<String, Object?>);

    expect(pack.persons.single.primaryName, 'Abraham');
    expect(pack.searchPeople('abram').single.id, 'person.abraham');
    expect(pack.relationshipsFor('person.abraham'), hasLength(1));
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
      "certainty": "explicit"
    }
  ],
  "events": [],
  "ages": [],
  "prophecies": []
}
''';
