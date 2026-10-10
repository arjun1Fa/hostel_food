import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userIdKey = 'user_id';
  static const String _roomNumberKey = 'room_number';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> saveUserData({
    required int id,
    required String email,
    required String fullName,
    required String role,
    String? roomNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, fullName);
    await prefs.setString(_userRoleKey, role);
    if (roomNumber != null) {
      await prefs.setString(_roomNumberKey, roomNumber);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);
    final role = prefs.getString(_userRoleKey);
    final room = prefs.getString(_roomNumberKey);

    if (id == null || email == null || role == null) return null;

    return {
      'id': id,
      'email': email,
      'full_name': name ?? '',
      'role': role,
      'room_number': room,
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
