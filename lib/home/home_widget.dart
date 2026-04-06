import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../authentication/login_pages/login_widget.dart';
import '../authentication/services/auth_session_service.dart';
import '../core/ui/app_theme.dart';
import 'chatbot/chatbot_widget.dart';
import 'cycle_module/cycle_module_widget.dart';
import 'foodscanner/foodscanner-widget.dart';
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
  int _selectedNavIndex = 2;

  final Color primaryPink = const Color(0xFFD94F7C);
  final Color lightPink = const Color(0xFFFDE8EF);
  final Color textPrimary = const Color(0xFF1A1A1A);
  final Color textSecondary = const Color(0xFF6B6B6B);

  Future<void> _logout() async {
    await AuthSessionService().clearSession();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginWidget()),
      (route) => false,
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

  Widget _moduleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryPink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lightPink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: primaryPink),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.fullName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 20),

                    // CYCLE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: lightPink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cycle status",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Day 12 · Ovulation",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryPink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "High energy phase. Great time for workouts and productivity.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Log Today"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // KPI
                    Row(
                      children: [
                        _kpiCard(
                          label: "Hydration",
                          value: "1.2L / 2L",
                          icon: Icons.water_drop,
                        ),
                        const SizedBox(width: 8),
                        _kpiCard(
                          label: "Sleep",
                          value: "7h 45m",
                          icon: Icons.nightlight,
                        ),
                        const SizedBox(width: 8),
                        _kpiCard(
                          label: "Mood",
                          value: "Radiant",
                          icon: Icons.favorite,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle("Your Modules"),
                    const SizedBox(height: 12),

                    _moduleCard(
                      title: 'Cycle Tracker',
                      subtitle: 'Track daily symptoms',
                      icon: Icons.calendar_today,
                      onTap: () {
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
                    ),

                    const SizedBox(height: 10),

                    _moduleCard(
                      title: 'Food Scanner',
                      subtitle: 'Analyze your meals',
                      icon: Icons.document_scanner,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FoodScannerWidget(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _moduleCard(
                      title: 'Workout Planner',
                      subtitle: 'Personal fitness plans',
                      icon: Icons.fitness_center,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutsPlansWidget(fullName: widget.fullName),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _moduleCard(
                      title: 'AI Chatbot',
                      subtitle: 'Live wellness guidance',
                      icon: Icons.smart_toy_outlined,
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

                    const SizedBox(height: 10),

                    _moduleCard(
                      title: 'Symptoms Predictor',
                      subtitle: 'PCOS risk screening in slides',
                      icon: Icons.monitor_heart_outlined,
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
                  ],
                ),
              ),
            ),

            // BOTTOM NAV
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.calendar_today_outlined),
                  _navItem(2, Icons.home),
                  _navItem(3, Icons.document_scanner_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
      },
      child: Icon(
        icon,
        color: isSelected ? primaryPink : Colors.grey,
        size: 22,
      ),
    );
  }
}
