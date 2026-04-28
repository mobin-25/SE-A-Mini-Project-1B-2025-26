class UserModel {
  final String uid;
  final String name;
  final String role; // 'Student' or 'Teacher'
  final String email;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.role,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'APSIT User',
      role: map['role'] as String? ?? 'Student',
      email: map['email'] as String? ?? '',
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'email': email,
        'createdAt': createdAt,
      };

  UserModel copyWith({String? name, String? role}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email,
      createdAt: createdAt,
    );
  }
}
