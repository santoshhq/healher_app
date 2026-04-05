import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../authentication/services/auth_session_service.dart';
import '../authentication/login_pages/login_widget.dart';
import 'cycle_module/cycle_module_widget.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({required this.userId, required this.fullName, super.key});

  final String userId;
  final String fullName;

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int _selectedNavIndex = 2;

  Future<void> _logout() async {
    await AuthSessionService().clearSession();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginWidget()),
      (route) => false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1D1B20),
      ),
    );
  }

  Widget _buildVitalCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF97939C),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1B20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required Color color,
    required Color accent,
    required String category,
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required IconData trailingIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, size: 18, color: const Color(0xFF1D1B20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C6774),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C6774),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(trailingIcon, size: 16, color: const Color(0xFF1D1B20)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFE91E63);
    const Color background = Color(0xFFF8F2F5);
    const Color textSecondary = Color(0xFF827D89);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Good Morning, ${widget.fullName}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1B20),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _logout,
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How are you feeling today?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 112,
                            width: 112,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 112,
                                  width: 112,
                                  child: CircularProgressIndicator(
                                    value: 0.38,
                                    strokeWidth: 4,
                                    backgroundColor: const Color(0xFFF3E8EE),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFC5005A),
                                        ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'DAY',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        letterSpacing: 0.6,
                                        color: const Color(0xFF827D89),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '12',
                                      style: GoogleFonts.poppins(
                                        fontSize: 38,
                                        height: 1,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1D1B20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ovulation phase',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1B20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your energy levels are peaking. Perfect time for creative tasks!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
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
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Log Symptoms',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Daily Vitals'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildVitalCard(
                          title: 'MOOD',
                          value: 'Radiant',
                          icon: Icons.sentiment_satisfied_alt,
                          iconColor: const Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 8),
                        _buildVitalCard(
                          title: 'SYMPTOMS',
                          value: 'Mild Cramps',
                          icon: Icons.bolt,
                          iconColor: const Color(0xFF00A572),
                        ),
                        const SizedBox(width: 8),
                        _buildVitalCard(
                          title: 'WATER',
                          value: '1.2L / 2L',
                          icon: Icons.water_drop,
                          iconColor: const Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 8),
                        _buildVitalCard(
                          title: 'SLEEP',
                          value: '7h 45m',
                          icon: Icons.nightlight_round,
                          iconColor: const Color(0xFF3949AB),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle("Today's Recommendations"),
                    const SizedBox(height: 10),
                    _buildRecommendationCard(
                      color: const Color(0xFFD7F2EA),
                      accent: const Color(0xFF41C8A6),
                      category: 'FITNESS',
                      title: 'Morning Flow Yoga',
                      subtitle: '15 mins • Light Intensity',
                      leadingIcon: Icons.self_improvement,
                      trailingIcon: Icons.play_arrow_rounded,
                    ),
                    _buildRecommendationCard(
                      color: const Color(0xFFFFE7EC),
                      accent: const Color(0xFFF7A8B8),
                      category: 'NUTRITION',
                      title: 'Quinoa Salad',
                      subtitle: 'PCOS-friendly • High Protein',
                      leadingIcon: Icons.restaurant_menu,
                      trailingIcon: Icons.arrow_forward_rounded,
                    ),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15202B), Color(0xFF2A2F3A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -28,
                            bottom: -28,
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            top: 14,
                            child: Icon(
                              Icons.psychology_alt,
                              size: 18,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mindful Moments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Explore techniques to reduce cortisol and improve cycle regularity through breathwork.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.85),
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
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF0E8EC))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBottomNavItem(
                    index: 0,
                    icon: Icons.calendar_today_outlined,
                    label: 'Tracker',
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
                  _buildBottomNavItem(
                    index: 1,
                    icon: Icons.favorite_border,
                    label: 'Health',
                  ),
                  _buildBottomNavItem(
                    index: 2,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _buildBottomNavItem(
                    index: 3,
                    icon: Icons.document_scanner_outlined,
                    label: 'Scanner',
                  ),
                  _buildBottomNavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
        if (onTap != null) {
          onTap();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFEDF4) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFFE91E63)
                  : const Color(0xFF9A95A1),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFE91E63)
                  : const Color(0xFF9A95A1),
            ),
          ),
        ],
      ),
    );
  }
}
