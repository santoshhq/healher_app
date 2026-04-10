import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'foodscanner_model.dart';
import 'scannedfoods/scannedfoods_page.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _DS {
  // Brand palette
  static const bg = Color(0xFF0E0E12);
  static const surfaceHigh = Color(0xFF1E1E28);
  static const card = Color(0xFF1C1C24);
  static const cardBorder = Color(0xFF2A2A38);

  static const accent = Color(0xFFD4F26E); // lime-green accent
  static const accentDim = Color(0xFF8FAD35);
  static const accentBg = Color(0xFF1E2410);

  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFC66D);

  static const textPrimary = Color(0xFFF4F4F6);
  static const textSecondary = Color(0xFF8888A0);
  static const textMuted = Color(0xFF555568);

  // Macro colours
  static const carbColor = Color(0xFFFFC66D);
  static const proteinColor = Color(0xFF6DBEFF);
  static const fatColor = Color(0xFFD4F26E);

  // Radii
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r28 = 28.0;
  static const r36 = 36.0;

  // Text styles
  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? textSecondary,
      );

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? textPrimary,
        letterSpacing: -0.3,
      );
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────
Widget _pill({
  required Widget child,
  Color bg = _DS.surfaceHigh,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  double radius = _DS.r36,
  Color? border,
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(radius),
    border: border != null ? Border.all(color: border, width: 1) : null,
  ),
  child: child,
);

Widget _iconBtn({
  required IconData icon,
  required VoidCallback? onTap,
  double size = 42,
  Color bg = const Color(0x33FFFFFF),
  Color fg = Colors.white,
}) => GestureDetector(
  onTap: onTap,
  child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Icon(icon, color: fg, size: size * 0.44),
  ),
);

// ─── Scan Corner Reticle ──────────────────────────────────────────────────────
Widget _buildReticle() {
  Widget corner(Alignment align, bool top, bool left) {
    return Align(
      alignment: align,
      child: SizedBox(
        width: 36,
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: top
                  ? const BorderSide(color: _DS.accent, width: 2.5)
                  : BorderSide.none,
              bottom: !top
                  ? const BorderSide(color: _DS.accent, width: 2.5)
                  : BorderSide.none,
              left: left
                  ? const BorderSide(color: _DS.accent, width: 2.5)
                  : BorderSide.none,
              right: !left
                  ? const BorderSide(color: _DS.accent, width: 2.5)
                  : BorderSide.none,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  return Positioned.fill(
    child: IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 130, 32, 210),
        child: Stack(
          children: [
            // Subtle overlay inside frame
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _DS.accent.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
            corner(Alignment.topLeft, true, true),
            corner(Alignment.topRight, true, false),
            corner(Alignment.bottomLeft, false, true),
            corner(Alignment.bottomRight, false, false),
          ],
        ),
      ),
    ),
  );
}

