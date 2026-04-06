import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_session_service.dart';

class ProfileModule extends ChangeNotifier {
  ProfileModule({AuthSessionService? sessionService})
    : _sessionService = sessionService ?? AuthSessionService();

  final AuthSessionService _sessionService;

  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  AuthSession? _session;

  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  String? get errorMessage => _errorMessage;

  String get userId => _session?.userId ?? '';
  String get fullName => _session?.fullName ?? '';
  String get email => _session?.email ?? '';

  Future<void> loadUserDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _sessionService.getSession();
      if (_session == null) {
        _errorMessage = 'No active session found.';
      }
    } catch (_) {
      _errorMessage = 'Unable to load profile details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoggingOut = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _sessionService.clearSession();
      _session = null;
      return true;
    } catch (_) {
      _errorMessage = 'Logout failed. Please try again.';
      return false;
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }
}

