import 'package:flutter_test/flutter_test.dart';
import 'package:my_allergy_buddy/services/missing_product_report_service.dart';

void main() {
  test('subject includes barcode', () {
    expect(
      MissingProductReportService.subjectFor('9300652801234'),
      'Missing product report – 9300652801234',
    );
  });

  test('subject without barcode is generic', () {
    expect(MissingProductReportService.subjectFor('  '), 'Missing product report');
  });

  test('body lists attached photos and does not mention Open Food Facts upload', () {
    final body = MissingProductReportService.bodyFor(
      barcode: '9300652801234',
      productName: 'Test biscuits',
      brand: 'Test brand',
      note: 'Could not find this in the app',
      hasFront: true,
      hasBack: true,
      hasBarcodePhoto: false,
      appVersion: '1.0.0 (1)',
    );

    expect(body, contains('Barcode: 9300652801234'));
    expect(body, contains('Photos attached: front of pack, back (ingredients / allergen panel)'));
    expect(body, contains('myallergybuddy_barcode_database'));
    expect(body, contains('Do not upload to Open Food Facts'));
    expect(body, contains('App version: 1.0.0 (1)'));
  });
}
