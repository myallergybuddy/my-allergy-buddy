import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'australian_curated_product_database.dart';
import 'product_database_service.dart';

/// Persistent overlay of pack-photo ingredients, keyed by barcode.
///
/// Photo OCR is stored in SharedPreferences and mirrored into the runtime
/// product database so later barcode scans can fill empty (or missing)
/// ingredient lists. Nothing here invents ingredients.
class UserLearnedProductStore {
  static const _productsKey = 'user_learned_products';
  static const _lastScanKey = 'last_scanned_product';
  static const _linkedPhotosKey = 'user_learned_linked_photos';
  static const Duration associateWindow = Duration(hours: 24);

  static final Map<String, Map<String, dynamic>> _products = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFromPrefs();
    await _discardOverlaysShadowingCurated();
    await backfillUnlinkedPhotoScans();
    _mirrorIntoRuntimeDatabase();
  }

  /// Curated contains/may-contain statements beat photo OCR for that barcode.
  static bool curatedAllergenStatementsWin(String barcode) {
    final curated = AustralianCuratedProductDatabase.products[barcode];
    if (curated == null) return false;
    return _stringList(curated['allergens']).isNotEmpty ||
        _stringList(curated['mayContainItems']).isNotEmpty ||
        _stringList(curated['ingredients']).isNotEmpty;
  }

  static Map<String, dynamic>? getProduct(String barcode) {
    final product = _products[barcode];
    if (product == null) return null;
    return Map<String, dynamic>.from(product);
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
          print('UserLearnedProductStore: Could not parse last scan: $e');
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
  }) async {
    await initialize();
    if (!isRealBarcode(barcode)) return false;

    if (curatedAllergenStatementsWin(barcode)) {
      if (kDebugMode) {
        print(
          'UserLearnedProductStore: Skipping photo OCR overlay; curated allergen statements win for $barcode',
        );
      }
      return false;
    }

    final cleaned = trimNutritionNoise(ingredients);
    if (cleaned.isEmpty) return false;

    final existingRuntime = ProductDatabaseService.getAllProducts()[barcode];
    final existingLearned = _products[barcode];
    final merged = <String, dynamic>{
      if (existingRuntime != null) ...existingRuntime,
      if (existingLearned != null) ...existingLearned,
      'barcode': barcode,
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
      'ingredientsSource': 'photo_ocr',
      'dataSource': 'Photo OCR (saved locally)',
      'learnedFrom': 'photo_ocr',
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

    _products[barcode] = merged;
    ProductDatabaseService.addProduct(barcode, merged);
    await _persist();

    if (sourcePhotoId != null && sourcePhotoId.isNotEmpty) {
      await _markPhotoLinked(sourcePhotoId);
    }

    if (kDebugMode) {
      print(
        'UserLearnedProductStore: Saved ${cleaned.length} photo ingredients for $barcode',
      );
    }
    return true;
  }

  /// Fill empty (or missing) ingredient lists from photo-saved data.
  /// Photo-saved ingredients also win when the remote list is empty.
  static Map<String, dynamic> applyToLookupResult(
    String barcode,
    Map<String, dynamic> result,
  ) {
    if (curatedAllergenStatementsWin(barcode)) return result;

    final learned = _products[barcode];
    if (learned == null) return result;

    final learnedIngredients = _stringList(learned['ingredients']);
    if (learnedIngredients.isEmpty) return result;

    if (result['success'] != true) {
      return {
        'success': true,
        'message': 'Product ingredients saved from a previous photo scan',
        'dataSource': 'Photo OCR (saved locally)',
        'product': Map<String, dynamic>.from(learned),
      };
    }

    final product = Map<String, dynamic>.from(result['product'] as Map? ?? {});
    final existing = _stringList(product['ingredients']);
    if (existing.isNotEmpty) {
      if (product['ingredientsSource'] == 'photo_ocr') {
        return {
          ...result,
          'product': product,
          'dataSource': 'Photo OCR (saved locally)',
        };
      }
      return result;
    }

    product['ingredients'] = learnedIngredients;
    product['ingredientsSource'] = 'photo_ocr';
    final source = result['dataSource']?.toString() ??
        product['dataSource']?.toString() ??
        '';
    product['dataSource'] = source.isEmpty
        ? 'Photo OCR (saved locally)'
        : '$source + Photo OCR';

    return {
      ...result,
      'product': product,
      'dataSource': product['dataSource'],
      'message': 'Product found; ingredients filled from photo scan',
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
    if (_stringList(_products[barcode]?['ingredients']).isNotEmpty) return;

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
        'UserLearnedProductStore: Backfilled photo $photoId onto barcode $barcode',
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
      final raw = prefs.getString(_productsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        if (value is Map) {
          _products[key.toString()] = Map<String, dynamic>.from(value);
        }
      });

      if (kDebugMode) {
        print(
          'UserLearnedProductStore: Loaded ${_products.length} photo-saved products',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserLearnedProductStore: Error loading products: $e');
      }
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_productsKey, jsonEncode(_products));
    } catch (e) {
      if (kDebugMode) {
        print('UserLearnedProductStore: Error saving products: $e');
      }
    }
  }

  static void _mirrorIntoRuntimeDatabase() {
    for (final entry in _products.entries) {
      if (curatedAllergenStatementsWin(entry.key)) continue;
      ProductDatabaseService.addProduct(entry.key, entry.value);
    }
  }

  static Future<void> _discardOverlaysShadowingCurated() async {
    final toRemove =
        _products.keys.where(curatedAllergenStatementsWin).toList();
    if (toRemove.isEmpty) return;

    for (final barcode in toRemove) {
      _products.remove(barcode);
      final curated = AustralianCuratedProductDatabase.products[barcode];
      if (curated != null) {
        ProductDatabaseService.replaceProduct(barcode, curated);
      }
    }
    await _persist();

    if (kDebugMode) {
      print(
        'UserLearnedProductStore: Discarded OCR overlay for curated barcodes: $toRemove',
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
        if (map['barcode']?.toString() == barcode) {
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
}
