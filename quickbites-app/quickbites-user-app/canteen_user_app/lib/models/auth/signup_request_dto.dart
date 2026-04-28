class SignupRequestDto {
  final String username;
  final String password;
  final String mobileNumber;
  final String role;

  const SignupRequestDto({
    required this.username,
    required this.password,
    required this.mobileNumber,
    required this.role,
  });

  factory SignupRequestDto.fromJson(Map<String, dynamic> json) {
    return SignupRequestDto(
      username: json['username'] as String,
      password: json['password'] as String,
      mobileNumber: json['mobileNumber'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'mobileNumber': mobileNumber,
      'role': role,
    };
  }
}
