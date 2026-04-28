import 'dart:convert';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation; // e.g. "Son", "Daughter", "Doctor"

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) => EmergencyContact(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        relation: map['relation'] as String? ?? '',
      );

  String toJson() => json.encode(toMap());

  factory EmergencyContact.fromJson(String source) =>
      EmergencyContact.fromMap(json.decode(source) as Map<String, dynamic>);
}
