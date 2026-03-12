import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../models/auth/auth_models.dart';

class StorageService {
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== Token Management (Secure) =====
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: accessToken);
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  // ===== User Data =====
  Future<void> saveUser(UserInfo user) async {
    await _prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  UserInfo? getUser() {
    final data = _prefs.getString(AppConstants.userKey);
    if (data == null) return null;
    return UserInfo.fromJson(jsonDecode(data));
  }

  Future<void> clearUser() async {
    await _prefs.remove(AppConstants.userKey);
  }

  // ===== Theme =====
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(AppConstants.themeKey, mode);
  }

  String getThemeMode() {
    return _prefs.getString(AppConstants.themeKey) ?? 'light';
  }

  // ===== First Launch =====
  bool get isFirstLaunch => _prefs.getBool(AppConstants.firstLaunchKey) ?? true;

  Future<void> setFirstLaunchDone() async {
    await _prefs.setBool(AppConstants.firstLaunchKey, false);
  }

  // ===== Clear All =====
  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
  }
}
