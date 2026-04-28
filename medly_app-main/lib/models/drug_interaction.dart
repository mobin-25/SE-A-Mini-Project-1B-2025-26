class DrugInteraction {
  final int? id;
  final int medicine1Id;
  final int medicine2Id;
  final String severity; // low, medium, high
  final String description;

  DrugInteraction({
    this.id,
    required this.medicine1Id,
    required this.medicine2Id,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'medicine1_id': medicine1Id,
    'medicine2_id': medicine2Id,
    'severity': severity,
    'description': description,
  };

  factory DrugInteraction.fromMap(Map<String, dynamic> map) => DrugInteraction(
    id: map['id'],
    medicine1Id: map['medicine1_id'],
    medicine2Id: map['medicine2_id'],
    severity: map['severity'],
    description: map['description'],
  );
}