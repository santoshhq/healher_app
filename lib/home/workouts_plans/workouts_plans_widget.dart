import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/app_theme.dart';

import 'pose_session_widget.dart';
import 'workouts_plans_model.dart';

class WorkoutsPlansWidget extends StatefulWidget {
  const WorkoutsPlansWidget({required this.fullName, super.key});

  final String fullName;

  @override
  State<WorkoutsPlansWidget> createState() => _WorkoutsPlansWidgetState();
}

class _WorkoutsPlansWidgetState extends State<WorkoutsPlansWidget> {
  late final WorkoutsPlansModel _model;

  Future<void> _openPoseSession(int index) async {
    final poseState = _model.poseStates[index];
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PoseSessionWidget(pose: poseState.pose),
      ),
    );

    if (completed == true) {
      _model.setCompleted(index, true);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = WorkoutsPlansModel();
    _model.loadTodayCompletedWorkout();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'warmup':
        return const Color(0xFFFF8A65);
      case 'main':
        return const Color(0xFFE91E63);
      case 'relaxation':
        return const Color(0xFF26A69A);
      default:
        return const Color(0xFF9575CD);
    }
  }

  Widget _buildHeaderCard() {
    final progress = _model.totalCount == 0
        ? 0.0
        : _model.completedCount / _model.totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF231129), Color(0xFF572C66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Plans',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hi ${widget.fullName}, build a focused 3-pose flow for today.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7CFFD5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _headerKpi('${_model.totalCount}', 'Poses Planned'),
                  const SizedBox(width: 8),
                  _headerKpi('${_model.completedCount}', 'Completed'),
                  const SizedBox(width: 8),
                  _headerKpi('${(progress * 100).round()}%', 'Progress'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerKpi(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoseCard(int index) {
    final poseState = _model.poseStates[index];
    final pose = poseState.pose;
    final categoryColor = _categoryColor(pose.category);

    final isAlt = index.isOdd;

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAlt
                  ? categoryColor.withValues(alpha: 0.28)
                  : const Color(0xFFEFE7F3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAlt
                            ? [
                                categoryColor.withValues(alpha: 0.18),
                                categoryColor.withValues(alpha: 0.08),
                              ]
                            : [
                                categoryColor.withValues(alpha: 0.14),
                                categoryColor.withValues(alpha: 0.14),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _model.categoryLabel(pose.category),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    poseState.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.timer_outlined,
                    color: poseState.isCompleted
                        ? const Color(0xFF2E7D32)
                        : categoryColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                pose.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Suggested duration: ${pose.duration} min',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF6F6A78),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openPoseSession(index),
                  icon: Icon(
                    isAlt
                        ? Icons.movie_filter_rounded
                        : Icons.ondemand_video_rounded,
                  ),
                  label: Text(
                    'Open Pose Session',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 65).ms, duration: 320.ms)
        .slideY(begin: 0.06, duration: 320.ms);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppTheme.brandInk,
            title: Text(
              'Custom Workout Plan',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Container(
            decoration: AppTheme.pageBackgroundDecoration(),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _model.isGenerating ||
                                _model.isLoadingToday ||
                                _model.isGenerateLocked
                            ? null
                            : _model.generateWorkoutPlan,
                        icon: (_model.isGenerating || _model.isLoadingToday)
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _model.isGenerateLocked
                                    ? Icons.lock_clock_rounded
                                    : Icons.auto_awesome_rounded,
                              ),
                        label: Text(
                          _model.isLoadingToday
                              ? 'Loading today\'s plan...'
                              : _model.isGenerating
                              ? 'Generating...'
                              : _model.isGenerateLocked
                              ? 'Today Workout Done '
                              : 'Generate Workout Plan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    if (_model.generateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _model.generateError!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_model.generateMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _model.generateMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF4D4657),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (_model.generateLockMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _model.generateLockMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF6F6978),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_model.saveError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _model.saveError!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_model.saveMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _model.saveMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_model.poseStates.isEmpty &&
                        !_model.isGenerating &&
                        !_model.isLoadingToday)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No completed workout found for today. Tap "Generate Workout Plan" to create today\'s 3 poses. Tomorrow starts fresh at zero until you generate again.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6F6978),
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        _model.poseStates.length,
                        (index) => _buildPoseCard(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
