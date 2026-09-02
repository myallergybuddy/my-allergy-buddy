import 'package:flutter_test/flutter_test.dart';
import 'package:my_allergy_buddy/tree_nuts_grouping.dart';

void main() {
  test('normalizeSelection keeps parent plus remaining children for a subset', () {
    final selected = {
      'Tree Nuts': 'High',
      'Almond': 'High',
      'Hazelnut': 'High',
      'Pecan': 'High',
      'Milk': 'Medium',
    };

    final saved = TreeNutsGrouping.normalizeSelection(selected);
    expect(saved.containsKey('Tree Nuts'), isTrue);
    expect(saved.keys, containsAll(['Almond', 'Hazelnut', 'Pecan', 'Milk']));
    expect(saved.containsKey('Cashew'), isFalse);
    expect(saved.containsKey('Walnut'), isFalse);
  });

  test('normalizeSelection collapses a complete group to Tree Nuts only', () {
    final selected = {
      'Tree Nuts': 'Medium',
      for (final child in TreeNutsGrouping.children) child: 'Medium',
    };

    final saved = TreeNutsGrouping.normalizeSelection(selected);
    expect(saved.keys, ['Tree Nuts']);
  });

  test('Profile shows Tree Nuts plus remaining selected children', () {
    final allergies = [
      {'name': 'Tree Nuts', 'severity': 'High'},
      {'name': 'Almond', 'severity': 'High'},
      {'name': 'Hazelnut', 'severity': 'High'},
      {'name': 'Milk', 'severity': 'Medium'},
    ];

    final profile = TreeNutsGrouping.forProfile(allergies)
        .map((item) => item['name'])
        .toList();
    expect(profile, ['Tree Nuts', 'Almond', 'Hazelnut', 'Milk']);
  });

  test('My Allergies shows Tree Nuts plus remaining selected children', () {
    final allergies = [
      {'name': 'Milk', 'severity': 'Medium'},
      {'name': 'Hazelnut', 'severity': 'High'},
      {'name': 'Tree Nuts', 'severity': 'High'},
      {'name': 'Almond', 'severity': 'High'},
    ];

    final mine = TreeNutsGrouping.forMyAllergies(allergies)
        .map((item) => item['name'])
        .toList();
    expect(mine, ['Tree Nuts', 'Almond', 'Hazelnut', 'Milk']);
  });

  test('Profile and My Allergies use the same Tree Nuts display list', () {
    final allergies = [
      {'name': 'Milk', 'severity': 'Medium'},
      {'name': 'Hazelnut', 'severity': 'High'},
      {'name': 'Tree Nuts', 'severity': 'High'},
      {'name': 'Almond', 'severity': 'High'},
    ];

    expect(
      TreeNutsGrouping.forProfile(allergies).map((item) => item['name']),
      TreeNutsGrouping.forMyAllergies(allergies).map((item) => item['name']),
    );
  });

  test('Profile and My Allergies stay exploded when only individual nuts are saved', () {
    final allergies = [
      {'name': 'Almond', 'severity': 'High'},
      {'name': 'Cashew', 'severity': 'High'},
    ];

    expect(
      TreeNutsGrouping.forProfile(allergies).map((item) => item['name']),
      ['Almond', 'Cashew'],
    );
    expect(
      TreeNutsGrouping.forMyAllergies(allergies).map((item) => item['name']),
      ['Almond', 'Cashew'],
    );
  });
}
