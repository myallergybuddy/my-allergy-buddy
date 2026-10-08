import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;

/// Editable catalog (not shipped). The app ships only the encrypted asset.
const sourcePath = 'data/myallergybuddy_barcode_database.json';
const assetPath = 'assets/myallergybuddy_barcode_database.enc';

/// Same key as EncryptionService.bundledCatalogKeyBase64.
const bundledCatalogKeyBase64 =
    'm9bod2NA03PyZwfqaqeM+kY1R6MHYW24pgY0rfLJ91I=';

void main(List<String> args) {
  if (args.contains('export')) {
    _export();
  } else {
    _encrypt();
  }
}

void _export() {
  final plain = _decrypt(File(assetPath).readAsStringSync());
  final decoded = jsonDecode(plain);
  if (decoded is! Map) {
    throw StateError('Catalog is not a JSON object');
  }
  File(sourcePath).parent.createSync(recursive: true);
  File(sourcePath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(decoded),
  );
  stdout.writeln('Exported ${decoded.length} products to $sourcePath');
}

void _encrypt() {
  final source = File(sourcePath);
  if (!source.existsSync()) {
    throw StateError('Missing $sourcePath. Run with "export" first.');
  }
  final decoded = jsonDecode(source.readAsStringSync());
  if (decoded is! Map || decoded.isEmpty) {
    throw StateError('$sourcePath must be a non-empty JSON object of barcodes');
  }
  final plain = jsonEncode(decoded);
  final payload = _encryptPlain(plain);
  if (payload.contains('9310155000710')) {
    throw StateError('Encrypted file still contains a plaintext barcode');
  }
  final roundTrip = jsonDecode(_decrypt(payload));
  if (roundTrip is! Map || roundTrip.length != decoded.length) {
    throw StateError('Encrypted catalog did not round-trip');
  }
  File(assetPath).writeAsStringSync(payload);
  stdout.writeln('Encrypted ${decoded.length} products to $assetPath');
}

String _encryptPlain(String plain) {
  final key = encrypt.Key.fromBase64(bundledCatalogKeyBase64);
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final encrypted = encrypter.encrypt(plain, iv: iv);
  return 'v1.${iv.base64}.${encrypted.base64}';
}

String _decrypt(String payload) {
  final parts = payload.split('.');
  if (parts.length != 3 || parts[0] != 'v1') {
    throw const FormatException('Unsupported bundled catalog format');
  }
  final key = encrypt.Key.fromBase64(bundledCatalogKeyBase64);
  final iv = encrypt.IV.fromBase64(parts[1]);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  return encrypter.decrypt64(parts[2], iv: iv);
}
