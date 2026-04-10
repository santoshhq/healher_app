import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // ── Design System Constants ─────────────────────────────────────
  // Colors
  static const _brandDark = Color(0xFF3A112D);
  static const _accentPink = Color(0xFFD24787);
  static const _accentLight = Color(0xFFF4D2DE);
  static const _textPrimary = Color(0xFF221A26);
  static const _textSecondary = Color(0xFF8B7F8F);
  static const _textMuted = Color(0xFFB3ABB6);
  static const _bgPage = Color(0xFFF5F0F3);
  static const _bgCard = Color(0xFFFFFFFF);

  // Success/Status Colors
  static const _successGreen = Color(0xFF4CAF50);
  static const _warningOrange = Color(0xFFFF9800);

  // Spacing Scale (8px base)
  static const _spacingXs = 4.0;
  static const _spacingSmall = 8.0;
  static const _spacingMid = 12.0;
  static const _spacingBase = 16.0;
  static const _spacingLarge = 20.0;
  static const _spacingXL = 24.0;

  // Border Radius
  static const _radiusSmall = 8.0;
  static const _radiusMid = 12.0;
  static const _radiusLarge = 16.0;
  static const _radiusXL = 20.0;

  // Shadows
  static final _shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final _shadowMid = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final _shadowLarge = [
    BoxShadow(
      color: _brandDark.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
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
        builder: (_) => PoseSessionWidget(
          pose: _model.poseStates[index].pose,
          userId: widget.userId,
          workoutDate: _model.getWorkoutDate(),
        ),
      ),
    );

    if (completed == true && mounted) {
      _model.setCompleted(index, true);
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMobileSize = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bgCard,
        surfaceTintColor: _bgCard,
        title: Text(
          'Workout Plans',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Workout Calendar',
            onPressed: _openWorkoutCalendar,
            icon: const Icon(Icons.calendar_month_rounded),
            color: _textPrimary,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _textSecondary.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            _spacingBase,
            _spacingLarge,
            _spacingBase,
            isMobileSize ? 120 : 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TODAY'S SESSION Card ──────────────────────
              _buildTodaySessionCard(),
              SizedBox(height: _spacingXL),

              // ── Generate Button ──────────────────────────
              _buildGenerateButton(),
              SizedBox(height: _spacingXL),

              if (_model.poseStates.isNotEmpty) ...[
                _buildPosePlansSection(),
                SizedBox(height: _spacingXL),
              ],

              // ── Today's Status Section ────────────────────
              _buildTodayStatusSection(),
              SizedBox(height: _spacingXL),

              // ── Quick Tips Section ────────────────────────
              _buildQuickTipsSection(),
              SizedBox(height: _spacingLarge),
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

    if (index == 1) {
      return;
    }

    if (index == 0 || index == 3 || index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeWidget(
            userId: widget.userId,
            fullName: widget.fullName,
            initialNavIndex: index,
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

  Future<void> _openWorkoutCalendar() async {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime visibleMonth = currentMonth;
    Future<Map<int, int>> monthFuture = _model.fetchMonthCompletionCounts(
      year: visibleMonth.year,
      month: visibleMonth.month,
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: _spacingBase,
                vertical: _spacingLarge,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_spacingBase),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final prevMonth = DateTime(
                              visibleMonth.year,
                              visibleMonth.month - 1,
                            );

                            final prevData = await _model
                                .fetchMonthCompletionCounts(
                                  year: prevMonth.year,
                                  month: prevMonth.month,
                                );

                            if (!context.mounted) return;

                            final hasAtLeastOneCompletedDay = prevData.values
                                .any((count) => count >= 1);

                            if (!hasAtLeastOneCompletedDay) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No completed workout days in that month.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              visibleMonth = prevMonth;
                              monthFuture = Future.value(prevData);
                            });
                          },
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            _monthTitle(visibleMonth),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              (visibleMonth.year < currentMonth.year ||
                                  (visibleMonth.year == currentMonth.year &&
                                      visibleMonth.month < currentMonth.month))
                              ? () {
                                  final nextMonth = DateTime(
                                    visibleMonth.year,
                                    visibleMonth.month + 1,
                                  );
                                  setDialogState(() {
                                    visibleMonth = nextMonth;
                                    monthFuture = _model
                                        .fetchMonthCompletionCounts(
                                          year: visibleMonth.year,
                                          month: visibleMonth.month,
                                        );
                                  });
                                }
                              : null,
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color:
                                (visibleMonth.year < currentMonth.year ||
                                    (visibleMonth.year == currentMonth.year &&
                                        visibleMonth.month <
                                            currentMonth.month))
                                ? _textPrimary
                                : _textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _spacingSmall),
                    _buildWeekdayHeader(),
                    const SizedBox(height: _spacingSmall),
                    FutureBuilder<Map<int, int>>(
                      future: monthFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final completionMap = snapshot.data ?? <int, int>{};
                        return _buildMonthGrid(visibleMonth, completionMap);
                      },
                    ),
                    const SizedBox(height: _spacingBase),
                    _buildCalendarLegend(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _monthTitle(DateTime month) {
    const names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  Widget _buildWeekdayHeader() {
    const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels
          .map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid(DateTime month, Map<int, int> completionMap) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekdayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final totalCells = firstWeekdayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final totalGridCells = rows * 7;

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - firstWeekdayOffset + 1;
              final isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;

              if (!isValidDay || cellIndex >= totalGridCells) {
                return const Expanded(child: SizedBox(height: 34));
              }

              final completedCount = completionMap[dayNumber] ?? 0;
              final bgColor = _calendarDayColor(completedCount);
              final textColor = completedCount >= 2
                  ? Colors.white
                  : _textPrimary;

              return Expanded(
                child: Container(
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _calendarDayColor(int completedCount) {
    if (completedCount >= 3) {
      return const Color(0xFF66BB6A);
    }
    if (completedCount == 2) {
      return const Color(0xFFF57C00);
    }
    if (completedCount == 1) {
      return const Color(0xFFFFCC80);
    }
    return const Color(0xFFE0E0E0);
  }

  Widget _buildCalendarLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _legendItem('None', const Color(0xFFE0E0E0)),
        _legendItem('1 Pose', const Color(0xFFFFCC80)),
        _legendItem('2 Poses', const Color(0xFFF57C00)),
        _legendItem('All Done', const Color(0xFF66BB6A)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  // [REMOVED: Old _buildBottomNav() and _navItem() - now using BottomNavWidget]

  // ── TODAY'S SESSION Card ──────────────────────────────────────
  Widget _buildTodaySessionCard() {
    final progress = _model.totalCount == 0
        ? 0.0
        : _model.completedCount / _model.totalCount;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brandDark.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(_radiusXL),
        boxShadow: _shadowLarge,
      ),
      child: Stack(
        children: [
          // Decorative background pattern
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(_spacingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Label
                Text(
                  "TODAY'S WORKOUT SESSION",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: _spacingMid),

                // Title & Description
                Text(
                  'Workout Plans',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: _spacingSmall),
                Text(
                  'Hi ${widget.fullName}, stay consistent\nwith your ${_model.totalCount} poses today.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: _spacingXL),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _spacingSmall),
                    // Progress indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_radiusSmall),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _accentPink.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _spacingXL),

                // KPI Row
                Row(
                  children: [
                    _buildKpiBox(
                      value: '${_model.completedCount}',
                      label: 'Completed',
                      icon: Icons.check_circle_rounded,
                    ),
                    SizedBox(width: _spacingLarge),
                    _buildKpiBox(
                      value: '${_model.totalCount - _model.completedCount}',
                      label: 'Remaining',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildKpiBox({
    required String value,
    required String label,
    required IconData icon,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
        vertical: _spacingBase,
        horizontal: _spacingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_radiusMid),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _accentLight.withValues(alpha: 0.8), size: 16),
              SizedBox(width: _spacingXs),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacingXs),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
    final isDisabled = _model.isGenerating || _model.isGenerateLocked;

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled
                    ? null
                    : () async {
                        try {
                          await _model.generateWorkoutPlan();
                        } catch (e, st) {
                          debugPrint('Failed to generate workout plan: $e');
                          debugPrintStack(stackTrace: st);
                          final errorMessage =
                              'Failed to generate workout plan: $e';
                          _model.stopGeneratingWithError(errorMessage);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red.shade700,
                              action: SnackBarAction(
                                label: 'Retry',
                                textColor: Colors.white,
                                onPressed: () {
                                  _model.generateWorkoutPlan();
                                },
                              ),
                            ),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(_radiusLarge),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDisabled
                          ? [Colors.grey.shade300, Colors.grey.shade400]
                          : [_accentPink, _accentPink.withValues(alpha: 0.85)],
                    ),
                    borderRadius: BorderRadius.circular(_radiusLarge),
                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color: _accentPink.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _spacingBase,
                      vertical: _spacingMid,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_model.isGenerating)
                          Transform.scale(
                            scale: 0.7,
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        SizedBox(width: _spacingSmall),
                        Text(
                          _model.isGenerating
                              ? 'Generating Plan...'
                              : (_model.isGenerateLocked
                                    ? 'Workout Plan Generated'
                                    : 'Generate Workout Plan'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _spacingSmall),
            Text(
              _model.generateLockMessage ??
                  'Resets daily · 3 poses per session',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textMuted,
                letterSpacing: -0.1,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildPosePlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Poses',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: _spacingLarge),
        ...List.generate(_model.poseStates.length, (index) {
          return _buildPoseCard(index)
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 100 * (index + 1)),
              )
              .slideY(begin: 0.1, end: 0);
        }),
      ],
    );
  }

  Widget _buildPoseCard(int index) {
    final state = _model.poseStates[index];
    final pose = state.pose;
    final categoryLabel = _model.categoryLabel(pose.category);

    Color categoryColor;
    Color categoryBgColor;
    IconData categoryIcon;

    switch (pose.category.toLowerCase()) {
      case 'warmup':
        categoryColor = const Color(0xFFFF8A65);
        categoryBgColor = const Color(0xFFFF8A65).withValues(alpha: 0.12);
        categoryIcon = Icons.local_fire_department_rounded;
        break;
      case 'main':
        categoryColor = const Color(0xFFE91E63);
        categoryBgColor = const Color(0xFFE91E63).withValues(alpha: 0.12);
        categoryIcon = Icons.self_improvement_rounded;
        break;
      case 'relaxation':
        categoryColor = const Color(0xFF26A69A);
        categoryBgColor = const Color(0xFF26A69A).withValues(alpha: 0.12);
        categoryIcon = Icons.spa_rounded;
        break;
      default:
        categoryColor = const Color(0xFF9575CD);
        categoryBgColor = const Color(0xFF9575CD).withValues(alpha: 0.12);
        categoryIcon = Icons.fitness_center_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: _spacingMid),
      child: Material(
        color: _bgCard,
        borderRadius: BorderRadius.circular(_radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(_radiusLarge),
          onTap: () => _openPoseSession(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radiusLarge),
              border: Border.all(
                color: _textSecondary.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: _shadowSmall,
            ),
            child: Padding(
              padding: const EdgeInsets.all(_spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Category Badge + Status Icon
                  Row(
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _spacingBase,
                          vertical: _spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: categoryBgColor,
                          borderRadius: BorderRadius.circular(_radiusSmall),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon, size: 14, color: categoryColor),
                            SizedBox(width: _spacingXs),
                            Text(
                              categoryLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Completion Indicator
                      if (state.isCompleted)
                        Container(
                          padding: const EdgeInsets.all(_spacingXs),
                          decoration: BoxDecoration(
                            color: _successGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: _successGreen,
                            size: 20,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(_spacingXs),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: _spacingBase),

                  // Pose Title
                  Text(
                    pose.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: _spacingSmall),

                  // Duration & Difficulty
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: _textSecondary,
                      ),
                      SizedBox(width: _spacingXs),
                      Text(
                        '${pose.duration} min',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                      SizedBox(width: _spacingBase),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _spacingSmall,
                          vertical: _spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: _textSecondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(_radiusSmall),
                        ),
                        child: Text(
                          pose.difficulty.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _spacingBase),

                  // Status Text
                  Text(
                    state.isCompleted
                        ? '✓ Completed successfully'
                        : 'Tap to open session, start timer & mark complete',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state.isCompleted ? _successGreen : _textMuted,
                    ),
                  ),
                ],
              ),
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

    Color statusColor;
    Color statusBgColor;
    Color statusLightBg;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;
    String statusBody;

    if (!hasPlan) {
      statusColor = const Color(0xFF9575CD);
      statusBgColor = statusColor.withValues(alpha: 0.12);
      statusLightBg = statusColor.withValues(alpha: 0.06);
      statusIcon = Icons.self_improvement_rounded;
      statusTitle = 'Ready to Start?';
      statusSubtitle = 'No workout yet today';
      statusBody =
          'Generate your personalized 3-pose workout to kick off your session today.';
    } else if (isComplete) {
      statusColor = _successGreen;
      statusBgColor = statusColor.withValues(alpha: 0.12);
      statusLightBg = statusColor.withValues(alpha: 0.06);
      statusIcon = Icons.emoji_events_rounded;
      statusTitle = 'Awesome Work!';
      statusSubtitle = 'Workout Completed';
      statusBody =
          'You crushed all $total poses today. Rest and recover – you\'ve earned it!';
    } else {
      statusColor = _accentPink;
      statusBgColor = statusColor.withValues(alpha: 0.12);
      statusLightBg = statusColor.withValues(alpha: 0.06);
      statusIcon = Icons.local_fire_department_rounded;
      statusTitle = 'Keep Going!';
      statusSubtitle = 'Workout in Progress';
      statusBody =
          '$completed of $total poses done. You are $completed of $total poses complete.';
    }

    final progressPercent = hasPlan ? ((completed / total) * 100).round() : 0;

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Status",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: _spacingBase),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(_radiusLarge),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: _shadowMid,
              ),
              child: Column(
                children: [
                  // Top colored header bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _spacingBase,
                      vertical: _spacingBase,
                    ),
                    decoration: BoxDecoration(
                      color: statusLightBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(_radiusLarge),
                        topRight: Radius.circular(_radiusLarge),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: statusColor.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Icon(statusIcon, size: 26, color: statusColor),
                        ),
                        SizedBox(width: _spacingBase),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                statusSubtitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(_spacingBase),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status message
                        Text(
                          statusBody,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: _spacingBase),

                        // Progress section (only show if has plan)
                        if (hasPlan) ...[
                          // Progress bar with percentage
                          Container(
                            padding: const EdgeInsets.all(_spacingBase),
                            decoration: BoxDecoration(
                              color: statusLightBg,
                              borderRadius: BorderRadius.circular(_radiusMid),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Progress label
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Session Progress',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                    Text(
                                      '$progressPercent%',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: _spacingSmall),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _radiusSmall,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: completed / total,
                                    minHeight: 8,
                                    backgroundColor: statusColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      statusColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: _spacingSmall),
                                // Completed poses
                                Text(
                                  '$completed of $total poses completed',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          // Call to action when no plan
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _spacingBase,
                              vertical: _spacingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(_radiusSmall),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: statusColor,
                                ),
                                SizedBox(width: _spacingSmall),
                                Expanded(
                                  child: Text(
                                    'Tap "Generate Workout Plan" above to start',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ── Quick Tips Section ────────────────────────────────────────
  Widget _buildQuickTipsSection() {
    final tips = [
      (
        icon: Icons.local_drink_rounded,
        title: 'Stay Hydrated',
        desc: 'Drink water before, during & after',
      ),
      (
        icon: Icons.favorite_rounded,
        title: 'Warm Up First',
        desc: 'Prepare your body for the session',
      ),
      (
        icon: Icons.bedtime_rounded,
        title: 'Rest Between',
        desc: '60 seconds recovery between poses',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tips',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: _spacingBase),
        ...tips.asMap().entries.map((entry) {
          final index = entry.key;
          final tip = entry.value;
          return Padding(
                padding: const EdgeInsets.only(bottom: _spacingBase),
                child: Container(
                  padding: const EdgeInsets.all(_spacingBase),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(_radiusLarge),
                    border: Border.all(
                      color: _textSecondary.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: _shadowSmall,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _accentPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(_radiusMid),
                        ),
                        child: Icon(tip.icon, color: _accentPink, size: 20),
                      ),
                      SizedBox(width: _spacingBase),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            SizedBox(height: _spacingXs),
                            Text(
                              tip.desc,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: _successGreen.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 250 + (index * 50)),
              )
              .slideY(begin: 0.1, end: 0);
        }),
      ],
    );
  }
}
