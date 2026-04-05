import 'dart:convert';

import 'package:http/http.dart' as http;

class ForgotPasswordOtpResponse {
  const ForgotPasswordOtpResponse({
    required this.success,
    required this.message,
    this.email,
  });

  final bool success;
  final String message;
  final String? email;
}

class ResetPasswordResponse {
  const ResetPasswordResponse({
    required this.success,
    required this.message,
    this.email,
  });

  final bool success;
  final String message;
  final String? email;
}

class ForgetPasswordApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  Future<ForgotPasswordOtpResponse> requestForgotPasswordOtp({
    required String email,
  }) async {
    final uri = Uri.parse('$_baseUrl/forgot-password');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email_id': email}),
      );

      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Password reset OTP request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ForgotPasswordOtpResponse(
          success: true,
          message: message,
          email: payload['email_id']?.toString(),
        );
      }

      return ForgotPasswordOtpResponse(success: false, message: message);
    } catch (_) {
      return const ForgotPasswordOtpResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Future<ResetPasswordResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/reset-password');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_id': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Reset password request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ResetPasswordResponse(
          success: true,
          message: message,
          email: payload['email_id']?.toString(),
        );
      }

      return ResetPasswordResponse(success: false, message: message);
    } catch (_) {
      return const ResetPasswordResponse(
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
}
