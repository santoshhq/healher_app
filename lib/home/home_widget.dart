import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../authentication/login_pages/login_widget.dart';
import '../authentication/services/auth_session_service.dart';
import 'chatbot/chatbot_widget.dart';
import 'cycle_module/cycle_module_widget.dart';
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4D2DE),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 30,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$_firstName',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 17,
                onPressed: _openTopActions,
                icon: const Icon(Icons.notifications_none_rounded),
                color: Colors.white,
              ),
              Positioned(
                top: 11,
                right: 10,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7579A),
                    shape: BoxShape.circle,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120D0018),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _monthYearLabel(today),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Today ${today.day}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: accentPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
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
        final ringSize = math.max(200.0, math.min(228.0, maxHeight * 0.49));
        final quickCardHeight = math.max(
          116.0,
          math.min(132.0, maxHeight * 0.27),
        );
        final topPadding = math.max(10.0, math.min(16.0, maxHeight * 0.04));
        final midGap = math.max(6.0, math.min(10.0, maxHeight * 0.02));
        final sectionGap = math.max(6.0, math.min(10.0, maxHeight * 0.022));

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F1F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
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
                        upperHeight * (upperCompact ? 0.64 : 0.70),
                      ),
                    );
                    final showInsight = upperHeight > 232;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Center(child: _buildCycleRing(size: adaptiveRing)),
                        SizedBox(height: upperCompact ? 6 : midGap),
                        const _MeterLines(),
                        if (showInsight) ...[
                          const Spacer(),
                          _buildDailyInsight(compact: upperCompact),
                        ],
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: sectionGap),
              _sectionTitle('Quick Access'),
              const SizedBox(height: 10),
              SizedBox(
                height: quickCardHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _quickCard(
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
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickCard(
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
                              builder: (_) =>
                                  PredictorWidget(fullName: widget.fullName),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyInsight({bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, compact ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF9F0F5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEDFE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D0018),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              color: accentPink,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF8DDEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              size: compact ? 14 : 16,
              color: accentPink,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Today Snapshot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Keep water intake and 20 min walk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 9.0 : 9.8,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 8,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9E4ED),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'On Track',
              style: GoogleFonts.plusJakartaSans(
                fontSize: compact ? 8.2 : 8.8,
                fontWeight: FontWeight.w700,
                color: accentPink,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF3D162F) : const Color(0xFFF8F7F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF0E7ED),
          ),
          boxShadow: dark
              ? const [
                  BoxShadow(
                    color: Color(0x160F0219),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark
                      ? Colors.black.withValues(alpha: 0.16)
                      : const Color(0xFFF0E8ED),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, c) {
                  final veryCompact = c.maxHeight < 108;
                  final compact = c.maxHeight < 122;
                  final iconSize = veryCompact ? 20.0 : (compact ? 24.0 : 28.0);
                  final iconGlyph = veryCompact
                      ? 11.0
                      : (compact ? 13.0 : 14.0);
                  final topGap = veryCompact ? 2.0 : (compact ? 4.0 : 8.0);
                  final titleGap = veryCompact ? 0.0 : (compact ? 2.0 : 4.0);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      veryCompact ? 5 : 8,
                      12,
                      veryCompact ? 5 : 8,
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
                                      ? const Color(0xFF5A2444)
                                      : const Color(0xFFFADCE8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  size: iconGlyph,
                                  color: dark
                                      ? const Color(0xFFF7C5DC)
                                      : accentPink,
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
                                      fontSize: 11.8,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                      color: dark ? Colors.white : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '+',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: actionColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 8.2,
                                            fontWeight: FontWeight.w600,
                                            color: dark
                                                ? const Color(0xFFE6B6C9)
                                                : const Color(0xFFB14876),
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
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF5A2444)
                                      : const Color(0xFFFADCE8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  size: iconGlyph,
                                  color: dark
                                      ? const Color(0xFFF7C5DC)
                                      : accentPink,
                                ),
                              ),
                              SizedBox(height: topGap),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: compact ? 13.0 : 14.0,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? Colors.white : textPrimary,
                                ),
                              ),
                              SizedBox(height: titleGap),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    '+',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: actionColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: compact ? 8.8 : 9.4,
                                        fontWeight: FontWeight.w600,
                                        color: dark
                                            ? const Color(0xFFE6B6C9)
                                            : const Color(0xFFB14876),
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
    const double progress = 0.72;
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
            painter: _CycleRingPainter(progress: progress, scale: scale),
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
                  '7',
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
                'Follicular Phase',
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
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -5),
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
                const SizedBox(width: 68),
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
            top: -8,
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
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE56AA7), Color(0xFFD24787)],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40B93673),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
        // Nutrition (index 3) now shows as a tab inline - no navigation needed
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? accentPink : const Color(0xFFB2A8B5),
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentPink : const Color(0xFFB2A8B5),
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
          width: 30,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFF5DCE6) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            day,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? const Color(0xFFC54882)
                  : const Color(0xFF6A606D),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          week,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: isToday ? const Color(0xFFC54882) : const Color(0xFFB3ABB6),
          ),
        ),
      ],
    );
  }
}

class _MeterLines extends StatelessWidget {
  const _MeterLines();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _MeterLine(width: 52, active: true),
        SizedBox(width: 8),
        _MeterLine(width: 84),
        SizedBox(width: 8),
        _MeterLine(width: 64),
      ],
    );
  }
}

class _MeterLine extends StatelessWidget {
  const _MeterLine({required this.width, this.active = false});

  final double width;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: active ? const Color(0xFFDC7EAA) : const Color(0xFFE7DFE4),
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
