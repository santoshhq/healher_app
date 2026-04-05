import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.fullName,
    required this.email,
  });

  final String userId;
  final String fullName;
  final String email;
}

class AuthSessionService {
  static const String _userIdKey = 'auth_user_id';
  static const String _fullNameKey = 'auth_full_name';
  static const String _emailKey = 'auth_email';

  Future<void> saveSession({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_emailKey, email);
  }

  Future<AuthSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey)?.trim() ?? '';
    final fullName = prefs.getString(_fullNameKey)?.trim() ?? '';
    final email = prefs.getString(_emailKey)?.trim() ?? '';

    if (userId.isEmpty || fullName.isEmpty) {
      return null;
    }

    return AuthSession(userId: userId, fullName: fullName, email: email);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_emailKey);
  }
}
