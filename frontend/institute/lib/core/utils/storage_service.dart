import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  final SharedPreferences prefs;

  StorageService(this.prefs);

  Future<void> saveToken(String token) async {
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<String?> getToken() async {
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await prefs.setString(AppConstants.userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  Future<void> saveRole(String role) async {
    await prefs.setString(AppConstants.roleKey, role);
  }

  Future<String?> getRole() async {
    return prefs.getString(AppConstants.roleKey);
  }

  Future<void> clearAll() async {
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}