import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userRole = 'user_role';
  static const String isDarkMode = 'is_dark_mode';
  static const String lastSyncTime = 'last_sync_time';
  static const String notificationsEnabled = 'notifications_enabled';
}

class SharedPrefsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth related
  static Future<void> saveAuthToken(String token) async {
    await _prefs.setString(SharedPrefsKeys.authToken, token);
  }

  static String? getAuthToken() {
    return _prefs.getString(SharedPrefsKeys.authToken);
  }

  static Future<void> saveUserId(String id) async {
    await _prefs.setString(SharedPrefsKeys.userId, id);
  }

  static String? getUserId() {
    return _prefs.getString(SharedPrefsKeys.userId);
  }

  static Future<void> saveUserEmail(String email) async {
    await _prefs.setString(SharedPrefsKeys.userEmail, email);
  }

  static String? getUserEmail() {
    return _prefs.getString(SharedPrefsKeys.userEmail);
  }

  static Future<void> saveUserName(String name) async {
    await _prefs.setString(SharedPrefsKeys.userName, name);
  }

  static String? getUserName() {
    return _prefs.getString(SharedPrefsKeys.userName);
  }

  static Future<void> saveUserRole(String role) async {
    await _prefs.setString(SharedPrefsKeys.userRole, role);
  }

  static String? getUserRole() {
    return _prefs.getString(SharedPrefsKeys.userRole);
  }

  // App settings
  static Future<void> setIsDarkMode(bool value) async {
    await _prefs.setBool(SharedPrefsKeys.isDarkMode, value);
  }

  static bool getIsDarkMode() {
    return _prefs.getBool(SharedPrefsKeys.isDarkMode) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(SharedPrefsKeys.notificationsEnabled, value);
  }

  static bool getNotificationsEnabled() {
    return _prefs.getBool(SharedPrefsKeys.notificationsEnabled) ?? true;
  }

  // Sync
  static Future<void> saveLastSyncTime(DateTime time) async {
    await _prefs.setString(
      SharedPrefsKeys.lastSyncTime,
      time.toIso8601String(),
    );
  }

  static DateTime? getLastSyncTime() {
    final timeStr = _prefs.getString(SharedPrefsKeys.lastSyncTime);
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  // Clear data on logout
  static Future<void> clearAuthData() async {
    await _prefs.remove(SharedPrefsKeys.authToken);
    await _prefs.remove(SharedPrefsKeys.userId);
    await _prefs.remove(SharedPrefsKeys.userEmail);
    await _prefs.remove(SharedPrefsKeys.userName);
    await _prefs.remove(SharedPrefsKeys.userRole);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
