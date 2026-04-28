class Disease {
  final int? id;
  final String name;
  final String description;

  Disease({this.id, required this.name, required this.description});

  Map<String, dynamic> toMap() => {
    'disease_id': id,
    'name': name,
    'description': description,
  };

  factory Disease.fromMap(Map<String, dynamic> map) => Disease(
    id: map['disease_id'],
    name: map['name'],
    description: map['description'],
  );
}