class SignupResponseDto {
  final int id;
  final String username;

  const SignupResponseDto({
    required this.id,
    required this.username,
  });

  factory SignupResponseDto.fromJson(Map<String, dynamic> json) {
    return SignupResponseDto(
      id: json['id'] as int,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }
}
