import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pose_session_widget.dart';
import 'workouts_plans_model.dart';
import '../bottom_nav_widget.dart';
import '../home_widget.dart';
import '../profile/profile_widget.dart';

class WorkoutsPlansWidget extends StatefulWidget {
  const WorkoutsPlansWidget({
    required this.userId,
    required this.fullName,
    this.showBottomNav = true,
    this.onNavTap,
    this.onFabPressed,
    super.key,
  });
  final String userId;
  final String fullName;
  final bool showBottomNav;
  final ValueChanged<int>? onNavTap;
  final VoidCallback? onFabPressed;

  @override
  State<WorkoutsPlansWidget> createState() => _WorkoutsPlansWidgetState();
}

class _WorkoutsPlansWidgetState extends State<WorkoutsPlansWidget> {
  late final WorkoutsPlansModel _model;

  // ── Design System ─────────────────────────────────────────────
  static const _brandDark = Color(0xFF3A112D);
  static const _accentPink = Color(0xFFD24787);
  static const _accentLight = Color(0xFFF4D2DE);
  static const _textPrimary = Color(0xFF221A26);
  static const _textSecondary = Color(0xFF8B7F8F);
  static const _textMuted = Color(0xFFB3ABB6);
  static const _bgPage = Color(0xFFF5F0F3);
  static const _bgCard = Color(0xFFFFFFFF);
  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _model = WorkoutsPlansModel(userId: widget.userId);
    _model.addListener(_onModelChanged);
    _model.loadTodayCompletedWorkout();
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openPoseSession(int index) async {
    if (index < 0 || index >= _model.poseStates.length) return;

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PoseSessionWidget(pose: _model.poseStates[index].pose),
      ),
    );

    if (completed == true && mounted) {
      _model.setCompleted(index, true);
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Custom Workout Plan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TODAY'S SESSION Card ──────────────────────
              _buildTodaySessionCard(),
              const SizedBox(height: 20),

              // ── Generate Button ──────────────────────────
              _buildGenerateButton(),
              const SizedBox(height: 20),

              if (_model.poseStates.isNotEmpty) ...[
                _buildPosePlansSection(),
                const SizedBox(height: 20),
              ],

              // ── Today's Status Section ────────────────────
              _buildTodayStatusSection(),
              const SizedBox(height: 20),

              // ── Quick Tips Section ────────────────────────
              _buildQuickTipsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavWidget(
              selectedIndex: _selectedNavIndex,
              onNavTap: _handleNavTap,
              onFabPressed: _handleFabPressed,
            )
          : null,
    );
  }

  // State variable for bottom nav
  int _selectedNavIndex = 1; // Default to Workout tab

  void _handleNavTap(int index) {
    setState(() => _selectedNavIndex = index);

    if (widget.onNavTap != null) {
      widget.onNavTap!(index);
      return;
    }

    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeWidget(
            userId: widget.userId,
            fullName: widget.fullName,
            initialNavIndex: 3,
          ),
        ),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileWidget(
            initialUserId: widget.userId,
            initialFullName: widget.fullName,
          ),
        ),
      );
    }
  }

  void _handleFabPressed() {
    setState(() => _selectedNavIndex = 2);
    if (widget.onFabPressed != null) {
      widget.onFabPressed!();
    }
  }

  // [REMOVED: Old _buildBottomNav() and _navItem() - now using BottomNavWidget]

  // ── TODAY'S SESSION Card ──────────────────────────────────────
  Widget _buildTodaySessionCard() {
    final progress = _model.totalCount == 0
        ? 0.0
        : _model.completedCount / _model.totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brandDark.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S SESSION",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Workout Plans',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hi ${widget.fullName}, build a focused\n3-pose flow for today.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Poses badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_model.totalCount}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Poses',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // KPI row
          Row(
            children: [
              _buildKpiBox('${_model.totalCount}', 'Poses\nPlanned'),
              const SizedBox(width: 10),
              _buildKpiBox('${_model.completedCount}', 'Completed'),
              const SizedBox(width: 10),
              _buildKpiBox('${(progress * 100).round()}%', 'Progress'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBox(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  // ── Generate Button ───────────────────────────────────────────
  Widget _buildGenerateButton() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _model.isGenerating
              ? null
              : () async {
                  try {
                    await _model.generateWorkoutPlan();
                  } catch (e, st) {
                    debugPrint('Failed to generate workout plan: $e');
                    debugPrintStack(stackTrace: st);
                  }
                },
          icon: Icon(
            Icons.flash_on_rounded,
            size: 18,
            color: _model.isGenerating ? Colors.grey : Colors.white,
          ),
          label: Text(
            _model.isGenerating ? 'Generating...' : 'Generate Workout Plan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _model.isGenerating ? Colors.grey.shade600 : Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentPink,
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Resets daily · 3 poses per session',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textMuted,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPosePlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Poses',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_model.poseStates.length, _buildPoseCard),
      ],
    );
  }

  Widget _buildPoseCard(int index) {
    final state = _model.poseStates[index];
    final pose = state.pose;
    final categoryLabel = _model.categoryLabel(pose.category);

    Color categoryColor;
    switch (pose.category.toLowerCase()) {
      case 'warmup':
        categoryColor = const Color(0xFFFF8A65);
        break;
      case 'main':
        categoryColor = const Color(0xFFE91E63);
        break;
      case 'relaxation':
        categoryColor = const Color(0xFF26A69A);
        break;
      default:
        categoryColor = const Color(0xFF9575CD);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openPoseSession(index),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      state.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.play_circle_fill_rounded,
                      color: state.isCompleted ? Colors.green : categoryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pose.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Duration: ${pose.duration} min • ${pose.difficulty.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.isCompleted
                      ? 'Completed'
                      : 'Tap to open session video, start timer, and mark complete',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: state.isCompleted ? Colors.green : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Today's Status Section ────────────────────────────────────
  Widget _buildTodayStatusSection() {
    final total = _model.totalCount;
    final completed = _model.completedCount;
    final hasPlan = total > 0;
    final isComplete = hasPlan && completed >= total;

    final statusIcon = !hasPlan
        ? Icons.self_improvement_rounded
        : (isComplete
              ? Icons.emoji_events_rounded
              : Icons.fitness_center_rounded);
    final statusTitle = !hasPlan
        ? 'No workout yet today'
        : (isComplete ? 'Workout completed' : 'Workout in progress');
    final statusBody = !hasPlan
        ? "Tap Generate Workout Plan to create today's\n3 poses. Tomorrow starts fresh\nat zero until you generate again."
        : (isComplete
              ? 'Great job! You completed all $total poses for today.'
              : '$completed of $total poses completed. Keep going to finish today\'s plan.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Status",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
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
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _accentLight.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: 28,
                  color: _accentPink.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                statusTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusBody,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Quick Tips Section ────────────────────────────────────────
  Widget _buildQuickTipsSection() {
    final tips = ['Stay hydrated', 'Warm up first', 'Rest 60s between'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tips',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(
                  '•',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _accentPink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tip,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
