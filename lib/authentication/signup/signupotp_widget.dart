import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/app_theme.dart';
import '../services/auth_session_service.dart';
import '../../home/home_widget.dart';
import 'signupotp_model.dart';

class SignupOtpWidget extends StatefulWidget {
  const SignupOtpWidget({
    required this.email,
    required this.fullName,
    super.key,
  });

  final String email;
  final String fullName;

  @override
  State<SignupOtpWidget> createState() => _SignupOtpWidgetState();
}

class _SignupOtpWidgetState extends State<SignupOtpWidget> {
  final SignupOtpModel _model = SignupOtpModel();
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;

  final Color primary = AppTheme.brandPrimary;
  final Color background = AppTheme.pageBackground;
  final Color textSecondary = AppTheme.mutedText;

  int _activeFieldIndex = 0;
  Timer? _otpTimer;

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

  void _startOtpSession() {
    _model.issueOtp(email: widget.email.trim());
    _startOtpCountdown();
  }

  @override
  void initState() {
    super.initState();
    _startOtpSession();
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    final digit = value.isEmpty ? '' : value[value.length - 1];
    _controllers[index].text = digit;
    _controllers[index].selection = TextSelection.fromPosition(
      TextPosition(offset: _controllers[index].text.length),
    );

    setState(() {
      _model.setDigit(index, digit);
    });

    if (digit.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Widget _buildOtpField(int index) {
    final isActive = _activeFieldIndex == index;
    final hasValue = _controllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 66,
      height: 66,
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
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 24,
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
            _controllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[index].text.length),
            );
          },
          onChanged: (value) {
            _onOtpChanged(index, value);
            setState(() => _activeFieldIndex = index);

            if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
              setState(() => _activeFieldIndex = index - 1);
            }
          },
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
    });

    final verified = await _model.verifyOtp();

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = false;
    });

    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _model.otpSuccessMessage ?? 'OTP verified successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      await AuthSessionService().saveSession(
        userId: _model.verifiedUserId ?? '',
        fullName: widget.fullName,
        email: widget.email,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeWidget(
            userId: _model.verifiedUserId ?? '',
            fullName: widget.fullName,
          ),
        ),
        (route) => false,
      );
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _model.otpError ?? 'OTP verification failed',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_model.canResend) {
      setState(() {
        _model.otpError = 'Please wait until OTP expires before resend';
      });
      return;
    }

    setState(() {
      _isResending = true;
    });

    final didResend = await _model.resendOtp();

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
      if (didResend) {
        for (var i = 0; i < _controllers.length; i++) {
          _controllers[i].clear();
          _model.setDigit(i, '');
        }
      }
      _activeFieldIndex = 0;
    });

    if (didResend) {
      _startOtpCountdown();
      _focusNodes.first.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _model.otpSuccessMessage ??
                'A new OTP has been sent to ${widget.email.trim()}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      );
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.pageBackgroundDecoration(),
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
                        child: Image.asset('assets/images/healhericon.png'),
                      ),
                    )
                    .animate()
                    .scale(delay: 200.ms, duration: 500.ms)
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 18),
                Text(
                      'Verify OTP',
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
                  'Enter the 4-digit code sent to ${_maskEmail(widget.email.trim())}',
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
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'OTP Code',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF494949),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(4, (index) {
                              return _buildOtpField(index);
                            }),
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
                              onPressed: _isVerifying ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isVerifying
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Verify OTP',
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
                                    : _resendOtp,
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

