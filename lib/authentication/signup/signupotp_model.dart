import 'services/signup_api_service.dart';

class SignupOtpModel {
  SignupOtpModel({SignupApiService? apiService})
    : _apiService = apiService ?? SignupApiService();

  final SignupApiService _apiService;

  final List<String> digits = List<String>.filled(4, '');
  String? otpError;
  String? targetEmail;
  String? otpSuccessMessage;
  String? verifiedUserId;

  static const Duration otpValidity = Duration(minutes: 5);
  DateTime? _issuedAt;

  bool get isComplete => digits.every((digit) => digit.length == 1);

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

  void issueOtp({required String email}) {
    targetEmail = email;
    _issuedAt = DateTime.now();
    otpError = null;
  }

  void clearDigits() {
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

    if (!isComplete) {
      otpError = 'Please enter 4-digit OTP';
      return;
    }

    final otpRegExp = RegExp(r'^\d{4}$');
    if (!otpRegExp.hasMatch(otpCode)) {
      otpError = 'OTP must contain numbers only';
      return;
    }

    otpError = null;
  }

  Future<bool> verifyOtp() async {
    validateOtp();
    if (otpError != null) {
      return false;
    }

    final response = await _apiService.verifySignupOtp(
      email: targetEmail!.trim(),
      otp: otpCode,
    );

    if (response.success) {
      otpError = null;
      otpSuccessMessage = response.message;
      verifiedUserId = response.userId;
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

    final response = await _apiService.resendSignupOtp(
      email: targetEmail!.trim(),
    );

    if (!response.success) {
      otpError = response.message;
      return false;
    }

    clearDigits();
    issueOtp(email: targetEmail!);
    otpSuccessMessage = response.message;
    return true;
  }
}

