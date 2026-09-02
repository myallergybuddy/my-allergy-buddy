import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_allergy_buddy/services/encryption_service.dart';
import 'package:my_allergy_buddy/services/user_learned_product_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testBarcode = '9415098765432';
  const paddedBarcode = '09415098765432';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    EncryptionService.resetPrivateCatalogKeyForTest();
    UserLearnedProductStore.resetForTest();
  });

  group('EncryptionService private payload', () {
    test('round-trips JSON and is not plaintext', () async {
      const plaintext = '{"barcode":"9415098765432","ingredients":["milk"]}';
      final cipher = await EncryptionService.encryptPrivatePayload(plaintext);

      expect(cipher.startsWith('v1.'), isTrue);
      expect(cipher.contains('milk'), isFalse);
      expect(cipher.contains('9415098765432'), isFalse);

      final decrypted = await EncryptionService.decryptPrivatePayload(cipher);
      expect(decrypted, plaintext);
    });
  });

  group('UserLearnedProductStore', () {
    test('save/get/list/remove by barcode with private_secure source', () async {
      final saved = await UserLearnedProductStore.saveProduct(
        barcode: testBarcode,
        ingredients: ['wheat flour', 'sugar', 'cocoa'],
        name: 'Test Biscuits',
        brand: 'Test Brand',
        learnedFrom: UserLearnedProductStore.learnedFromManual,
      );
      expect(saved, isTrue);

      final product = UserLearnedProductStore.getProduct(testBarcode);
      expect(product, isNotNull);
      expect(product!['source'], UserLearnedProductStore.sourcePrivateSecure);
      expect(product['learnedFrom'], UserLearnedProductStore.learnedFromManual);
      expect(product['ingredients'], ['wheat flour', 'sugar', 'cocoa']);

      final listed = UserLearnedProductStore.listProducts();
      expect(listed, hasLength(1));

      expect(await UserLearnedProductStore.removeProduct(testBarcode), isTrue);
      expect(UserLearnedProductStore.getProduct(testBarcode), isNull);
      expect(UserLearnedProductStore.listProducts(), isEmpty);
    });

    test('looks up barcode padding variants', () async {
      await UserLearnedProductStore.savePhotoIngredients(
        barcode: testBarcode,
        ingredients: ['milk powder'],
        name: 'Milk Powder',
      );

      final viaPad = UserLearnedProductStore.getProduct(paddedBarcode);
      expect(viaPad, isNotNull);
      expect(viaPad!['ingredients'], ['milk powder']);
      expect(viaPad['learnedFrom'], UserLearnedProductStore.learnedFromPhotoOcr);
    });

    test('migrates plaintext SharedPreferences into encrypted storage', () async {
      SharedPreferences.setMockInitialValues({
        'user_learned_products': jsonEncode({
          testBarcode: {
            'barcode': testBarcode,
            'name': 'Legacy OCR Bar',
            'ingredients': ['peanuts', 'salt'],
            'ingredientsSource': 'photo_ocr',
          },
        }),
      });

      await UserLearnedProductStore.initialize();

      final product = UserLearnedProductStore.getProduct(testBarcode);
      expect(product, isNotNull);
      expect(product!['ingredients'], ['peanuts', 'salt']);
      expect(product['source'], UserLearnedProductStore.sourcePrivateSecure);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_learned_products'), isNull);
      final encrypted = prefs.getString('user_learned_products_enc');
      expect(encrypted, isNotNull);
      expect(encrypted, isNotEmpty);
      expect(encrypted!.contains('peanuts'), isFalse);
      expect(encrypted.contains('Legacy OCR Bar'), isFalse);
    });

    test('applyToLookupResult fills a miss from the private catalog', () async {
      await UserLearnedProductStore.saveProduct(
        barcode: testBarcode,
        ingredients: ['almonds'],
        name: 'Almond Mix',
      );

      final result = UserLearnedProductStore.applyToLookupResult(testBarcode, {
        'success': false,
        'message': 'Product not found in any available data source',
        'dataSource': 'None',
      });

      expect(result['success'], isTrue);
      expect(result['dataSource'], UserLearnedProductStore.dataSourceLabel);
      expect(
        (result['product'] as Map)['ingredients'],
        ['almonds'],
      );
    });

    test('applyToLookupResult overlays when open source has no ingredients', () async {
      await UserLearnedProductStore.savePhotoIngredients(
        barcode: testBarcode,
        ingredients: ['cashews', 'salt'],
        name: 'Cashew Pack',
      );

      final result = UserLearnedProductStore.applyToLookupResult(testBarcode, {
        'success': true,
        'dataSource': 'Open Food Facts',
        'product': {
          'barcode': testBarcode,
          'name': 'Cashew Pack',
          'ingredients': <String>[],
        },
      });

      expect((result['product'] as Map)['ingredients'], ['cashews', 'salt']);
      expect((result['product'] as Map)['source'], 'private_secure');
      expect(
        result['dataSource'].toString(),
        contains('Private catalog'),
      );
    });

    test('applyToLookupResult keeps open-source ingredients', () async {
      await UserLearnedProductStore.saveProduct(
        barcode: testBarcode,
        ingredients: ['private only'],
        name: 'Private',
      );

      final result = UserLearnedProductStore.applyToLookupResult(testBarcode, {
        'success': true,
        'dataSource': 'Open Food Facts',
        'product': {
          'barcode': testBarcode,
          'name': 'OFF Product',
          'ingredients': ['water', 'sugar'],
        },
      });

      expect((result['product'] as Map)['ingredients'], ['water', 'sugar']);
      expect(result['dataSource'], 'Open Food Facts');
    });

    test('curated allergen statements win over private overlay', () async {
      const curatedBarcode = '9310155000710';
      final saved = await UserLearnedProductStore.saveProduct(
        barcode: curatedBarcode,
        ingredients: ['should not save'],
        name: 'Shadow Attempt',
      );
      expect(saved, isFalse);

      final result = UserLearnedProductStore.applyToLookupResult(curatedBarcode, {
        'success': true,
        'dataSource': 'Local Database',
        'product': {
          'barcode': curatedBarcode,
          'name': 'La Pasta Carbonara Flavour Pasta and Sauce',
          'ingredients': ['durum wheat semolina'],
        },
      });
      expect(result['dataSource'], 'Local Database');
      expect(
        (result['product'] as Map)['ingredients'],
        ['durum wheat semolina'],
      );
    });

    test('rejects invented or photo-placeholder barcodes', () async {
      expect(
        await UserLearnedProductStore.saveProduct(
          barcode: 'PHOTO_123',
          ingredients: ['milk'],
        ),
        isFalse,
      );
      expect(
        await UserLearnedProductStore.saveProduct(
          barcode: 'not-a-barcode',
          ingredients: ['milk'],
        ),
        isFalse,
      );
    });
  });
}
