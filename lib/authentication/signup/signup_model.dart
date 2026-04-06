import 'services/signup_api_service.dart';

class SignupModel {
  SignupModel({SignupApiService? apiService})
    : _apiService = apiService ?? SignupApiService();

  final SignupApiService _apiService;

  String name = '';
  String email = '';
  String mobile = '';
  String password = '';
  String confirmPassword = '';
  String? tempId;
  String? signupMessage;
  String? signupError;

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  String? nameError;
  String? emailError;
  String? mobileError;
  String? passwordError;
  String? confirmPasswordError;

  void validateName() {
    if (name.isEmpty) {
      nameError = 'Name is required';
    } else if (name.length < 3) {
      nameError = 'Enter a valid name';
    } else {
      nameError = null;
    }
  }

  void validateEmail() {
    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailError = 'Enter a valid email';
    } else {
      emailError = null;
    }
  }

  void validateMobile() {
    if (mobile.isEmpty) {
      mobileError = 'Mobile number is required';
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      mobileError = 'Enter 10 digit number';
    } else {
      mobileError = null;
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

  void validateConfirmPassword() {
    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Confirm your password';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match';
    } else {
      confirmPasswordError = null;
    }
  }

  bool get isValid =>
      nameError == null &&
      emailError == null &&
      mobileError == null &&
      passwordError == null &&
      confirmPasswordError == null &&
      name.isNotEmpty &&
      email.isNotEmpty &&
      mobile.isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty;

  Future<bool> signup() async {
    final response = await _apiService.signUp(
      name: name.trim(),
      email: email.trim(),
      mobile: mobile.trim(),
      password: password,
    );

    signupMessage = response.message;
    if (response.success) {
      tempId = response.tempId;
      signupError = null;
      return true;
    }

    signupError = response.message;
    return false;
  }
}

