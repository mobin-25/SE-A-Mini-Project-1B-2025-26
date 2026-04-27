class LoginResponseDto {
  final String jwt;
  final String? refreshToken;
  final int userId;

  const LoginResponseDto({
    required this.jwt,
    this.refreshToken,
    required this.userId,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      jwt: json['jwt'] as String,
      refreshToken: json['refreshToken'] as String?,
      userId: (json['userId'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jwt': jwt,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'userId': userId,
    };
  }
}
