import 'services/login_api_service.dart';

class LoginModel {
  LoginModel({LoginApiService? apiService})
    : _apiService = apiService ?? LoginApiService();

  final LoginApiService _apiService;

  String email = '';
  String password = '';
  bool isPasswordVisible = false;

  String? emailError;
  String? passwordError;
  String? loginError;
  String? loginMessage;
  String? userId;
  String? name;
  String? emailId;

  void validateEmail() {
    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailError = 'Enter a valid email';
    } else {
      emailError = null;
    }
  }

  void validatePassword() {
    if (password.isEmpty) {
      passwordError = 'Password is required';
    } else if (password.length < 6) {
      passwordError = 'Minimum 6 characters required';
    } else {
      passwordError = null;
    }
  }

  bool get isValid =>
      emailError == null &&
      passwordError == null &&
      email.isNotEmpty &&
      password.isNotEmpty;

  Future<bool> login() async {
    final response = await _apiService.signIn(
      email: email.trim(),
      password: password,
    );

    loginMessage = response.message;

    if (response.success) {
      loginError = null;
      userId = response.userId;
      name = response.name;
      emailId = response.email;
      return true;
    }

    loginError = response.message;
    return false;
  }
}

