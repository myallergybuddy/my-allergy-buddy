import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'australian_curated_product_database.dart';
import 'barcode_utils.dart';
import 'encryption_service.dart';
import 'product_database_service.dart';

/// Encrypted on-device catalog (`myallergybuddy_barcode_database`) of
/// pack-accurate products that open barcode databases do not have (or have
/// with no usable ingredients).
///
/// Photo OCR and manual adds stay on this device: they are never uploaded to
/// Open Food Facts or any other public API. Ingredients are stored encrypted
/// at rest (AES-256-CBC); the key lives in FlutterSecureStorage.
class UserLearnedProductStore {
  static const databaseName = 'myallergybuddy_barcode_database';
  static const _encryptedProductsKey = databaseName;
  static const _legacyEncryptedProductsKey = 'user_learned_products_enc';
  static const _legacyProductsKey = 'user_learned_products';
  static const _lastScanKey = 'last_scanned_product';
  static const _linkedPhotosKey = 'user_learned_linked_photos';
  static const Duration associateWindow = Duration(hours: 24);

  static const sourcePrivateSecure = databaseName;
  static const sourceLegacyPrivateSecure = 'private_secure';
  static const learnedFromPhotoOcr = 'photo_ocr';
  static const learnedFromManual = 'manual';
  static const dataSourceLabel = databaseName;

