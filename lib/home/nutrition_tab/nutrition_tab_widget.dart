import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../foodscanner/foodscanner_model.dart';

// ─── Design Tokens (Home Widget Style) ───────────────────────────────────────
class _NutritionDS {
  // Brand palette - home widget colors
  static const pageBg = Color(0xFFF5F0F3);
  static const cardBg = Color(0xFFFFFFFF);
  static const brandDark = Color(0xFF3A112D);
  static const accentPink = Color(0xFFD24787);
  static const accentLight = Color(0xFFF4D2DE);

  static const textPrimary = Color(0xFF221A26);
  static const textSecondary = Color(0xFF8B7F8F);
  static const textMuted = Color(0xFFB3ABB6);

  // Macro colours
  static const carbColor = Color(0xFFFFC66D);
  static const proteinColor = Color(0xFF6DBEFF);
  static const fatColor = Color(0xFF5FD4A3);

  // Success & Error
  static const success = Color(0xFF5FD4A3);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFC66D);

  // Radii
  static const r8 = 8.0;
  static const r10 = 10.0;
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r28 = 28.0;

  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? textPrimary,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? textSecondary,
      );
}

// ─── Nutrition Quotes ─────────────────────────────────────────────────────────
class _NutritionQuotes {
  static const List<String> quotes = [
    '🥗 Analyzing your meal...',
    '💪 Loading nutrition facts...',
    '🥑 Checking macros...',
    '🌟 Discovering health benefits...',
    '📊 Processing food data...',
    '🍎 Evaluating nutritional value...',
    '⚡ Fetching analysis results...',
    '🎯 Analyzing food composition...',
  ];

  static String random() {
    return quotes[DateTime.now().millisecond % quotes.length];
  }
}

// ─── Nutrition Tab Widget ─────────────────────────────────────────────────────
class NutritionTabWidget extends StatefulWidget {
  const NutritionTabWidget({super.key});

  @override
  State<NutritionTabWidget> createState() => _NutritionTabWidgetState();
}

