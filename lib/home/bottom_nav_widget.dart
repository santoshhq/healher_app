import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavTap;
  final VoidCallback onFabPressed;

  const BottomNavWidget({
    required this.selectedIndex,
    required this.onNavTap,
    required this.onFabPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const accentPink = Color(0xFFD24787);

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
                _navItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => onNavTap(0),
                  accentPink: accentPink,
                ),
                _navItem(
                  index: 1,
                  icon: Icons.fitness_center_rounded,
                  label: 'Workout',
                  isSelected: selectedIndex == 1,
                  onTap: () => onNavTap(1),
                  accentPink: accentPink,
                ),
                const SizedBox(width: 70),
                _navItem(
                  index: 3,
                  icon: Icons.favorite_border_rounded,
                  label: 'Nutrition',
                  isSelected: selectedIndex == 3,
                  onTap: () => onNavTap(3),
                  accentPink: accentPink,
                ),
                _navItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 4,
                  onTap: () => onNavTap(4),
                  accentPink: accentPink,
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: Semantics(
              label: 'Open cycle module',
              hint: 'Double tap to open cycle tracking',
              button: true,
              onTap: onFabPressed,
              child: Tooltip(
                message: 'Open cycle module',
                child: GestureDetector(
                  onTap: onFabPressed,
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentPink.withValues(alpha: 0.95),
                          accentPink,
                        ],
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
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
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
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentPink,
  }) {
    return SizedBox(
      width: 64,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        onTap: onTap,
        child: GestureDetector(
          onTap: onTap,
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
      ),
    );
  }
}

