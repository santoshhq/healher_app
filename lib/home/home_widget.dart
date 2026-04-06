import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../authentication/login_pages/login_widget.dart';
import '../authentication/services/auth_session_service.dart';
import 'chatbot/chatbot_widget.dart';
import 'cycle_module/cycle_module_model.dart';
import 'cycle_module/cycle_module_widget.dart';
import 'cycle_module/services/cycle_api_service.dart';
import 'nutrition_tab/nutrition_tab_widget.dart';
import 'symtoms_predictor/predictor_widget.dart';
import 'workouts_plans/workouts_plans_widget.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({required this.userId, required this.fullName, super.key});

  final String userId;
  final String fullName;

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int _selectedNavIndex = 0;

  final Color pageBg = const Color(0xFFF5F0F3);
  final Color brandDark = const Color(0xFF3A112D);
  final Color accentPink = const Color(0xFFD24787);
  final Color textPrimary = const Color(0xFF221A26);
  final Color textSecondary = const Color(0xFF8B7F8F);

  late CycleModuleModel _cycleModel;

  int _daysUntilOvulation = 7;
  double _cycleProgress = 0.72;
  String _currentPhase = 'Follicular Phase';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cycleModel = CycleModuleModel(userId: widget.userId);
    _initializeCycleData();
  }

  Future<void> _initializeCycleData() async {
    try {
      await _cycleModel.fetchCycles();
      if (mounted) {
        _updateCycleInfo();
      }
    } catch (e) {
      // Cycle data not available, use defaults
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateCycleInfo() {
    if (_cycleModel.cycles.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final now = _normalize(DateTime.now());
    final latest = _cycleModel.cycles.last;

    // Get ovulation date
    final ovulationDate = latest.ovulationDate != null
        ? _normalize(latest.ovulationDate!)
        : _normalize(
            latest.startDate.add(
              Duration(days: (latest.cycleLength - 14).clamp(8, 25)),
            ),
          );

    // Calculate days until ovulation
    final daysUntil = ovulationDate.difference(now).inDays;
    _daysUntilOvulation = daysUntil.clamp(0, 99);

    // Calculate cycle progress
    final cycleStart = _normalize(latest.startDate);
    final daysSinceStart = now.difference(cycleStart).inDays;
    _cycleProgress = (daysSinceStart / latest.cycleLength).clamp(0.0, 1.0);

    // Determine current phase
    final periodEnd = cycleStart.add(Duration(days: latest.periodLength - 1));
    final ovulationWindowStart = ovulationDate.subtract(
      const Duration(days: 4),
    );
    final ovulationWindowEnd = ovulationDate.add(const Duration(days: 1));

    if (now.isBefore(periodEnd) || now.isAtSameMomentAs(periodEnd)) {
      _currentPhase = 'Period Phase';
    } else if (now.isBefore(ovulationWindowStart)) {
      _currentPhase = 'Follicular Phase';
    } else if (!now.isAfter(ovulationWindowEnd)) {
      _currentPhase = 'Ovulation';
    } else {
      _currentPhase = 'Luteal Phase';
    }

    setState(() => _isLoading = false);
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    _cycleModel.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthSessionService().clearSession();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginWidget()),
      (route) => false,
    );
  }

  Future<void> _openTopActions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _logout();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  String get _firstName {
    final parts = widget.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'User';
    return parts.first;
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _monthYearLabel(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  List<DateTime> _calendarWeekDays(DateTime anchor) {
    return List.generate(
      7,
      (index) => DateTime(anchor.year, anchor.month, anchor.day + (index - 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show Nutrition Tab inline when selected
    if (_selectedNavIndex == 3) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0F3),
        body: const NutritionTabWidget(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brandDark, const Color(0xFF2E0F24)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  children: [
                    _buildTopBar().animate().fadeIn(duration: 280.ms),
                    const SizedBox(height: 14),
                    _buildCalendarCard().animate().fadeIn(duration: 320.ms),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _buildMainBody().animate().fadeIn(
                        duration: 380.ms,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accentPink,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentPink.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 28,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _firstName,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                onPressed: _openTopActions,
                icon: const Icon(Icons.notifications_none_rounded),
                color: Colors.white,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x40FF6B6B), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final today = _today;
    final weekDays = _calendarWeekDays(today);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _monthYearLabel(today),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Today ${today.day}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: accentPink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (date) => _DayCell(
                    day: '${date.day}',
                    week: date == today ? 'Today' : _weekdayLabel(date),
                    isToday: date == today,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final ringSize = math.max(200.0, math.min(228.0, maxHeight * 0.48));
        final quickCardHeight = math.max(
          110.0,
          math.min(130.0, maxHeight * 0.26),
        );
        final topPadding = math.max(12.0, math.min(18.0, maxHeight * 0.05));
        final midGap = math.max(8.0, math.min(12.0, maxHeight * 0.025));
        final sectionGap = math.max(8.0, math.min(14.0, maxHeight * 0.025));

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F1F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, upper) {
                    final upperHeight = upper.maxHeight;
                    final upperCompact = upperHeight < 300;
                    final adaptiveRing = math.max(
                      176.0,
                      math.min(
                        ringSize,
                        upperHeight * (upperCompact ? 0.62 : 0.68),
                      ),
                    );
                    final showInsight = upperHeight > 240;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Center(child: _buildCycleRing(size: adaptiveRing))
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),
                        SizedBox(height: upperCompact ? 8 : midGap),
                        _MeterLines(
                          phase: _currentPhase,
                          daysUntilOvulation: _daysUntilOvulation,
                          cycleProgress: _cycleProgress,
                        ).animate().fadeIn(delay: 200.ms),
                        if (showInsight) ...[
                          const Spacer(),
                          _buildDailyInsight(
                            compact: upperCompact,
                          ).animate().fadeIn(
                            delay: 300.ms,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _sectionTitle('Quick Access'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: quickCardHeight,
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _quickCard(
                            height: quickCardHeight,
                            title: 'AI\nAssistance',
                            subtitle: 'Ask anything',
                            dark: true,
                            icon: Icons.chat_bubble_outline_rounded,
                            actionColor: const Color(0xFFE27AAE),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatbotWidget(
                                    userId: widget.userId,
                                    fullName: widget.fullName,
                                  ),
                                ),
                              );
                            },
                          ).animate().fadeIn(
                            delay: 400.ms,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          _quickCard(
                            height: quickCardHeight,
                            title: 'Early Symptoms\nDetector',
                            subtitle: 'Log today',
                            dark: false,
                            icon: Icons.search_rounded,
                            actionColor: accentPink,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PredictorWidget(
                                    fullName: widget.fullName,
                                  ),
                                ),
                              );
                            },
                          ).animate().fadeIn(
                            delay: 400.ms,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  String _getPhaseAdvice() {
    switch (_currentPhase) {
      case 'Period Phase':
        return 'Rest, stay hydrated, take iron-rich foods';
      case 'Follicular Phase':
        return 'Energy boosts! Do cardio, strength training';
      case 'Ovulation':
        return 'Peak energy! Best time for workouts';
      case 'Luteal Phase':
        return 'Listen to body, gentle yoga, extra sleep';
      default:
        return 'Keep water intake and 20 min walk';
    }
  }

  Widget _buildDailyInsight({bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        13,
        compact ? 10 : 12,
        13,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              color: accentPink,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: accentPink.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              color: accentPink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              size: compact ? 14 : 16,
              color: accentPink,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_currentPhase • Ovulation in $_daysUntilOvulation days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _getPhaseAdvice(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 9.2 : 10.2,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: accentPink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentPink.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Text(
              'On Track',
              style: GoogleFonts.plusJakartaSans(
                fontSize: compact ? 8.4 : 9,
                fontWeight: FontWeight.w700,
                color: accentPink,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required double height,
    required String title,
    required String subtitle,
    required bool dark,
    required IconData icon,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: dark
          ? Colors.white.withValues(alpha: 0.1)
          : accentPink.withValues(alpha: 0.1),
      highlightColor: dark
          ? Colors.white.withValues(alpha: 0.05)
          : accentPink.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF3D162F) : const Color(0xFFFAF9FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: dark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -18,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : actionColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, c) {
                  final veryCompact = c.maxHeight < 104;
                  final compact = c.maxHeight < 118;
                  final iconSize = veryCompact ? 22.0 : (compact ? 26.0 : 30.0);
                  final iconGlyph = veryCompact
                      ? 12.0
                      : (compact ? 14.0 : 15.0);
                  final topGap = veryCompact ? 3.0 : (compact ? 5.0 : 10.0);
                  final titleGap = veryCompact ? 1.0 : (compact ? 2.5 : 5.0);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      veryCompact ? 6 : 10,
                      14,
                      veryCompact ? 6 : 10,
                    ),
                    child: veryCompact
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : actionColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  icon,
                                  size: iconGlyph,
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : actionColor,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.replaceAll('\n', ' '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      color: dark
                                          ? Colors.white
                                          : const Color(0xFF221A26),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: actionColor,
                                        size: 9,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 8.4,
                                            fontWeight: FontWeight.w600,
                                            color: dark
                                                ? Colors.white.withValues(
                                                    alpha: 0.65,
                                                  )
                                                : const Color(0xFF8B7F8F),
                                            letterSpacing: -0.15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : actionColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  icon,
                                  size: iconGlyph,
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : actionColor,
                                ),
                              ),
                              SizedBox(height: topGap),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: compact ? 13.2 : 14.4,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: dark
                                      ? Colors.white
                                      : const Color(0xFF221A26),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: titleGap),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: actionColor,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: compact ? 9 : 9.8,
                                        fontWeight: FontWeight.w700,
                                        color: dark
                                            ? Colors.white.withValues(
                                                alpha: 0.65,
                                              )
                                            : const Color(0xFF8B7F8F),
                                        letterSpacing: -0.2,
                                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCycleRing({double size = 220}) {
    final scale = math.max(0.82, math.min(1.0, size / 220));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 176 * scale,
            height: 176 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.68),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A6B2C48),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _CycleRingPainter(progress: _cycleProgress, scale: scale),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ovulation\nin',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12 * scale,
                  letterSpacing: 0.2,
                  height: 1.2,
                  color: const Color(0xFFA99CAC),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A1730), Color(0xFF291022)],
                ).createShader(bounds),
                child: Text(
                  '$_daysUntilOvulation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 46 * scale,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21 * scale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: accentPink,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                _currentPhase,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB8ACB9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                _navItem(index: 0, icon: Icons.home_rounded, label: 'Home'),
                _navItem(
                  index: 1,
                  icon: Icons.fitness_center_rounded,
                  label: 'Workout',
                ),
                const SizedBox(width: 70),
                _navItem(
                  index: 3,
                  icon: Icons.favorite_border_rounded,
                  label: 'Nutrition',
                ),
                _navItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedNavIndex = 2);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CycleModuleWidget(
                      userId: widget.userId,
                      fullName: widget.fullName,
                    ),
                  ),
                );
              },
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentPink.withValues(alpha: 0.95), accentPink],
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: accentPink.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accentPink.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutsPlansWidget(fullName: widget.fullName),
            ),
          );
        }
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentPink.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? accentPink : const Color(0xFFB2A8B5),
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentPink : const Color(0xFFB2A8B5),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.week, this.isToday = false});

  final String day;
  final String week;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFD24787) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: const Color(0xFFD24787).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            day,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isToday ? Colors.white : const Color(0xFF6A606D),
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          week,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isToday ? const Color(0xFFD24787) : const Color(0xFFB3ABB6),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _MeterLines extends StatelessWidget {
  const _MeterLines({
    required this.phase,
    required this.daysUntilOvulation,
    required this.cycleProgress,
  });

  final String phase;
  final int daysUntilOvulation;
  final double cycleProgress;

  @override
  Widget build(BuildContext context) {
    // Calculate widths based on cycle phase
    // Follicular: ~8 days, Ovulation window: ~5 days, Luteal: ~14 days
    final follicularDays = 8;
    final ovulationWindowDays = 5;
    final lutealDays = 14;

    // Determine active line based on phase
    int activeLine = 0;
    if (phase == 'Period Phase') {
      activeLine = 0;
    } else if (phase == 'Follicular Phase') {
      activeLine = 1;
    } else if (phase == 'Ovulation') {
      activeLine = 2;
    } else {
      activeLine = 3;
    }

    // Calculate widths as percentage of cycle progress
    final baseWidth = 60.0;
    final follicularWidth =
        baseWidth * (phase == 'Follicular Phase' ? cycleProgress * 2 : 0.8);
    final ovulationWidth =
        baseWidth *
        (phase == 'Ovulation'
            ? cycleProgress * 1.5
            : daysUntilOvulation < 7
            ? 0.9
            : 0.6);
    final lutealWidth =
        baseWidth * (phase == 'Luteal Phase' ? cycleProgress * 1.2 : 0.7);

    return Row(
      children: [
        _MeterLine(
          width: follicularWidth.clamp(28.0, 88.0),
          active: activeLine == 1,
          label: 'Follicular',
        ),
        const SizedBox(width: 8),
        _MeterLine(
          width: ovulationWidth.clamp(32.0, 96.0),
          active: activeLine == 2,
          label: 'Ovulation',
        ),
        const SizedBox(width: 8),
        _MeterLine(
          width: lutealWidth.clamp(28.0, 80.0),
          active: activeLine == 3,
          label: 'Luteal',
        ),
      ],
    );
  }
}

