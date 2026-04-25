import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class TokenStorageService {
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveAuth({
    required String jwt,
    String? refreshToken,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.jwtStorageKey, jwt);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setInt(ApiConfig.userIdStorageKey, userId);
  }

  Future<String?> getJwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.jwtStorageKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(ApiConfig.userIdStorageKey);
  }

  Future<void> saveJwt(String jwt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.jwtStorageKey, jwt);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.jwtStorageKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(ApiConfig.userIdStorageKey);
  }
}
