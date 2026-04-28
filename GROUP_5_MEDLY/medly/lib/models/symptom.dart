class Symptom {
  final int? id;
  final String name;

  Symptom({this.id, required this.name});

  Map<String, dynamic> toMap() => {'symptom_id': id, 'name': name};

  factory Symptom.fromMap(Map<String, dynamic> map) =>
      Symptom(id: map['symptom_id'], name: map['name']);
}