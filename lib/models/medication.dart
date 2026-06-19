
class Medication {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String? notes;

  Medication({
    required this.id,
    required this.name,
    required this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      expiryDate: DateTime.parse(json['expiryDate']),
      notes: json['notes'],
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    DateTime? expiryDate,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
    );
  }
} 