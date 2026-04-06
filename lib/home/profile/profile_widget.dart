import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../authentication/login_pages/login_widget.dart';
import '../bottom_nav_widget.dart';
import '../cycle_module/cycle_module_widget.dart';
import '../home_widget.dart';
import '../nutrition_tab/nutrition_tab_widget.dart';
import '../workouts_plans/workouts_plans_widget.dart';
import 'profile_module.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({
    this.initialUserId,
    this.initialFullName,
    this.initialEmail,
    this.showBottomNav = true,
    super.key,
  });

  final String? initialUserId;
  final String? initialFullName;
  final String? initialEmail;
  final bool showBottomNav;

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final ProfileModule _module = ProfileModule();
  int _selectedNavIndex = 4;

  @override
  void initState() {
    super.initState();
    _module.addListener(_onModuleChanged);
    _module.loadUserDetails();
  }

  @override
  void dispose() {
    _module.removeListener(_onModuleChanged);
    _module.dispose();
    super.dispose();
  }

  void _onModuleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _fullName {
    final moduleName = _module.fullName.trim();
    if (moduleName.isNotEmpty) return moduleName;
    return widget.initialFullName?.trim().isNotEmpty == true
        ? widget.initialFullName!.trim()
        : 'User';
  }

  String get _email {
    final moduleEmail = _module.email.trim();
    if (moduleEmail.isNotEmpty) return moduleEmail;
    return widget.initialEmail?.trim().isNotEmpty == true
        ? widget.initialEmail!.trim()
        : 'Not available';
  }

  String get _effectiveUserId {
    final moduleUserId = _module.userId.trim();
    if (moduleUserId.isNotEmpty) return moduleUserId;
    return widget.initialUserId?.trim().isNotEmpty == true
        ? widget.initialUserId!.trim()
        : '';
  }

  String get _firstLetter {
    final value = _fullName.trim();
    return value.isEmpty ? 'U' : value[0].toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    final ok = await _module.logout();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_module.errorMessage ?? 'Logout failed')),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginWidget()),
      (route) => false,
    );
  }

  void _showInfoDialog({required String title, required String content}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeWidget(userId: _effectiveUserId, fullName: _fullName),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutsPlansWidget(
            userId: _effectiveUserId,
            fullName: _fullName,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NutritionTabWidget()),
      );
    }
  }

  void _handleFabPressed() {
    setState(() => _selectedNavIndex = 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CycleModuleWidget(userId: _effectiveUserId, fullName: _fullName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF221A26),
          ),
        ),
      ),
      body: _module.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A112D), Color(0xFF5B1A46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFD24787),
                          child: Text(
                            _firstLetter,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fullName,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _profileTile(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: _fullName,
                  ),
                  const SizedBox(height: 10),
                  _profileTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _email,
                  ),
                  const SizedBox(height: 12),
                  _optionTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => _showInfoDialog(
                      title: 'About Us',
                      content:
                          'HealHer helps you track cycle health, workouts, and nutrition in one place.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _optionTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _showInfoDialog(
                      title: 'Terms & Conditions',
                      content:
                          'By using HealHer, you agree to app terms, privacy protections, and responsible usage.',
                    ),
                  ),
                  if ((_module.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _module.errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFC62828),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _module.isLoggingOut ? null : _confirmLogout,
                      icon: _module.isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        _module.isLoggingOut ? 'Logging out...' : 'Logout',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD24787),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF4D2DE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD24787), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8B7F8F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF221A26),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D2DE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFD24787), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF221A26),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B7F8F)),
            ],
          ),
        ),
      ),
    );
  }
}
