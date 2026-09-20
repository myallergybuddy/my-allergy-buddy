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

  test('body lists attached photos and asks for a secure-database review', () {
    final body = MissingProductReportService.bodyFor(
      barcode: '9300652801234',
      productName: 'Test biscuits',
      brand: 'Test brand',
      note: 'Could not find this in the app',
      hasFront: true,
      hasBack: true,
      hasBarcodePhoto: false,
    );

    expect(body, contains('Barcode: 9300652801234'));
    expect(body, contains('Photos attached: front of pack, back (ingredients / allergen panel)'));
    expect(body, contains('Please review this product and add to secure database.'));
    expect(body, isNot(contains('App version:')));
  });
}
