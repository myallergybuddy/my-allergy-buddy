import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Emails a missing-product report to the app owner.
///
/// Photos are attached for the owner to review and then add to
/// `myallergybuddy_barcode_database`. This service never writes that catalog
/// and never uploads to Open Food Facts.
class MissingProductReportService {
  static const supportEmail = 'myallergybuddy@gmail.com';

  static String subjectFor(String barcode) {
    final code = barcode.trim();
    if (code.isEmpty) return 'Missing product report';
    return 'Missing product report – $code';
  }

  static String bodyFor({
    required String barcode,
    required String productName,
    required String brand,
    required String note,
    required bool hasFront,
    required bool hasBack,
    required bool hasBarcodePhoto,
    String appVersion = '',
  }) {
    final photos = <String>[];
    if (hasFront) photos.add('front of pack');
    if (hasBack) photos.add('back (ingredients / allergen panel)');
    if (hasBarcodePhoto) photos.add('barcode');

    final buffer = StringBuffer()
      ..writeln('A user reported a product that is missing or incomplete in My Allergy Buddy.')
      ..writeln()
      ..writeln('Barcode: ${_orDash(barcode)}')
      ..writeln('Product name: ${_orDash(productName)}')
      ..writeln('Brand: ${_orDash(brand)}')
      ..writeln('Note: ${_orDash(note)}')
      ..writeln()
      ..writeln(
        photos.isEmpty
            ? 'Photos attached: none'
            : 'Photos attached: ${photos.join(', ')}',
      )
      ..writeln()
      ..writeln(
        'Please review and add this to the secure catalog '
        '(myallergybuddy_barcode_database). Do not upload to Open Food Facts.',
      );

    if (appVersion.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('App version: $appVersion');
    }

    return buffer.toString();
  }

  /// Opens the device email app addressed to [supportEmail] with labeled photo attachments.
  static Future<void> sendReport({
    required String barcode,
    required String productName,
    required String brand,
    required String note,
    File? frontPhoto,
    File? backPhoto,
    File? barcodePhoto,
  }) async {
    String appVersion = '';
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVersion = '${pkg.version} (${pkg.buildNumber})';
    } catch (_) {}

    final attachments = await _labeledAttachments(
      frontPhoto: frontPhoto,
      backPhoto: backPhoto,
      barcodePhoto: barcodePhoto,
    );

    final email = Email(
      recipients: const [supportEmail],
      subject: subjectFor(barcode),
      body: bodyFor(
        barcode: barcode,
        productName: productName,
        brand: brand,
        note: note,
        hasFront: frontPhoto != null,
        hasBack: backPhoto != null,
        hasBarcodePhoto: barcodePhoto != null,
        appVersion: appVersion,
      ),
      attachmentPaths: attachments,
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  static Future<List<String>> _labeledAttachments({
    File? frontPhoto,
    File? backPhoto,
    File? barcodePhoto,
  }) async {
    final paths = <String>[];
    final front = await _copyLabeled(frontPhoto, 'front');
    final back = await _copyLabeled(backPhoto, 'back_ingredients');
    final barcode = await _copyLabeled(barcodePhoto, 'barcode');
    if (front != null) paths.add(front);
    if (back != null) paths.add(back);
    if (barcode != null) paths.add(barcode);
    return paths;
  }

  static Future<String?> _copyLabeled(File? source, String label) async {
    if (source == null) return null;
    try {
      if (!await source.exists()) return null;
      final dir = await getTemporaryDirectory();
      final ext = p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
      final dest = File(
        p.join(dir.path, 'missing_product_${label}_${DateTime.now().millisecondsSinceEpoch}$ext'),
      );
      await source.copy(dest.path);
      return dest.path;
    } catch (e) {
      if (kDebugMode) {
        print('MissingProductReport: Could not copy $label photo: $e');
      }
      return source.path;
    }
  }

  static String _orDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '(not provided)' : trimmed;
  }
}
