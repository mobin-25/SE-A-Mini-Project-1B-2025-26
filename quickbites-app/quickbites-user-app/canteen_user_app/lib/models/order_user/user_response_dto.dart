class UserResponseDto {
  final String username;
  final String mobileNumber;
  final String email;
  final String? profilePictureUrl;

  const UserResponseDto({
    required this.username,
    required this.mobileNumber,
    required this.email,
    this.profilePictureUrl,
  });

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      username: json['username'] as String,
      mobileNumber: json['mobileNumber'] as String,
      email: json['email'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'mobileNumber': mobileNumber,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
