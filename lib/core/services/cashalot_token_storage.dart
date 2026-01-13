import 'package:shared_preferences/shared_preferences.dart';

class CashalotTokenStorage {
  static const String _accessTokenKey = 'cashalot_access_token';
  static const String _refreshTokenKey = 'cashalot_refresh_token';
  static const String _accessTokenExpiryKey = 'cashalot_access_token_expiry';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? accessTokenExpiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    if (accessTokenExpiry != null) {
      await prefs.setString(
        _accessTokenExpiryKey,
        accessTokenExpiry.toIso8601String(),
      );
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<DateTime?> getAccessTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accessTokenExpiryKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accessTokenExpiryKey);
  }
}
