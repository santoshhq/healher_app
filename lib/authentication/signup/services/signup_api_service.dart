import 'dart:convert';

import 'package:http/http.dart' as http;

class SignupResponse {
  const SignupResponse({
    required this.success,
    required this.message,
    this.tempId,
  });

  final bool success;
  final String message;
  final String? tempId;
}

class OtpVerifyResponse {
  const OtpVerifyResponse({
    required this.success,
    required this.message,
    this.userId,
  });

  final bool success;
  final String message;
  final String? userId;
}

class ApiStatusResponse {
  const ApiStatusResponse({required this.success, required this.message});

  final bool success;
  final String message;
}

class SignupApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  Future<SignupResponse> signUp({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/sign-up');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email_id': email,
          'mobile_number': mobile,
          'password': password,
        }),
      );

      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Signup request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SignupResponse(
          success: true,
          message: message,
          tempId: payload['temp_id']?.toString(),
        );
      }

      return SignupResponse(success: false, message: message);
    } catch (_) {
      return const SignupResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Future<OtpVerifyResponse> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/verify-otp',
    ).replace(queryParameters: {'email': email, 'otp': otp});

    try {
      final response = await http.post(uri);
      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'OTP verification completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return OtpVerifyResponse(
          success: true,
          message: message,
          userId: payload['userId']?.toString(),
        );
      }

      return OtpVerifyResponse(success: false, message: message);
    } catch (_) {
      return const OtpVerifyResponse(
        success: false,
        message: 'Unable to connect. Please try again.',
      );
    }
  }

  Future<ApiStatusResponse> resendSignupOtp({required String email}) async {
    final uri = Uri.parse(
      '$_baseUrl/resend-otp',
    ).replace(queryParameters: {'email': email});

    try {
      final response = await http.post(uri);
      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Resend request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiStatusResponse(success: true, message: message);
      }

      return ApiStatusResponse(success: false, message: message);
    } catch (_) {
      return const ApiStatusResponse(
        success: false,
        message: 'Unable to connect. Please try again.',
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

