import 'services/forget_password_api_service.dart';

class OtpVerifyModel {
  OtpVerifyModel({ForgetPasswordApiService? apiService})
    : _apiService = apiService ?? ForgetPasswordApiService();

  final ForgetPasswordApiService _apiService;

  final List<String> digits = List<String>.filled(4, '');

  String newPassword = '';
  String confirmPassword = '';

  String? otpError;
  String? newPasswordError;
  String? confirmPasswordError;

  String? targetEmail;
  String? successMessage;
  DateTime? _issuedAt;

  static const Duration otpValidity = Duration(minutes: 5);

  bool get isOtpComplete => digits.every((digit) => digit.length == 1);
  String get otpCode => digits.join();

  Duration get remainingDuration {
    if (_issuedAt == null) {
      return otpValidity;
    }

    final expiryTime = _issuedAt!.add(otpValidity);
    final remaining = expiryTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => remainingDuration == Duration.zero;
  bool get canResend => isExpired;

  void startOtpSession({required String email}) {
    targetEmail = email;
    _issuedAt = DateTime.now();
    clearOtp();
    otpError = null;
  }

  void clearOtp() {
    for (var i = 0; i < digits.length; i++) {
      digits[i] = '';
    }
  }

  void setDigit(int index, String value) {
    if (index < 0 || index >= digits.length) {
      return;
    }
    digits[index] = value;
    otpError = null;
  }

  void validateOtp() {
    if (isExpired) {
      otpError = 'OTP expired. Please resend OTP';
      return;
    }

    if (!isOtpComplete) {
      otpError = 'Please enter 4-digit OTP';
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(otpCode)) {
      otpError = 'OTP must contain numbers only';
      return;
    }

    otpError = null;
  }

  void validateNewPassword() {
    if (newPassword.isEmpty) {
      newPasswordError = 'New password is required';
    } else if (newPassword.length < 6) {
      newPasswordError = 'Minimum 6 characters required';
    } else {
      newPasswordError = null;
    }
  }

  void validateConfirmPassword() {
    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm password';
    } else if (confirmPassword != newPassword) {
      confirmPasswordError = 'Passwords do not match';
    } else {
      confirmPasswordError = null;
    }
  }

  void validateAll() {
    validateOtp();
    validateNewPassword();
    validateConfirmPassword();
  }

  bool get canSubmit =>
      otpError == null &&
      newPasswordError == null &&
      confirmPasswordError == null &&
      isOtpComplete &&
      newPassword.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      !isExpired;

  Future<bool> submitReset() async {
    validateAll();
    if (!canSubmit) {
      return false;
    }

    final response = await _apiService.resetPassword(
      email: targetEmail!.trim(),
      otp: otpCode,
      newPassword: newPassword,
    );

    if (response.success) {
      otpError = null;
      successMessage = response.message;
      return true;
    }

    otpError = response.message;
    return false;
  }

  Future<bool> resendOtp() async {
    if (!canResend || targetEmail == null || targetEmail!.isEmpty) {
      otpError = 'Resend is available only after OTP expiry';
      return false;
    }

    final response = await _apiService.requestForgotPasswordOtp(
      email: targetEmail!.trim(),
    );

    if (!response.success) {
      otpError = response.message;
      return false;
    }

    startOtpSession(email: targetEmail!);
    successMessage = response.message;
    return true;
  }
}

