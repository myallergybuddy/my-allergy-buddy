import 'package:flutter_test/flutter_test.dart';
import 'package:my_allergy_buddy/services/australian_curated_product_database.dart';
import 'package:my_allergy_buddy/services/australian_food_database_service.dart';
import 'package:my_allergy_buddy/services/html_text_utils.dart';
import 'package:my_allergy_buddy/services/product_database_service.dart';

void main() {
  test('HtmlTextUtils keeps tree nuts after allergen-span entity decoding', () {
    const encoded = '&lt;span class=&quot;allergen&quot;&gt;tree nuts&lt;/span&gt;';
    expect(HtmlTextUtils.strip(encoded), 'tree nuts');
    expect(HtmlTextUtils.forDisplay(encoded), 'tree nuts');
    expect(
      HtmlTextUtils.forDisplayList(['Egg', 'Tree Nuts', 'Peanut', 'Sesame']),
      ['Egg', 'Tree Nuts', 'Peanut', 'Sesame'],
    );
  });

  test('Bizza curated may-contain keeps Tree Nuts on the label list', () {
    final bizza = AustralianCuratedProductDatabase.products['9310072037493']!;
    final collected = ProductDatabaseService.collectMayContainItems(
      ingredients: List<String>.from(bizza['ingredients'] as List),
      product: bizza,
    );
    final displayed = HtmlTextUtils.forDisplayList(collected);

    expect(displayed, contains('Tree Nuts'));
    expect(displayed, containsAll(['Egg', 'Peanut', 'Sesame']));
  });

  test('en:nuts and plain nuts labels become Tree Nuts', () {
    final items = ProductDatabaseService.collectMayContainItems(
      ingredients: const [],
      product: {
        'traces_tags': ['en:nuts', 'en:peanuts'],
        'mayContainItems': ['nuts'],
      },
    );
    expect(items, contains('Tree Nuts'));
    expect(items.where((item) => item.toLowerCase() == 'nuts'), isEmpty);
  });

  test('may be present listing detects Tree Nuts without treating peanuts as nuts', () {
    const warning = 'Egg, peanuts, sesame and tree nuts may be present';
    final detected = ProductDatabaseService.analyzeAllergens(
      [warning],
      [
        {'name': 'Tree Nuts', 'severity': 'high'},
        {'name': 'Peanuts', 'severity': 'high'},
        {'name': 'Egg', 'severity': 'high'},
        {'name': 'Sesame', 'severity': 'high'},
      ],
    );
    final names = detected.map((item) => item['name']).toSet();
    expect(names, contains('Tree Nuts'));
    expect(names, contains('Peanuts'));

    final peanutOnly = AustralianFoodDatabaseService.detectCrossContaminationWarnings(
      ['May contain peanuts'],
    ).map((item) => item['allergen']).toSet();
    expect(peanutOnly, contains('Peanuts'));
    expect(peanutOnly, isNot(contains('Tree Nuts')));

    final bizzaStyle = AustralianFoodDatabaseService.detectCrossContaminationWarnings(
      [warning],
    ).map((item) => item['allergen']).toSet();
    expect(bizzaStyle, contains('Tree Nuts'));
    expect(bizzaStyle, contains('Peanuts'));
    expect(bizzaStyle, contains('Egg'));
    expect(bizzaStyle, contains('Sesame'));
  });

  test('Continental minestrone 9300667015029 lists Tree Nuts in may contain', () {
    final soup = AustralianCuratedProductDatabase.lookup('9300667015029')!;
    expect(soup['name'], contains('Minestrone'));
    expect(soup['brand'], 'Continental');

    final collected = ProductDatabaseService.collectMayContainItems(
      ingredients: List<String>.from(soup['ingredients'] as List),
      product: soup,
    );
    expect(HtmlTextUtils.forDisplayList(collected), contains('Tree Nuts'));

    final padded = AustralianCuratedProductDatabase.lookup('09300667015029');
    expect(padded, isNotNull);
    expect(padded!['name'], soup['name']);
  });

  test('Tree Nuts group matches any nut; individual nut matches only that nut plus tree-nut traces', () {
    final treeNutsUser = [
      {'name': 'Tree Nuts', 'severity': 'high'},
    ];
    final almondUser = [
      {'name': 'Almond', 'severity': 'high'},
    ];

    final almondInRecipe = ProductDatabaseService.analyzeAllergens(
      const ['wheat flour', 'almond meal', 'sugar'],
      treeNutsUser,
    ).map((item) => item['name']).toSet();
    expect(almondInRecipe, contains('Tree Nuts'));

    final walnutNotAlmond = ProductDatabaseService.analyzeAllergens(
      const ['wheat flour', 'walnuts', 'sugar'],
      almondUser,
    );
    expect(walnutNotAlmond, isEmpty);

    final almondOwnNut = ProductDatabaseService.analyzeAllergens(
      const ['wheat flour', 'almonds', 'sugar'],
      almondUser,
    ).map((item) => item['name']).toSet();
    expect(almondOwnNut, contains('Almond'));

    final mayContainTreeNuts = ProductDatabaseService.analyzeAllergens(
      const ['may contain tree nuts'],
      almondUser,
    ).map((item) => item['name']).toSet();
    expect(mayContainTreeNuts, contains('Almond'));

    final enNutsTraces = ProductDatabaseService.collectMayContainItems(
      ingredients: const [],
      product: {
        'traces_tags': ['en:nuts'],
      },
    );
    expect(enNutsTraces, contains('Tree Nuts'));

    final groupHitsTraces = ProductDatabaseService.analyzeAllergens(
      const ['may contain nuts'],
      treeNutsUser,
    ).map((item) => item['name']).toSet();
    expect(groupHitsTraces, contains('Tree Nuts'));
  });
}
