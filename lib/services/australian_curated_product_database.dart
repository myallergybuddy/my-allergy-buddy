import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'barcode_utils.dart';
import 'encryption_service.dart';

/// Your barcode catalog for products the free APIs do not list.
///
/// Edit `data/myallergybuddy_barcode_database.json`, then run
/// `dart run scripts/sync_barcode_catalog.dart` so the encrypted app file
/// [assetPath] stays in sync. Lookup uses this file before Open Food Facts
/// and USDA. [ensureLoaded] decrypts it into [products].
class AustralianCuratedProductDatabase {
  AustralianCuratedProductDatabase._();

  static const assetPath = 'assets/myallergybuddy_barcode_database.enc';

  /// Mutable map so test helpers can add entries at runtime.
  static final Map<String, Map<String, dynamic>> products = {};

  static bool _loaded = false;

  /// Decrypt the bundled catalog into [products]. Safe to call more than once.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final payload = await rootBundle.loadString(assetPath);
    final plain = EncryptionService.decryptBundledCatalog(payload);
    final decoded = jsonDecode(plain);
    if (decoded is! Map) {
      throw const FormatException('Bundled barcode catalog is not a JSON object');
    }
    products
      ..clear()
      ..addAll(
        decoded.map(
          (key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    _loaded = true;
  }

  @visibleForTesting
  static void resetForTest() {
    _loaded = false;
    products.clear();
  }

  /// Lookup a curated product, including UPC/EAN/GTIN variants.
  static Map<String, dynamic>? lookup(String barcode) {
    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final entry = products[candidate];
      if (entry != null) return Map<String, dynamic>.from(entry);
    }
    return null;
  }

  static int get count => products.length;

  static List<String> get barcodes => products.keys.toList();
}
