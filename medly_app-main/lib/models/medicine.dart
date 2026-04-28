class Medicine {
  final int? id;
  final String name;
  final String composition;
  final String type; // tablet, syrup, capsule
  final String dosageInfo;

  Medicine({
    this.id,
    required this.name,
    required this.composition,
    required this.type,
    required this.dosageInfo,
  });

  Map<String, dynamic> toMap() => {
    'medicine_id': id,
    'name': name,
    'composition': composition,
    'type': type,
    'dosage_info': dosageInfo,
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    id: map['medicine_id'],
    name: map['name'],
    composition: map['composition'],
    type: map['type'],
    dosageInfo: map['dosage_info'],
  );
}