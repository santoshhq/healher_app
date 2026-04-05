import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Plans',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hi ${widget.fullName}, generate one warm-up, one main, and one relaxation pose instantly.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_model.totalCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Poses',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_model.completedCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Completed',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoseCard(int index) {
    final poseState = _model.poseStates[index];
    final pose = poseState.pose;
    final categoryColor = _categoryColor(pose.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.14),
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
              icon: const Icon(Icons.ondemand_video_rounded),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFF5EDF3);

    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF201A26),
            title: Text(
              'Custom Workout Plan',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
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
                        backgroundColor: const Color(0xFFE91E63),
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
        );
      },
    );
  }
}
