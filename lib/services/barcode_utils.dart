/// Shared GTIN / UPC / EAN helpers for product barcode lookup.
class BarcodeUtils {
  BarcodeUtils._();

  /// Known pack/label variants that differ by a single check digit or prefix.
  static const Map<String, List<String>> knownAliases = {
    '931007201332': ['9310072013312'],
    '9310072013312': ['931007201332'],
    '9310072037496': ['9310072037493'],
    '9310072037493': ['9310072037496'],
  };

  /// Digits-only form of a scanned or stored barcode.
  static String digitsOnly(String barcode) =>
      barcode.replaceAll(RegExp(r'[^0-9]'), '');

  /// Lookup candidates to try against APIs and local maps.
  ///
  /// Includes UPC-A / EAN-13 / GTIN-14 padding variants plus a small set of
  /// known Australian pack aliases.
  static List<String> lookupCandidates(String barcode) {
    final original = barcode.trim();
    final digits = digitsOnly(original);
    final candidates = <String>{};

    if (original.isNotEmpty) candidates.add(original);
    if (digits.isNotEmpty) {
      candidates.add(digits);
      candidates.addAll(_lengthVariants(digits));
    }

    for (final value in List<String>.from(candidates)) {
      final aliases = knownAliases[value];
      if (aliases != null) candidates.addAll(aliases);
    }

    return candidates.toList();
  }

  /// True when two barcodes refer to the same GTIN after normalization.
  static bool matches(String? stored, String scanned) {
    if (stored == null || stored.trim().isEmpty) return false;
    final storedCandidates = lookupCandidates(stored).toSet();
    for (final candidate in lookupCandidates(scanned)) {
      if (storedCandidates.contains(candidate)) return true;
    }
    return false;
  }

  static Iterable<String> _lengthVariants(String digits) {
    final variants = <String>{digits};

    var stripped = digits;
    while (stripped.startsWith('0') && stripped.length > 8) {
      stripped = stripped.substring(1);
      variants.add(stripped);
    }

    for (final length in const [12, 13, 14]) {
      if (digits.length <= length) {
        variants.add(digits.padLeft(length, '0'));
      }
      if (stripped.length <= length) {
        variants.add(stripped.padLeft(length, '0'));
      }
    }

    if (digits.length == 14) {
      variants.add(digits.substring(1));
      variants.add(digits.substring(2));
    }
    if (digits.length == 13 && digits.startsWith('0')) {
      variants.add(digits.substring(1));
    }

    return variants;
  }
}
