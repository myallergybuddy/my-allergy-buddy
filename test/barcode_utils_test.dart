import 'package:flutter_test/flutter_test.dart';
import 'package:my_allergy_buddy/services/barcode_utils.dart';
import 'package:my_allergy_buddy/services/open_food_facts_service.dart';

void main() {
  group('BarcodeUtils', () {
    test('keeps original EAN-13 and adds GTIN-14 padding', () {
      final candidates = BarcodeUtils.lookupCandidates('9310155000710');
      expect(candidates, contains('9310155000710'));
      expect(candidates, contains('09310155000710'));
    });

    test('matches UPC-A with EAN-13 leading zero', () {
      expect(BarcodeUtils.matches('012345678905', '12345678905'), isTrue);
      expect(BarcodeUtils.matches('123456789012', '0123456789012'), isTrue);
    });

    test('includes known Australian pack aliases', () {
      expect(
        BarcodeUtils.lookupCandidates('931007201332'),
        contains('9310072013312'),
      );
    });

    test('ignores non-digit formatting', () {
      expect(
        BarcodeUtils.matches('9310-155-000-710', '9310155000710'),
        isTrue,
      );
    });
  });

  group('OpenFoodFactsService helpers', () {
    test('maps common allergen names to taxonomy tags', () {
      expect(OpenFoodFactsService.allergenToOffTag('milk'), 'en:milk');
      expect(OpenFoodFactsService.allergenToOffTag('Soy'), 'en:soybeans');
      expect(OpenFoodFactsService.allergenToOffTag('tree nuts'), 'en:nuts');
      expect(OpenFoodFactsService.allergenToOffTag('unknown'), isNull);
    });

    test('builds absolute image URLs without double-prefixing', () {
      expect(
        OpenFoodFactsService.absoluteImageUrl(
          'https://images.openfoodfacts.org/images/products/1.jpg',
        ),
        'https://images.openfoodfacts.org/images/products/1.jpg',
      );
      expect(
        OpenFoodFactsService.absoluteImageUrl('//images.openfoodfacts.org/a.jpg'),
        'https://images.openfoodfacts.org/a.jpg',
      );
      expect(
        OpenFoodFactsService.absoluteImageUrl('/images/products/1.jpg'),
        'https://images.openfoodfacts.org/images/products/1.jpg',
      );
    });
  });
}
