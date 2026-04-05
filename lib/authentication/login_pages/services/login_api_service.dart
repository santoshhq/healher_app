import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginResponse {
  const LoginResponse({
    required this.success,
    required this.message,
    this.userId,
    this.name,
    this.email,
  });

  final bool success;
  final String message;
  final String? userId;
  final String? name;
  final String? email;
}

class LoginApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  Future<LoginResponse> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/sign-in');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email_id': email, 'password': password}),
      );

      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? _statusMessage(response.statusCode);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LoginResponse(
          success: true,
          message: message,
          userId: payload['userId']?.toString(),
          name: payload['name']?.toString(),
          email: payload['email_id']?.toString(),
        );
      }

      return LoginResponse(success: false, message: message);
    } catch (_) {
      return const LoginResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  String? _extractMessage(Map<String, dynamic> payload) {
    final message = payload['message'] ?? payload['error'] ?? payload['detail'];
    if (message == null) {
      return null;
    }
    return message.toString();
  }

  String _statusMessage(int statusCode) {
    if (statusCode == 401) {
      return 'Invalid email or password, or account not verified.';
    }
    if (statusCode == 404) {
      return 'Account not found. Please sign up first.';
    }
    if (statusCode >= 500) {
      return 'Server error. Please try again in a moment.';
    }
    return 'Sign in request failed. Please try again.';
  }
}