class _MeterLine extends StatelessWidget {
  const _MeterLine({required this.width, this.active = false, this.label = ''});

  final double width;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: width,
        height: 5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: active ? const Color(0xFFD24787) : const Color(0xFFE5D9E0),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFD24787).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  const _CycleRingPainter({required this.progress, required this.scale});

  final double progress;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final mainRadius = 74 * scale;
    final innerRadius = 62 * scale;
    final mainRect = Rect.fromCircle(center: center, radius: mainRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    const startAngle = -1.5708;
    final sweep = 6.2831 * progress;

    final outerHalo = Paint()
      ..color = const Color(0x1AC74F86)
      ..strokeWidth = 16 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bgTrackPaint = Paint()
      ..color = const Color(0xFFE5D9E0)
      ..strokeWidth = 10 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [
          Color(0xFFEA84B5),
          Color(0xFFD9629A),
          Color(0xFFC74584),
          Color(0xFFEA84B5),
        ],
      ).createShader(mainRect)
      ..strokeWidth = 10 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final innerRingPaint = Paint()
      ..color = const Color(0x1FC94781)
      ..strokeWidth = 6 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(mainRect, 0, 6.2831, false, outerHalo);
    canvas.drawArc(mainRect, 0, 6.2831, false, bgTrackPaint);
    canvas.drawArc(mainRect, startAngle, sweep, false, activePaint);
    canvas.drawArc(innerRect, 0.3, 5.1, false, innerRingPaint);

    final endX = center.dx + mainRadius * math.cos(startAngle + sweep);
    final endY = center.dy + mainRadius * math.sin(startAngle + sweep);
    final endOffset = Offset(endX, endY);

    canvas.drawCircle(
      endOffset,
      8 * scale,
      Paint()..color = const Color(0x33CF4E87),
    );
    canvas.drawCircle(
      endOffset,
      4.7 * scale,
      Paint()..color = const Color(0xFFFED0E3),
    );
    canvas.drawCircle(
      endOffset,
      3.1 * scale,
      Paint()..color = const Color(0xFFD24787),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
