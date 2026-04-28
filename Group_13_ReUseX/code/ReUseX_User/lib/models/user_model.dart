class UserModel {
  String name;
  String email;
  String phone;
  String? imagePath;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    this.imagePath,
  });
}