class _NutritionTabWidgetState extends State<NutritionTabWidget>
    with WidgetsBindingObserver {
  late final FoodScannerModel _model;
  bool _showCaptureFlow = false;

  @override
  void initState() {
    super.initState();
    _model = FoodScannerModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _openCameraFlow() async {
    final capturedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _NutritionCameraCaptureWidget()),
    );
    if (!mounted || capturedPath == null || capturedPath.trim().isEmpty) return;
    await _model.setImageFromPathAndAnalyse(capturedPath);
  }

  Future<void> _pickFromGalleryAndAnalyse() async {
    await _model.pickFromGalleryAndAnalyse();
  }

  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: _NutritionDS.cardBg,
            borderRadius: BorderRadius.circular(_NutritionDS.r20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _NutritionDS.accentLight,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _NutritionDS.accentPink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _NutritionQuotes.random(),
                style: _NutritionDS.display(16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please wait while we analyze your meal',
                style: _NutritionDS.body(12, color: _NutritionDS.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _num(String raw) {
    final m = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(raw);
    return double.tryParse(m?.group(0) ?? '') ?? 0;
  }

  String _macroDisplay(String raw) {
    final v = _num(raw);
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}g';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _NutritionDS.pageBg,
      body: AnimatedBuilder(
        animation: _model,
        builder: (context, _) {
          // Show loading dialog when analyzing
          if (_model.isAnalyzing && !_model.isPickingImage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              _showLoadingDialog();
            });
          } else if (_model.result != null) {
            // Close loading dialog when result arrives
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
          }

          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBackground()),
                Positioned.fill(
                  child: _showCaptureFlow
                      ? Column(
                          children: [
                            Expanded(
                              child: _model.result != null
                                  ? _buildResultView()
                                  : const SizedBox.shrink(),
                            ),
                            _buildCameraControls(),
                          ],
                        )
                      : _buildLandingScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandingScreen() {
    return Scaffold(
      backgroundColor: _NutritionDS.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                30,
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Perfect ',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: _NutritionDS.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Food Scanner',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: _NutritionDS.accentPink,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Instant nutrition analysis with AI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _NutritionDS.textSecondary,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _NutritionDS.warning.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flash_on,
                                  size: 12,
                                  color: _NutritionDS.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Powered',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _NutritionDS.warning,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Benefits Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBenefitItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Macros',
                          color: _NutritionDS.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildBenefitItem(
                          icon: Icons.favorite_rounded,
                          label: 'Health',
                          color: _NutritionDS.danger,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildBenefitItem(
                          icon: Icons.flash_on_rounded,
                          label: 'Instant',
                          color: const Color(0xFF6DBEFF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // TODAY'S GOAL Section with Food Image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _NutritionDS.brandDark,
                          _NutritionDS.brandDark.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_NutritionDS.r16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left side: Text and button
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TODAY'S GOAL",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scan your\nmeal,\nknow your\nintake',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _showCaptureFlow = true);
                                  _openCameraFlow();
                                },
                                icon: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Scan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _NutritionDS.accentPink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right side: Food image (no box)
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              _NutritionDS.r16,
                            ),
                            child: Image.asset(
                              'assests/images/foodscanner_person.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    size: 32,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Scan Your Meal Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Scan Your Meal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _NutritionDS.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Camera & Gallery Cards (Horizontal)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSquareActionCard(
                          icon: Icons.camera_alt_rounded,
                          title: 'Camera',
                          subtitle: 'Snap & analyze\ninstantly',
                          color: _NutritionDS.accentPink,
                          onTap: _handleCameraTap,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSquareActionCard(
                          icon: Icons.image_rounded,
                          title: 'Gallery',
                          subtitle: 'Pick from your\nphotos',
                          color: const Color(0xFF6DBEFF),
                          onTap: _handleGalleryTap,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCameraTap() {
    if (!mounted) return;
    setState(() => _showCaptureFlow = true);
    _openCameraFlow();
  }

  void _handleGalleryTap() {
    if (!mounted) return;
    setState(() => _showCaptureFlow = true);
    _pickFromGalleryAndAnalyse();
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_NutritionDS.r12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(_NutritionDS.r10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _NutritionDS.textPrimary,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSquareActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: color.withValues(alpha: 0.1),
      highlightColor: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(_NutritionDS.r14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_NutritionDS.r14),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(_NutritionDS.r12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _NutritionDS.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _NutritionDS.textSecondary,
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Icon(Icons.arrow_forward_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final img = _model.selectedImage;
    if (img == null || img.path.trim().isEmpty) {
      return Container(
        decoration: const BoxDecoration(color: _NutritionDS.pageBg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _NutritionDS.accentLight,
                  border: Border.all(
                    color: _NutritionDS.accentPink.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: _NutritionDS.accentPink,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text('Scan Your Meal', style: _NutritionDS.display(20)),
              const SizedBox(height: 8),
              Text(
                'Take a photo or pick from gallery',
                style: _NutritionDS.body(13, color: _NutritionDS.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final file = File(img.path);
    if (!file.existsSync()) {
      return Container(color: _NutritionDS.pageBg);
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: _NutritionDS.pageBg),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_model.selectedImage != null && _model.result == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_NutritionDS.accentPink, Color(0xFFC54882)],
                ),
                borderRadius: BorderRadius.circular(_NutritionDS.r12),
                boxShadow: [
                  BoxShadow(
                    color: _NutritionDS.accentPink.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _model.isAnalyzing ? null : () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _model.isAnalyzing ? Icons.hourglass_top : Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _model.isAnalyzing ? 'Analyzing...' : 'Analyze Meal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _controlButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: _model.isAnalyzing ? null : _pickFromGalleryAndAnalyse,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _controlButton(
                  icon: Icons.add_a_photo_rounded,
                  label: 'Camera',
                  onTap: _model.isAnalyzing ? null : _openCameraFlow,
                  primary: true,
                ),
              ),
            ],
          ),
          if (_model.analyzeError != null && _model.analyzeError!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _NutritionDS.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_NutritionDS.r8),
                  border: Border.all(
                    color: _NutritionDS.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: _NutritionDS.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _model.analyzeError!,
                        style: _NutritionDS.body(
                          11,
                          color: _NutritionDS.danger,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: primary ? _NutritionDS.accentPink : Colors.white,
          borderRadius: BorderRadius.circular(_NutritionDS.r12),
          border: Border.all(
            color: primary
                ? _NutritionDS.accentPink
                : _NutritionDS.textMuted.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: _NutritionDS.accentPink.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : _NutritionDS.accentPink,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary ? Colors.white : _NutritionDS.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _model.result;
    if (result == null) return const SizedBox.shrink();

    final carbs = _num(result.carbs);
    final protein = _num(result.protein);
    final fats = _num(result.fats);
    final total = (carbs + protein + fats).clamp(1, 9999);
    final calories = _num(result.calories);
    final score = _num(result.healthScore).clamp(0, 10);
    final scoreLabel = score >= 7
        ? 'Excellent'
        : score >= 4
        ? 'Good'
        : 'Moderate';
    final scoreColor = score >= 7
        ? _NutritionDS.success
        : score >= 4
        ? _NutritionDS.warning
        : _NutritionDS.danger;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_NutritionDS.r20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with Title and Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Scan Result',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _NutritionDS.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _model.clear();
                      setState(() => _showCaptureFlow = false);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _NutritionDS.accentPink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: _NutritionDS.accentPink,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable Content (Image, Name, Macros, Health Score)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Food Image (Prominent)
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_NutritionDS.r16),
                        color: _NutritionDS.pageBg,
                      ),
                      child: _buildFoodImage(),
                    ),
                    const SizedBox(height: 18),

                    // ── Food Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        result.foodName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _NutritionDS.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Total Calories (Prominent)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _NutritionDS.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(_NutritionDS.r12),
                          border: Border.all(
                            color: _NutritionDS.warning.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: _NutritionDS.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Total ${calories.toInt()} Kcal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _NutritionDS.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Macros (Three Circular Progress Cards)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _macroProgressCard(
                              label: 'Carbs',
                              value: _macroDisplay(result.carbs),
                              color: _NutritionDS.carbColor,
                              icon: Icons.grain_rounded,
                              percentage: (carbs / total * 100).toInt(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _macroProgressCard(
                              label: 'Protein',
                              value: _macroDisplay(result.protein),
                              color: _NutritionDS.proteinColor,
                              icon: Icons.fitness_center_rounded,
                              percentage: (protein / total * 100).toInt(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _macroProgressCard(
                              label: 'Fats',
                              value: _macroDisplay(result.fats),
                              color: _NutritionDS.fatColor,
                              icon: Icons.water_drop_rounded,
                              percentage: (fats / total * 100).toInt(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Health Score with Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _NutritionDS.textPrimary.withValues(
                            alpha: 0.04,
                          ),
                          borderRadius: BorderRadius.circular(_NutritionDS.r12),
                          border: Border.all(
                            color: _NutritionDS.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: scoreColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$scoreLabel Health Score',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _NutritionDS.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${score.toStringAsFixed(0)}/10',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: scoreColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: score / 10,
                                minHeight: 5,
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scoreColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Recommendation Section
                    if (result.recommendation != null &&
                        result.recommendation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _NutritionDS.accentLight.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(
                              _NutritionDS.r12,
                            ),
                            border: Border.all(
                              color: _NutritionDS.accentPink.withValues(
                                alpha: 0.2,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_rounded,
                                    color: _NutritionDS.accentPink,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recommendation',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _NutritionDS.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.recommendation ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _NutritionDS.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (result.recommendation != null &&
                        result.recommendation!.isNotEmpty)
                      const SizedBox(height: 12),

                    // ── Alternative Section
                    if (result.alternative != null &&
                        result.alternative!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _NutritionDS.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              _NutritionDS.r12,
                            ),
                            border: Border.all(
                              color: _NutritionDS.success.withValues(
                                alpha: 0.2,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    color: _NutritionDS.success,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Alternative Option',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _NutritionDS.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.alternative ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _NutritionDS.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Action Buttons (Update Details & Next)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement edit details flow
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit details coming soon'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: const BorderSide(
                          color: _NutritionDS.accentPink,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_NutritionDS.r10),
                        ),
                      ),
                      child: Text(
                        'Update Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _NutritionDS.accentPink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _model.clear();
                        setState(() => _showCaptureFlow = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _NutritionDS.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_NutritionDS.r10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    final img = _model.selectedImage;
    if (img == null || img.path.trim().isEmpty) {
      return Container(
        color: _NutritionDS.pageBg,
        child: Center(
          child: Icon(
            Icons.image_rounded,
            color: _NutritionDS.textMuted,
            size: 48,
          ),
        ),
      );
    }
    final file = File(img.path);
    if (!file.existsSync()) {
      return Container(color: _NutritionDS.pageBg);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(_NutritionDS.r16),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: _NutritionDS.pageBg),
      ),
    );
  }

  Widget _macroProgressCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required int percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_NutritionDS.r12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _NutritionDS.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _NutritionDS.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Camera Capture Widget ────────────────────────────────────────────────────
class _NutritionCameraCaptureWidget extends StatefulWidget {
  const _NutritionCameraCaptureWidget();

  @override
  State<_NutritionCameraCaptureWidget> createState() =>
      _NutritionCameraCaptureWidgetState();
}

class _NutritionCameraCaptureWidgetState
    extends State<_NutritionCameraCaptureWidget> {
  late CameraController _controller;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await _controller.takePicture();
      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                // Top Close Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Capture Button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _capturePhoto,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: _NutritionDS.accentPink.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: _NutritionDS.accentPink,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
