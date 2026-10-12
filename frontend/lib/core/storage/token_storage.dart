import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-appropriate secure storage service:
/// - Android & iOS: Encrypted Keystore / Keychain backed storage via FlutterSecureStorage.
/// - Web & PWA: Short-lived access token held in-memory only. Refresh token handled via HttpOnly cookie.
///   No long-lived tokens stored in localStorage or sessionStorage (OWASP ASVS compliance).
class TokenStorage {
  static const String _accessTokenKey = 'sec_access_token';
  static const String _refreshTokenKey = 'sec_refresh_token';
  static const String _csrfTokenKey = 'sec_csrf_token';

  // Shared non-sensitive profile keys
  static const String _userRoleKey = 'profile_user_role';
  static const String _userEmailKey = 'profile_user_email';
  static const String _userNameKey = 'profile_user_name';
  static const String _userIdKey = 'profile_user_id';
  static const String _roomNumberKey = 'profile_room_number';

  // Mobile / Desktop secure storage instance
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();


  // In-memory token storage for Web / PWA (ephemeral, cleared on browser tab close or reload)
  static String? _inMemoryAccessToken;
  static String? _inMemoryCsrfToken;

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? csrfToken,
  }) async {
    if (kIsWeb) {
      _inMemoryAccessToken = accessToken;
      if (csrfToken != null) {
        _inMemoryCsrfToken = csrfToken;
      }
      // On Web, refresh token is NOT stored in localStorage or sessionStorage.
      // It is securely held in an HttpOnly, Secure, SameSite=Lax cookie by the browser.
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      if (csrfToken != null) {
        await _secureStorage.write(key: _csrfTokenKey, value: csrfToken);
      }
    }
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
    if (kIsWeb) {
      return _inMemoryAccessToken;
    }
    return await _secureStorage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      // On Web, refresh token is transported via HttpOnly cookie
      return null;
    }
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  static Future<String?> getCsrfToken() async {
    if (kIsWeb) {
      return _inMemoryCsrfToken;
    }
    return await _secureStorage.read(key: _csrfTokenKey);
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
    if (kIsWeb) {
      _inMemoryAccessToken = null;
      _inMemoryCsrfToken = null;
    } else {
      await _secureStorage.deleteAll();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_roomNumberKey);
  }
}