// ─── Macro Circle ────────────────────────────────────────────────────────────
class _MacroRing extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final double progress;
  final IconData icon;

  const _MacroRing({
    required this.value,
    required this.label,
    required this.color,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 5,
                    color: color.withValues(alpha: 0.1),
                  ),
                ),
                // Progress
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.04, 1.0),
                    strokeWidth: 5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Center icon + mini ring
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(value, style: _DS.mono(18, color: _DS.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: _DS.body(12, color: _DS.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
class FoodScannerWidget extends StatefulWidget {
  const FoodScannerWidget({super.key});

  @override
  State<FoodScannerWidget> createState() => _FoodScannerWidgetState();
}

class _FoodScannerWidgetState extends State<FoodScannerWidget>
    with SingleTickerProviderStateMixin {
  late final FoodScannerModel _model;
  bool _didAutoOpenCamera = false;
  late final AnimationController _shimmerController;

  Future<void> _openCameraFlow() async {
    final capturedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _FoodCameraCaptureWidget()),
    );
    if (!mounted || capturedPath == null || capturedPath.trim().isEmpty) return;
    await _model.setImageFromPathAndAnalyse(capturedPath);
  }

  Future<void> _openHistory() async {
    final userId = await _model.resolveUserId();
    if (!mounted) return;

    if (userId == null || userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login and retry.'),
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ScannedFoodsPage(userId: userId)),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = FoodScannerModel();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutoOpenCamera) return;
      _didAutoOpenCamera = true;
      _openCameraFlow();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  double _num(String raw) {
    final m = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(raw);
    return double.tryParse(m?.group(0) ?? '') ?? 0;
  }

  String _macroDisplay(String raw) {
    final v = _num(raw);
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}g';
  }

  // ── Empty / Image Background ─────────────────────────────────────────────
  Widget _buildBackground() {
    final img = _model.selectedImage;
    if (img == null || img.path.trim().isEmpty) {
      return Container(
        decoration: const BoxDecoration(color: _DS.bg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _DS.surfaceHigh,
                  border: Border.all(color: _DS.cardBorder, width: 1.5),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: _DS.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text('Point your camera at food', style: _DS.display(18)),
              const SizedBox(height: 8),
              Text('or upload from gallery', style: _DS.body(14)),
            ],
          ),
        ),
      );
    }
    final file = File(img.path);
    if (!file.existsSync()) {
      return Container(
        color: _DS.bg,
        child: Center(child: Text('Image unavailable', style: _DS.body(14))),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: _DS.bg),
    );
  }

  // ── Result Sheet ─────────────────────────────────────────────────────────
  Widget _buildResultSheet() {
    final result = _model.result;
    if (result == null) return const SizedBox.shrink();

    final carbs = _num(result.carbs);
    final protein = _num(result.protein);
    final fats = _num(result.fats);
    final total = (carbs + protein + fats).clamp(1, 9999);
    final score = _num(result.healthScore).clamp(0, 10);
    final scoreLabel = score >= 7
        ? 'Excellent'
        : score >= 4
        ? 'Moderate'
        : 'Low';
    final scoreColor = score >= 7
        ? _DS.accent
        : score >= 4
        ? _DS.warning
        : _DS.danger;

    final maxSheetHeight = MediaQuery.of(context).size.height * 0.72;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(_DS.r28),
          border: Border.all(color: _DS.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 330;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _DS.textMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // ── Food name + calories row
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.foodName,
                          style: _DS.display(22),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('Nutritional breakdown', style: _DS.body(12)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _DS.accentBg,
                            borderRadius: BorderRadius.circular(_DS.r16),
                            border: Border.all(
                              color: _DS.accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                result.calories,
                                style: _DS.mono(22, color: _DS.accent),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'kcal',
                                style: _DS.body(11, color: _DS.accentDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.foodName,
                                style: _DS.display(24),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nutritional breakdown',
                                style: _DS.body(12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _DS.accentBg,
                            borderRadius: BorderRadius.circular(_DS.r16),
                            border: Border.all(
                              color: _DS.accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                result.calories,
                                style: _DS.mono(22, color: _DS.accent),
                              ),
                              Text(
                                'kcal',
                                style: _DS.body(11, color: _DS.accentDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  Divider(color: _DS.cardBorder, height: 1),
                  const SizedBox(height: 20),

                  // ── Macro circles
                  Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _MacroRing(
                        value: _macroDisplay(result.carbs),
                        label: 'Carbs',
                        color: _DS.carbColor,
                        progress: carbs / total,
                        icon: Icons.grain_rounded,
                      ),
                      _MacroRing(
                        value: _macroDisplay(result.protein),
                        label: 'Protein',
                        color: _DS.proteinColor,
                        progress: protein / total,
                        icon: Icons.bubble_chart_rounded,
                      ),
                      _MacroRing(
                        value: _macroDisplay(result.fats),
                        label: 'Fats',
                        color: _DS.fatColor,
                        progress: fats / total,
                        icon: Icons.eco_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Health score bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _DS.surfaceHigh,
                      borderRadius: BorderRadius.circular(_DS.r16),
                      border: Border.all(color: _DS.cardBorder, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (compact)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: scoreColor.withValues(alpha: 0.15),
                                    ),
                                    child: Icon(
                                      score >= 7
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 14,
                                      color: scoreColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Health Score',
                                    style: _DS.body(
                                      13,
                                      color: _DS.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _pill(
                                    bg: scoreColor.withValues(alpha: 0.12),
                                    border: scoreColor.withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      scoreLabel,
                                      style: _DS.body(
                                        11,
                                        color: scoreColor,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)}/10',
                                    style: _DS.mono(15, color: _DS.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scoreColor.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  score >= 7
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 14,
                                  color: scoreColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Health Score',
                                style: _DS.body(13, color: _DS.textSecondary),
                              ),
                              const Spacer(),
                              _pill(
                                bg: scoreColor.withValues(alpha: 0.12),
                                border: scoreColor.withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  scoreLabel,
                                  style: _DS.body(
                                    11,
                                    color: scoreColor,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)}/10',
                                style: _DS.mono(15, color: _DS.textPrimary),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: score / 10,
                            minHeight: 6,
                            backgroundColor: _DS.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scoreColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Recommendation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _DS.surfaceHigh,
                      borderRadius: BorderRadius.circular(_DS.r16),
                      border: Border.all(color: _DS.cardBorder, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: _DS.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result.recommendation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _DS.body(12, color: _DS.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineBtn(
                          label: 'Retake',
                          icon: Icons.camera_alt_outlined,
                          onTap: _openCameraFlow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccentBtn(
                          label: 'Save & Next',
                          onTap: _model.clear,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Error Banner ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    final text = _model.analyzeError ?? _model.pickError;
    if (text == null) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      top: 90,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _DS.danger.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(_DS.r12),
          border: Border.all(color: _DS.danger, width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: _DS.body(
                  12,
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Analyze status banner ────────────────────────────────────────────────
  Widget _buildAnalyzeBanner() {
    final msg = _model.analyzeMessage;
    if (msg == null) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      top: 90,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _DS.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(_DS.r12),
          border: Border.all(
            color: _DS.accent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: _DS.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: _DS.body(12, color: _DS.accent, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom camera controls ───────────────────────────────────────────────
  Widget _buildCameraControls() {
    final busy = _model.isAnalyzing || _model.isPickingImage;
    final hasImage = _model.selectedImage != null;

    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Analyse button
          AnimatedOpacity(
            opacity: hasImage ? 1 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: (hasImage && !busy) ? _model.analyseImage : null,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: hasImage && !busy
                      ? const LinearGradient(
                          colors: [_DS.accent, Color(0xFFB0D44A)],
                        )
                      : null,
                  color: hasImage && !busy ? null : _DS.surfaceHigh,
                  borderRadius: BorderRadius.circular(_DS.r36),
                  border: Border.all(
                    color: hasImage && !busy
                        ? Colors.transparent
                        : _DS.cardBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: _model.isAnalyzing
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _DS.bg,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Analysing…',
                              style: _DS.body(
                                15,
                                color: _DS.bg,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Analyse Meal',
                          style: _DS.display(
                            15,
                            color: hasImage && !busy ? _DS.bg : _DS.textMuted,
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBtn(
                icon: Icons.photo_library_outlined,
                onTap: busy ? null : _model.pickFromGalleryAndAnalyse,
                bg: const Color(0x55FFFFFF),
              ),
              const SizedBox(width: 24),
              // Shutter
              GestureDetector(
                onTap: busy ? null : _openCameraFlow,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _DS.accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _DS.accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: _DS.bg,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: _DS.bg,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 24),
              _iconBtn(
                icon: Icons.restart_alt_rounded,
                onTap: _model.clear,
                bg: const Color(0x55FFFFFF),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: busy ? null : _openHistory,
            child: Text(
              'Show History',
              style: _DS.body(
                14,
                color: busy ? _DS.textMuted : Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        final hasResult = _model.result != null;
        final hasImage = _model.selectedImage != null;

        return Scaffold(
          backgroundColor: _DS.bg,
          body: Stack(
            children: [
              // Full-screen background
              Positioned.fill(child: _buildBackground()),

              // Vignette overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: hasImage
                          ? [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ]
                          : [
                              _DS.bg.withValues(alpha: 0.7),
                              Colors.transparent,
                              _DS.bg.withValues(alpha: 0.5),
                            ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Stack(
                  children: [
                    // ── Top bar
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 10,
                      child: Row(
                        children: [
                          _iconBtn(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          _pill(
                            bg: Colors.black.withValues(alpha: 0.4),
                            border: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              hasResult ? 'Scan Result' : 'Nutrition Scanner',
                              style: _DS.body(
                                14,
                                color: Colors.white,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _iconBtn(
                            icon: Icons.restart_alt_rounded,
                            onTap: _model.clear,
                          ),
                        ],
                      ),
                    ),

                    // ── Scan reticle (when no result)
                    if (!hasResult) _buildReticle(),

                    // ── Scan hint label
                    if (!hasResult && !hasImage)
                      Positioned(
                        bottom: 180,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _pill(
                            bg: Colors.black.withValues(alpha: 0.5),
                            border: _DS.accent.withValues(alpha: 0.3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 13,
                                  color: _DS.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Align food within the frame',
                                  style: _DS.body(12, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Banners
                    _buildErrorBanner(),
                    _buildAnalyzeBanner(),

                    // ── Camera controls
                    if (!hasResult) _buildCameraControls(),

                    // ── Result sheet
                    if (hasResult) _buildResultSheet(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Reusable Button Widgets ──────────────────────────────────────────────────
class _AccentBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AccentBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_DS.accent, Color(0xFFB0D44A)],
          ),
          borderRadius: BorderRadius.circular(_DS.r36),
        ),
        child: Center(
          child: Text(label, style: _DS.display(14, color: _DS.bg)),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _OutlineBtn({required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _DS.surfaceHigh,
          borderRadius: BorderRadius.circular(_DS.r36),
          border: Border.all(color: _DS.cardBorder, width: 1),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: _DS.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: _DS.body(
                  14,
                  color: _DS.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Camera Capture Widget ────────────────────────────────────────────────────
class _FoodCameraCaptureWidget extends StatefulWidget {
  const _FoodCameraCaptureWidget();

  @override
  State<_FoodCameraCaptureWidget> createState() =>
      _FoodCameraCaptureWidgetState();
}

class _FoodCameraCaptureWidgetState extends State<_FoodCameraCaptureWidget> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _cameraError = 'No camera found on this device.';
        });
        return;
      }

      final preferred = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        preferred,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _cameraError =
            'Unable to open camera. Please check permissions and try again.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing)
      return;
    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _cameraError = 'Failed to capture. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _corner({required bool top, required bool left}) => SizedBox(
    width: 36,
    height: 36,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: _DS.accent, width: 2.5)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: _DS.accent, width: 2.5)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: _DS.accent, width: 2.5)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: _DS.accent, width: 2.5)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: _DS.bg,
        body: Center(child: CircularProgressIndicator(color: _DS.accent)),
      );
    }

    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: _DS.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _DS.surfaceHigh,
                    border: Border.all(
                      color: _DS.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _DS.danger,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: _DS.body(14, color: _DS.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            Positioned.fill(child: CameraPreview(_controller!)),

            // Vignette
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              left: 16,
              top: 12,
              child: _iconBtn(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),

            // Camera label
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: _pill(
                  bg: Colors.black.withValues(alpha: 0.4),
                  border: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    'Frame your meal',
                    style: _DS.body(
                      13,
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Reticle
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 130, 32, 210),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: _corner(top: true, left: true),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: _corner(top: true, left: false),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _corner(top: false, left: true),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _corner(top: false, left: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Error banner
            if (_cameraError != null)
              Positioned(
                left: 16,
                right: 16,
                top: 90,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _DS.danger.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(_DS.r12),
                  ),
                  child: Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: _DS.body(
                      12,
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Bottom controls
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gallery icon (placeholder; wire up as needed)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Shutter
                  GestureDetector(
                    onTap: _isCapturing ? null : _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: _DS.accent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _DS.accent.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: _DS.bg,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: _DS.bg,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Settings
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.flash_auto_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
