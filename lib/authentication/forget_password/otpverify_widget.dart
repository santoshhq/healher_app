import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otpverify_model.dart';
import '../login_pages/login_widget.dart';

class OtpVerifyWidget extends StatefulWidget {
  const OtpVerifyWidget({required this.email, super.key});

  final String email;

  @override
  State<OtpVerifyWidget> createState() => _OtpVerifyWidgetState();
}

class _OtpVerifyWidgetState extends State<OtpVerifyWidget> {
  final OtpVerifyModel _model = OtpVerifyModel();

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  int _activeFieldIndex = 0;
  Timer? _otpTimer;

  final Color primary = const Color(0xFFE91E63);
  final Color background = const Color(0xFFFFF5F7);
  final Color textSecondary = const Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _model.startOtpSession(email: widget.email.trim());
    _startOtpCountdown();
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.isEmpty) {
      return email;
    }

    final localPart = parts.first;
    final domainPart = parts.last;
    if (localPart.length <= 2) {
      return '$localPart@$domainPart';
    }

    final visibleStart = localPart.substring(0, 2);
    return '$visibleStart${'*' * (localPart.length - 2)}@$domainPart';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startOtpCountdown() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {});
      if (_model.isExpired) {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    final digit = value.isEmpty ? '' : value[value.length - 1];
    _otpControllers[index].text = digit;
    _otpControllers[index].selection = TextSelection.fromPosition(
      TextPosition(offset: _otpControllers[index].text.length),
    );

    setState(() {
      _model.setDigit(index, digit);
    });

    if (digit.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
      setState(() => _activeFieldIndex = index + 1);
    }
  }

  Widget _buildOtpField(int index) {
    final isActive = _activeFieldIndex == index;
    final hasValue = _otpControllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isActive
            ? LinearGradient(
                colors: [primary.withOpacity(0.22), primary.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : const Color(0xFFF8F9FA),
        border: Border.all(
          color: isActive
              ? primary
              : hasValue
              ? primary.withOpacity(0.35)
              : const Color(0xFFEAEAEA),
          width: isActive ? 1.8 : 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E2E2E),
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isCollapsed: true,
          ),
          onTap: () {
            setState(() => _activeFieldIndex = index);
            _otpControllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _otpControllers[index].text.length),
            );
          },
          onChanged: (value) {
            _onOtpChanged(index, value);
            if (value.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
              setState(() => _activeFieldIndex = index - 1);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required Function(String) onChanged,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null
                  ? Colors.red.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF2E2E2E),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF8A8A8A),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF8A8A8A),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: textSecondary,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              error,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    setState(() {
      _isSubmitting = true;
      _model.newPassword = _newPasswordController.text.trim();
      _model.confirmPassword = _confirmPasswordController.text.trim();
    });

    final success = await _model.submitReset();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _model.otpError ?? 'Unable to reset password. Please try again.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _model.successMessage ?? 'Password reset successful',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginWidget()),
      (route) => false,
    );
  }

  Future<void> _onResend() async {
    if (!_model.canResend) {
      setState(() {
        _model.otpError = 'Please wait until OTP expires before resend';
      });
      return;
    }

    setState(() => _isResending = true);
    final resent = await _model.resendOtp();

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
      _activeFieldIndex = 0;
      if (resent) {
        for (final controller in _otpControllers) {
          controller.clear();
        }
      }
    });

    if (resent) {
      _startOtpCountdown();
      _otpFocusNodes.first.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _model.successMessage ??
                'A new OTP has been sent to ${widget.email.trim()}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _model.otpError ?? 'Unable to resend OTP',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [background, background.withOpacity(0.8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF2E2E2E),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideX(begin: -0.2, delay: 100.ms),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1D2DF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Step 2 of 2',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 160.ms),
                const SizedBox(height: 12),
                Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assests/images/healhericon.png'),
                      ),
                    )
                    .animate()
                    .scale(delay: 200.ms, duration: 500.ms)
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 18),
                Text(
                      'OTP Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2E2E),
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2, delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  'Enter OTP sent to ${_maskEmail(widget.email.trim())}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        _model.isExpired
                            ? 'OTP expired'
                            : 'Code expires in ${_formatDuration(_model.remainingDuration)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A4E67),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 18),
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OTP Code',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF494949),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              4,
                              (index) => _buildOtpField(index),
                            ),
                          ),
                          if (_model.otpError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                _model.otpError!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          _buildPasswordInput(
                            hint: 'New Password',
                            controller: _newPasswordController,
                            obscure: !_showNewPassword,
                            onToggle: () {
                              setState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _model.newPassword = value;
                                _model.validateNewPassword();
                                _model.confirmPassword =
                                    _confirmPasswordController.text;
                                _model.validateConfirmPassword();
                              });
                            },
                            error: _model.newPasswordError,
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordInput(
                            hint: 'Confirm Password',
                            controller: _confirmPasswordController,
                            obscure: !_showConfirmPassword,
                            onToggle: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _model.confirmPassword = value;
                                _model.newPassword =
                                    _newPasswordController.text;
                                _model.validateConfirmPassword();
                              });
                            },
                            error: _model.confirmPasswordError,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, primary.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Reset Password',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Did not receive code?',
                                style: GoogleFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: (_isResending || !_model.canResend)
                                    ? null
                                    : _onResend,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(left: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _isResending
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primary,
                                        ),
                                      )
                                    : Text(
                                        _model.canResend
                                            ? 'Resend'
                                            : 'Resend locked',
                                        style: GoogleFonts.poppins(
                                          color: _model.canResend
                                              ? primary
                                              : textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.1, delay: 500.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
