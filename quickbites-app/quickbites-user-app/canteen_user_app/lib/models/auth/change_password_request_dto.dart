class ChangePasswordRequestDto {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequestDto({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}
