import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class AuthService {
  // ✅ Register User
  static Future<bool> registerUser(
    String name,
    String phone,
    String password,
  ) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "phone": phone, "pin": password}),
    );

    return response.statusCode == 200;
  }

  // ✅ Login User
  static Future<bool> loginUser(String phone, String password) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "pin": password}),
    );

    return response.statusCode == 200;
  }
}
