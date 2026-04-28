class UserProfile {
  final String uid;
  final String name;
  final String familyCode;
  final String? emergencyContact;
  final bool diabetes;
  final bool bp;
  final bool heart;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.familyCode,
    this.emergencyContact,
    this.diabetes = false,
    this.bp = false,
    this.heart = false,
    this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    String? familyCode,
    String? emergencyContact,
    bool? diabetes,
    bool? bp,
    bool? heart,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        familyCode: familyCode ?? this.familyCode,
        emergencyContact: emergencyContact ?? this.emergencyContact,
        diabetes: diabetes ?? this.diabetes,
        bp: bp ?? this.bp,
        heart: heart ?? this.heart,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'familyCode': familyCode,
        'emergencyContact': emergencyContact,
        'diabetes': diabetes,
        'bp': bp,
        'heart': heart,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) =>
      UserProfile(
        uid: uid,
        name: map['name'] as String? ?? 'User',
        familyCode: map['familyCode'] as String? ?? '',
        emergencyContact: map['emergencyContact'] as String?,
        diabetes: map['diabetes'] as bool? ?? false,
        bp: map['bp'] as bool? ?? false,
        heart: map['heart'] as bool? ?? false,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String)
            : null,
      );
}
