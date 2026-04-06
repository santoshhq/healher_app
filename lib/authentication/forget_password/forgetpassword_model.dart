import 'services/forget_password_api_service.dart';

class ForgetPasswordModel {
  ForgetPasswordModel({ForgetPasswordApiService? apiService})
    : _apiService = apiService ?? ForgetPasswordApiService();

  final ForgetPasswordApiService _apiService;

  String email = '';
  String? emailError;
  String? responseMessage;
  String? requestError;

  void validateEmail() {
    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailError = 'Enter a valid email';
    } else {
      emailError = null;
    }
  }

  bool get isValid => emailError == null && email.isNotEmpty;

  Future<bool> sendOtp() async {
    validateEmail();
    if (!isValid) {
      return false;
    }

    final response = await _apiService.requestForgotPasswordOtp(
      email: email.trim(),
    );

    responseMessage = response.message;

    if (response.success) {
      requestError = null;
      return true;
    }

    requestError = response.message;
    return false;
  }
}

