import 'dart:convert';

class ScanResult {
  final String barcode;
  final String productName;
  final String brand;
  final List<String> ingredients;
  final List<Map<String, dynamic>> detectedAllergens;
  final DateTime scanDate;
  final bool isSafe;
  final String? image;

  ScanResult({
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.ingredients,
    required this.detectedAllergens,
    required this.scanDate,
    required this.isSafe,
    this.image,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      barcode: json['barcode'],
      productName: json['productName'],
      brand: json['brand'],
      ingredients: List<String>.from(json['ingredients']),
      detectedAllergens: List<Map<String, dynamic>>.from(json['detectedAllergens']),
      scanDate: DateTime.parse(json['scanDate']),
      isSafe: json['isSafe'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'ingredients': ingredients,
      'detectedAllergens': detectedAllergens,
      'scanDate': scanDate.toIso8601String(),
      'isSafe': isSafe,
      'image': image,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory ScanResult.fromJsonString(String jsonString) {
    return ScanResult.fromJson(jsonDecode(jsonString));
  }
} 