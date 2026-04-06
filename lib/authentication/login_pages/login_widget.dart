import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/app_theme.dart';
import '../services/auth_session_service.dart';
import '../../home/home_widget.dart';
import 'login_model.dart';
import '../forget_password/forgetpassword_widget.dart';
import '../signup/signup_widget.dart';

class LoginWidget extends StatefulWidget {
  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final LoginModel _model = LoginModel();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  /// 🎨 COLOR SYSTEM (PCOS APP)
  final Color primary = AppTheme.brandPrimary;
  final Color background = AppTheme.pageBackground;
  final Color textPrimary = AppTheme.brandInk;
  final Color textSecondary = AppTheme.mutedText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.pageBackgroundDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                /// 🌸 LOGO WITH ANIMATION
                Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset('assests/images/healhericon.png'),
                      ),
                    )
                    .animate()
                    .scale(delay: 200.ms, duration: 600.ms)
                    .fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                /// 🌸 TITLE WITH ANIMATION
                Text(
                      "Welcome back",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.3, delay: 400.ms),

                const SizedBox(height: 8),

                /// 🌿 SUBTITLE WITH ANIMATION
                Text(
                      "Let's continue your wellness journey",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.2, delay: 600.ms),

                const SizedBox(height: 48),

                /// 🧾 FORM CARD WITH ANIMATION
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
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

                        const SizedBox(height: 20),

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
                                });
                              },
                              error: _model.passwordError,
                            )
                            .animate()
                            .fadeIn(delay: 900.ms)
                            .slideX(begin: -0.1, delay: 900.ms),

                        const SizedBox(height: 12),

                        /// 🔗 FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgetPasswordWidget(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 1000.ms),

                        const SizedBox(height: 24),

                        /// 💗 PRIMARY BUTTON WITH ANIMATION
                        Container(
                              width: double.infinity,
                              height: 56,
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
                                          final loginSuccess = await _model
                                              .login();
                                          setState(() => _isLoading = false);

                                          if (!mounted) {
                                            return;
                                          }

                                          if (loginSuccess) {
                                            await AuthSessionService()
                                                .saveSession(
                                                  userId: _model.userId ?? '',
                                                  fullName:
                                                      _model.name ?? 'User',
                                                  email:
                                                      _model.emailId ??
                                                      _model.email,
                                                );

                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    HomeWidget(
                                                      userId:
                                                          _model.userId ?? '',
                                                      fullName:
                                                          _model.name ?? 'User',
                                                    ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _model.loginError ??
                                                      'Sign in failed. Please try again.',
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
                                        "Sign In",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 1100.ms)
                            .scale(delay: 1100.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, delay: 700.ms),

                const SizedBox(height: 32),

                /// 🌿 FOOTER WITH ANIMATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpWidget(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Sign up",
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🌸 INPUT FIELD WITH MODERN DESIGN
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
              fontSize: 16,
              color: const Color(0xFF2E2E2E),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF8A8A8A),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: error != null ? Colors.red : const Color(0xFF8A8A8A),
                size: 22,
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
                horizontal: 20,
                vertical: 18,
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
