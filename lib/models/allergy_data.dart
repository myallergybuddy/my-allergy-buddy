enum AllergySeverity {
  mild,
  moderate,
  severe
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
    'relationship': relationship,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    relationship: json['relationship'],
  );
}

class ScanHistoryItem {
  final String productName;
  final List<String> ingredients;
  final DateTime scanDate;
  final List<String> detectedAllergens;

  ScanHistoryItem({
    required this.productName,
    required this.ingredients,
    required this.scanDate,
    required this.detectedAllergens,
  });

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'ingredients': ingredients,
    'scanDate': scanDate.toIso8601String(),
    'detectedAllergens': detectedAllergens,
  };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) => ScanHistoryItem(
    productName: json['productName'],
    ingredients: List<String>.from(json['ingredients']),
    scanDate: DateTime.parse(json['scanDate']),
    detectedAllergens: List<String>.from(json['detectedAllergens']),
  );
} 