  static final Map<String, Map<String, dynamic>> _products = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFromPrefs();
    await _discardOverlaysShadowingCurated();
    await backfillUnlinkedPhotoScans();
  }

  /// Curated contains/may-contain statements beat photo OCR for that barcode.
  static bool curatedAllergenStatementsWin(String barcode) {
    final curated = AustralianCuratedProductDatabase.lookup(barcode);
    if (curated == null) return false;
    return _stringList(curated['allergens']).isNotEmpty ||
        _stringList(curated['mayContainItems']).isNotEmpty ||
        _stringList(curated['ingredients']).isNotEmpty;
  }

  static bool isPrivateCatalogEntry(Map<String, dynamic>? product) {
    if (product == null) return false;
    final source = product['source']?.toString();
    return source == sourcePrivateSecure ||
        source == sourceLegacyPrivateSecure;
  }

  static Map<String, dynamic>? getProduct(String barcode) {
    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final product = _products[candidate];
      if (product != null) {
        return Map<String, dynamic>.from(product);
      }
    }
    return null;
  }

  /// Copies of every privately stored product.
  static List<Map<String, dynamic>> listProducts() {
    return _products.values
        .map((product) => Map<String, dynamic>.from(product))
        .toList();
  }

  static bool isRealBarcode(String? barcode) {
    if (barcode == null) return false;
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('PHOTO_')) return false;
    if (trimmed.toLowerCase().startsWith('no barcode')) return false;
    return RegExp(r'^\d{8,14}$').hasMatch(trimmed);
  }

  /// Remember the most recent barcode scan so a following photo can be linked.
  static Future<void> rememberLastScan({
    required String barcode,
    String? name,
    String? brand,
    String? image,
  }) async {
    if (!isRealBarcode(barcode)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastScanKey,
      jsonEncode({
        'barcode': barcode.trim(),
        'name': name ?? '',
        'brand': brand ?? '',
        'image': image ?? '',
        'scannedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  static Future<Map<String, dynamic>?> getLastScan({
    Duration maxAge = associateWindow,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastScanKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final barcode = map['barcode']?.toString() ?? '';
        if (isRealBarcode(barcode) && _isRecent(map['scannedAt']?.toString(), maxAge)) {
          return map;
        }
      } catch (e) {
        if (kDebugMode) {
          print('myallergybuddy_barcode_database: Could not parse last scan: $e');
        }
      }
    }

    return _lastRealBarcodeFromHistory(prefs, maxAge: maxAge);
  }

  /// Session barcode first, then last scanned barcode from this device.
  static Future<Map<String, dynamic>?> resolveBarcodeForPhoto({
    String? sessionBarcode,
    String? sessionName,
    String? sessionBrand,
    String? sessionImage,
  }) async {
    if (isRealBarcode(sessionBarcode)) {
      return {
        'barcode': sessionBarcode!.trim(),
        'name': sessionName ?? '',
        'brand': sessionBrand ?? '',
        'image': sessionImage ?? '',
      };
    }
    return getLastScan();
  }

  /// Persist OCR ingredients for [barcode]. Empty lists are ignored.
  static Future<bool> savePhotoIngredients({
    required String barcode,
    required List<String> ingredients,
    String? name,
    String? brand,
    String? image,
    String? sourcePhotoId,
  }) {
    return saveProduct(
      barcode: barcode,
      ingredients: ingredients,
      name: name,
      brand: brand,
      image: image,
      learnedFrom: learnedFromPhotoOcr,
      sourcePhotoId: sourcePhotoId,
    );
  }

  /// Save a myallergybuddy_barcode_database entry keyed by barcode.
  ///
  /// [learnedFrom] is `photo_ocr` or `manual`. Never invents a barcode.
  /// Never uploads to Open Food Facts or any public API.
  static Future<bool> saveProduct({
    required String barcode,
    required List<String> ingredients,
    String? name,
    String? brand,
    String? image,
    String learnedFrom = learnedFromManual,
    String? sourcePhotoId,
  }) async {
    await initialize();
    if (!isRealBarcode(barcode)) return false;

    if (curatedAllergenStatementsWin(barcode)) {
      if (kDebugMode) {
        print(
          'myallergybuddy_barcode_database: Skipping overlay; curated allergen statements win for $barcode',
        );
      }
      return false;
    }

    final cleaned = trimNutritionNoise(ingredients);
    if (cleaned.isEmpty) return false;

    final storageKey = _storageKeyFor(barcode);
    final existingRuntime = _runtimeProduct(barcode);
    final existingLearned = _products[storageKey] ?? getProduct(barcode);
    final fromPhoto = learnedFrom == learnedFromPhotoOcr;
    final merged = <String, dynamic>{
      if (existingRuntime != null) ...existingRuntime,
      if (existingLearned != null) ...existingLearned,
      'barcode': storageKey,
      'name': _firstNonEmpty([
            name,
            existingLearned?['name']?.toString(),
            existingRuntime?['name']?.toString(),
          ]) ??
          'Unknown Product',
      'brand': _firstNonEmpty([
            brand,
            existingLearned?['brand']?.toString(),
            existingRuntime?['brand']?.toString(),
          ]) ??
          '',
      'ingredients': cleaned,
      'ingredientsSource': fromPhoto ? learnedFromPhotoOcr : learnedFromManual,
      'source': sourcePrivateSecure,
      'dataSource': dataSourceLabel,
      'learnedFrom': fromPhoto ? learnedFromPhotoOcr : learnedFromManual,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (image != null && image.isNotEmpty) {
      merged['image'] = image;
    } else if (existingLearned?['image'] != null) {
      merged['image'] = existingLearned!['image'];
    } else if (existingRuntime?['image'] != null) {
      merged['image'] = existingRuntime!['image'];
    }
    if (sourcePhotoId != null && sourcePhotoId.isNotEmpty) {
      merged['sourcePhotoId'] = sourcePhotoId;
    }

    _products[storageKey] = merged;
    await _persist();

    if (sourcePhotoId != null && sourcePhotoId.isNotEmpty) {
      await _markPhotoLinked(sourcePhotoId);
    }

    if (kDebugMode) {
      print(
        'myallergybuddy_barcode_database: Saved ${cleaned.length} ingredients for $storageKey ($learnedFrom)',
      );
    }
    return true;
  }

  /// Remove a myallergybuddy_barcode_database entry (all stored barcode variants).
  static Future<bool> removeProduct(String barcode) async {
    await initialize();
    final keys = _matchingKeys(barcode);
    if (keys.isEmpty) return false;
    for (final key in keys) {
      _products.remove(key);
    }
    await _persist();
    return true;
  }

  /// Fill empty (or missing) ingredient lists from myallergybuddy_barcode_database.
  /// Open sources that already have usable ingredients keep winning.
  /// Photo-saved / manual ingredients also win when lookup missed entirely.
  static Map<String, dynamic> applyToLookupResult(
    String barcode,
    Map<String, dynamic> result,
  ) {
    if (curatedAllergenStatementsWin(barcode)) return result;

    final learned = getProduct(barcode);
    if (learned == null) return result;

    final learnedIngredients = _stringList(learned['ingredients']);
    if (learnedIngredients.isEmpty) return result;

    if (result['success'] != true) {
      return {
        'success': true,
        'message': 'Product ingredients saved in myallergybuddy_barcode_database',
        'dataSource': dataSourceLabel,
        'product': Map<String, dynamic>.from(learned),
      };
    }

    final product = Map<String, dynamic>.from(result['product'] as Map? ?? {});
    final existing = _stringList(product['ingredients']);
    if (existing.isNotEmpty) {
      if (isPrivateCatalogEntry(product) ||
          product['ingredientsSource'] == learnedFromPhotoOcr) {
        return {
          ...result,
          'product': product,
          'dataSource': dataSourceLabel,
        };
      }
      return result;
    }

    product['ingredients'] = learnedIngredients;
    product['ingredientsSource'] =
        learned['ingredientsSource'] ?? learnedFromPhotoOcr;
    product['source'] = sourcePrivateSecure;
    product['learnedFrom'] = learned['learnedFrom'] ?? learnedFromPhotoOcr;
    final source = result['dataSource']?.toString() ??
        product['dataSource']?.toString() ??
        '';
    product['dataSource'] = source.isEmpty
        ? dataSourceLabel
        : '$source + $dataSourceLabel';

    return {
      ...result,
      'product': product,
      'dataSource': product['dataSource'],
      'message': 'Product found; ingredients filled from myallergybuddy_barcode_database',
    };
  }

  /// Attach unmatched Photo Scan history to the last barcode scan.
  static Future<void> backfillUnlinkedPhotoScans() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getStringList(_linkedPhotosKey) ?? [];
    final photoHistory = prefs.getStringList('scan_history') ?? [];

    final unlinkedPhotos = <Map<String, dynamic>>[];
    for (final json in photoHistory) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(json) as Map);
        final photoId = map['barcode']?.toString() ?? '';
        if (!photoId.startsWith('PHOTO_') || linked.contains(photoId)) {
          continue;
        }
        final ingredients = trimNutritionNoise(_stringList(map['ingredients']));
        if (ingredients.isEmpty) continue;
        unlinkedPhotos.add(map);
      } catch (_) {
        // Skip corrupt history rows.
      }
    }
    if (unlinkedPhotos.isEmpty) return;

    unlinkedPhotos.sort((a, b) {
      final aDate = DateTime.tryParse(a['scanDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['scanDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final lastScan = await getLastScan(maxAge: const Duration(days: 7));
    if (lastScan == null) return;

    final barcode = lastScan['barcode']?.toString() ?? '';
    if (!isRealBarcode(barcode)) return;
    if (curatedAllergenStatementsWin(barcode)) return;
    if (_stringList(getProduct(barcode)?['ingredients']).isNotEmpty) return;

    final photo = unlinkedPhotos.first;
    final photoId = photo['barcode']?.toString() ?? '';
    final ingredients = trimNutritionNoise(_stringList(photo['ingredients']));
    if (ingredients.isEmpty) return;

    final historyMeta = _productMetaFromHistory(prefs, barcode);
    await savePhotoIngredients(
      barcode: barcode,
      ingredients: ingredients,
      name: _firstNonEmpty([
        lastScan['name']?.toString(),
        historyMeta?['name']?.toString(),
        photo['productName']?.toString(),
      ]),
      brand: _firstNonEmpty([
        lastScan['brand']?.toString(),
        historyMeta?['brand']?.toString(),
        photo['brand']?.toString(),
      ]),
      image: _firstNonEmpty([
        lastScan['image']?.toString(),
        historyMeta?['image']?.toString(),
      ]),
      sourcePhotoId: photoId,
    );

    if (kDebugMode) {
      print(
        'myallergybuddy_barcode_database: Backfilled photo $photoId onto barcode $barcode',
      );
    }
  }

  /// Drop nutrition-table OCR that follows the ingredient list.
  static List<String> trimNutritionNoise(List<String> ingredients) {
    final kept = <String>[];
    for (final raw in ingredients) {
      final item = raw.trim();
      if (item.isEmpty) continue;
      if (_looksLikeNutritionSection(item)) break;
      kept.add(item);
    }
    return kept;
  }

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
    _products.clear();
  }

  static bool _looksLikeNutritionSection(String item) {
    final text = item.toLowerCase();
    return text.contains('nutritional information') ||
        text.contains('nutrition information') ||
        text.contains('nutrition facts') ||
        text.startsWith('servings per package') ||
        text.startsWith('avg. quantity') ||
        text.startsWith('avg quantity') ||
        text.contains('per serving') ||
        text.contains('dietary fibre') ||
        text.contains('exporting to the world') ||
        RegExp(r'^\d+(\.\d+)?\s*k\.?j').hasMatch(text);
  }

  static Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var migratedLegacy = false;

      for (final key in [_encryptedProductsKey, _legacyEncryptedProductsKey]) {
        final encrypted = prefs.getString(key);
        if (encrypted == null || encrypted.isEmpty) continue;
        try {
          final decodedJson =
              await EncryptionService.decryptPrivatePayload(encrypted);
          _mergeDecodedProducts(jsonDecode(decodedJson));
          if (key == _legacyEncryptedProductsKey) {
            migratedLegacy = true;
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'myallergybuddy_barcode_database: Could not decrypt catalog ($key): $e',
            );
          }
        }
      }

      final plaintext = prefs.getString(_legacyProductsKey);
      if (plaintext != null && plaintext.isNotEmpty) {
        _mergeDecodedProducts(jsonDecode(plaintext));
        migratedLegacy = true;
      }

      if (migratedLegacy ||
          (_products.isNotEmpty &&
              (prefs.getString(_encryptedProductsKey) == null ||
                  prefs.getString(_encryptedProductsKey)!.isEmpty))) {
        await _persist();
        await prefs.remove(_legacyEncryptedProductsKey);
        await prefs.remove(_legacyProductsKey);
        if (kDebugMode) {
          print(
            'myallergybuddy_barcode_database: Migrated catalog to $databaseName',
          );
        }
      }

      if (kDebugMode) {
        print(
          'myallergybuddy_barcode_database: Loaded ${_products.length} products',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('myallergybuddy_barcode_database: Error loading products: $e');
      }
    }
  }

  static void _mergeDecodedProducts(dynamic decoded) {
    if (decoded is! Map) return;
    decoded.forEach((key, value) {
      if (value is Map) {
        final product = Map<String, dynamic>.from(value);
        product['source'] = sourcePrivateSecure;
        product['learnedFrom'] ??=
            product['ingredientsSource']?.toString() == learnedFromPhotoOcr
                ? learnedFromPhotoOcr
                : learnedFromManual;
        product['dataSource'] = dataSourceLabel;
        _products[key.toString()] = product;
      }
    });
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_products);
      final encrypted = await EncryptionService.encryptPrivatePayload(payload);
      await prefs.setString(_encryptedProductsKey, encrypted);
      await prefs.remove(_legacyProductsKey);
      await prefs.remove(_legacyEncryptedProductsKey);
    } catch (e) {
      if (kDebugMode) {
        print('myallergybuddy_barcode_database: Error saving encrypted products: $e');
      }
    }
  }

  static Future<void> _discardOverlaysShadowingCurated() async {
    final toRemove =
        _products.keys.where(curatedAllergenStatementsWin).toList();
    if (toRemove.isEmpty) return;

    for (final barcode in toRemove) {
      _products.remove(barcode);
      final curated = AustralianCuratedProductDatabase.lookup(barcode);
      if (curated != null) {
        ProductDatabaseService.replaceProduct(barcode, curated);
      }
    }
    await _persist();

    if (kDebugMode) {
      print(
        'myallergybuddy_barcode_database: Discarded OCR overlay for curated barcodes: $toRemove',
      );
    }
  }

  static Future<void> _markPhotoLinked(String photoId) async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getStringList(_linkedPhotosKey) ?? [];
    if (!linked.contains(photoId)) {
      linked.add(photoId);
      await prefs.setStringList(_linkedPhotosKey, linked);
    }
  }

  static Future<Map<String, dynamic>?> _lastRealBarcodeFromHistory(
    SharedPreferences prefs, {
    required Duration maxAge,
  }) async {
    final sources = [
      prefs.getStringList('enhanced_scan_history') ?? const <String>[],
      prefs.getStringList('scan_history') ?? const <String>[],
    ];

    Map<String, dynamic>? newest;
    DateTime? newestDate;
    for (final list in sources) {
      for (final json in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(json) as Map);
          final barcode = map['barcode']?.toString() ?? '';
          if (!isRealBarcode(barcode)) continue;
          final scannedAt = DateTime.tryParse(map['scanDate']?.toString() ?? '');
          if (scannedAt == null || !_isRecent(scannedAt.toIso8601String(), maxAge)) {
            continue;
          }
          if (newestDate == null || scannedAt.isAfter(newestDate)) {
            newestDate = scannedAt;
            newest = {
              'barcode': barcode,
              'name': map['productName']?.toString() ?? '',
              'brand': map['brand']?.toString() ?? '',
              'image': map['image']?.toString() ?? '',
              'scannedAt': scannedAt.toIso8601String(),
            };
          }
        } catch (_) {}
      }
    }
    return newest;
  }

  static Map<String, dynamic>? _productMetaFromHistory(
    SharedPreferences prefs,
    String barcode,
  ) {
    final history = prefs.getStringList('enhanced_scan_history') ?? [];
    for (final json in history.reversed) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(json) as Map);
        if (BarcodeUtils.matches(map['barcode']?.toString(), barcode)) {
          return map;
        }
      } catch (_) {}
    }
    return null;
  }

  static bool _isRecent(String? iso, Duration maxAge) {
    final parsed = DateTime.tryParse(iso ?? '');
    if (parsed == null) return false;
    return DateTime.now().difference(parsed) <= maxAge;
  }

  static List<String> _stringList(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        final trimmed = value.trim();
        if (trimmed.toLowerCase() == 'unknown product') continue;
        if (trimmed.toLowerCase() == 'unknown brand') continue;
        if (trimmed.toLowerCase() == 'product from photo') continue;
        return trimmed;
      }
    }
    return null;
  }

  static String _storageKeyFor(String barcode) {
    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      if (_products.containsKey(candidate)) return candidate;
    }
    final digits = BarcodeUtils.digitsOnly(barcode);
    return digits.isNotEmpty ? digits : barcode.trim();
  }

  static List<String> _matchingKeys(String barcode) {
    return _products.keys
        .where((key) => BarcodeUtils.matches(key, barcode))
        .toList();
  }

  static Map<String, dynamic>? _runtimeProduct(String barcode) {
    final all = ProductDatabaseService.getAllProducts();
    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final product = all[candidate];
      if (product != null && !isPrivateCatalogEntry(product)) {
        return product;
      }
    }
    return null;
  }
}
