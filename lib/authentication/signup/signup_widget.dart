import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/app_theme.dart';
import 'signup_model.dart';
import 'signupotp_widget.dart';
import '../login_pages/login_widget.dart';

class SignUpWidget extends StatefulWidget {
  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final SignupModel _model = SignupModel();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final Color primary = AppTheme.brandPrimary;
  final Color background = AppTheme.pageBackground;
  final Color textSecondary = AppTheme.mutedText;

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

                /// BACK BUTTON
                Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: const Color(0xFF2E2E2E),
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

                const SizedBox(height: 12),

                /// 🌸 LOGO WITH ANIMATION
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
                    .scale(delay: 200.ms, duration: 600.ms)
                    .fadeIn(delay: 200.ms),

                const SizedBox(height: 18),

                /// TITLE WITH ANIMATION
                Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2E2E),
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.3, delay: 300.ms),

                const SizedBox(height: 8),

                /// SUBTITLE WITH ANIMATION
                Text(
                      "Start your wellness journey today",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.2, delay: 500.ms),

                const SizedBox(height: 22),

                /// FORM CARD WITH ANIMATION
                Container(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// 👤 FULL NAME
                        _buildInput(
                              hint: "Full Name",
                              icon: Icons.person_outline,
                              onChanged: (val) {
                                setState(() {
                                  _model.name = val;
                                  _model.validateName();
                                });
                              },
                              error: _model.nameError,
                            )
                            .animate()
                            .fadeIn(delay: 700.ms)
                            .slideX(begin: -0.1, delay: 700.ms),

                        const SizedBox(height: 12),

                        /// 📧 EMAIL
                        _buildInput(
                              hint: "Email address",
                              icon: Icons.email_outlined,
                              onChanged: (val) {
                                setState(() {
                                  _model.email = val;
                                  _model.validateEmail();
                                });
                              },
                              error: _model.emailError,
                            )
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .slideX(begin: -0.1, delay: 800.ms),

                        const SizedBox(height: 12),

                        /// 📱 MOBILE NUMBER
                        Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _model.mobileError != null
                                          ? Colors.red.withOpacity(0.3)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.call_outlined,
                                    size: 20,
                                    color: _model.mobileError != null
                                        ? Colors.red
                                        : const Color(0xFF8A8A8A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _model.mobileError != null
                                            ? Colors.red.withOpacity(0.3)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: const Color(0xFF2E2E2E),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Mobile Number",
                                        hintStyle: GoogleFonts.poppins(
                                          color: const Color(0xFF8A8A8A),
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                          child: Text(
                                            '+91',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _model.mobileError != null
                                                  ? Colors.red
                                                  : const Color(0xFF8A8A8A),
                                            ),
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: primary.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _model.mobile = val;
                                          _model.validateMobile();
                                        });
                                      },
                                      validator: (_) => _model.mobileError,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(delay: 900.ms)
                            .slideX(begin: -0.1, delay: 900.ms),

                        if (_model.mobileError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              _model.mobileError!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        /// 🔐 PASSWORD
                        _buildInput(
                              hint: "Password",
                              icon: Icons.lock_outline,
                              obscure: !_model.isPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  _model.isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _model.isPasswordVisible =
                                        !_model.isPasswordVisible;
                                  });
                                },
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _model.password = val;
                                  _model.validatePassword();
                                  _model.validateConfirmPassword();
                                });
                              },
                              error: _model.passwordError,
                            )
                            .animate()
                            .fadeIn(delay: 1000.ms)
                            .slideX(begin: -0.1, delay: 1000.ms),

                        const SizedBox(height: 12),

                        /// 🔐 CONFIRM PASSWORD
                        _buildInput(
                              hint: "Confirm Password",
                              icon: Icons.lock_outline,
                              obscure: !_model.isConfirmPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  _model.isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _model.isConfirmPasswordVisible =
                                        !_model.isConfirmPasswordVisible;
                                  });
                                },
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _model.confirmPassword = val;
                                  _model.validateConfirmPassword();
                                });
                              },
                              error: _model.confirmPasswordError,
                            )
                            .animate()
                            .fadeIn(delay: 1100.ms)
                            .slideX(begin: -0.1, delay: 1100.ms),

                        const SizedBox(height: 18),

                        /// 💗 SIGN UP BUTTON WITH ANIMATION
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
                                onPressed: !_model.isValid || _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _isLoading = true);
                                          final isSignupSuccess = await _model
                                              .signup();
                                          setState(() => _isLoading = false);

                                          if (!mounted) {
                                            return;
                                          }

                                          if (isSignupSuccess) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SignupOtpWidget(
                                                      email: _model.email
                                                          .trim(),
                                                      fullName: _model.name
                                                          .trim(),
                                                    ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _model.signupError ??
                                                      'Signup failed. Please try again.',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                backgroundColor:
                                                    Colors.red.shade600,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        "Create Account",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 1200.ms)
                            .scale(delay: 1200.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, delay: 600.ms),

                const SizedBox(height: 16),

                /// 🌿 FOOTER WITH ANIMATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginWidget(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Sign in",
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1300.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    String? error,
    bool obscure = false,
    Widget? suffix,
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
              width: 1.5,
            ),
          ),
          child: TextFormField(
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
              prefixIcon: Icon(
                icon,
                color: error != null ? Colors.red : const Color(0xFF8A8A8A),
                size: 20,
              ),
              suffixIcon: suffix,
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
            validator: (_) => error,
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
}

