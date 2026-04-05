import 'dart:async';

import 'package:flutter/material.dart';

import '../../authentication/services/auth_session_service.dart';
import 'services/workout_plan_api_service.dart';

class WorkoutPoseState {
  WorkoutPoseState({required this.pose})
    : remainingSeconds = 300,
      isRunning = false,
      isCompleted = false;

  final WorkoutPose pose;
  int remainingSeconds;
  bool isRunning;
  bool isCompleted;
}

class WorkoutsPlansModel extends ChangeNotifier {
  WorkoutsPlansModel({
    WorkoutPlanApiService? apiService,
    AuthSessionService? authSessionService,
  }) : _apiService = apiService ?? WorkoutPlanApiService(),
       _authSessionService = authSessionService ?? AuthSessionService();

  final WorkoutPlanApiService _apiService;
  final AuthSessionService _authSessionService;
  final Map<int, Timer> _timers = {};

  bool isGenerating = false;
  String? generateError;
  String? generateMessage;
  String? saveMessage;
  String? saveError;

  List<WorkoutPoseState> poseStates = [];

  int get totalCount => poseStates.length;

  int get completedCount =>
      poseStates.where((state) => state.isCompleted).length;

  Future<void> generateWorkoutPlan() async {
    _cancelAllTimers();
    isGenerating = true;
    generateError = null;
    generateMessage = null;
    saveMessage = null;
    saveError = null;
    poseStates = [];
    notifyListeners();

    final session = await _authSessionService.getSession();
    if (session == null || session.userId.trim().isEmpty) {
      isGenerating = false;
      generateError = 'User session not found. Please login again.';
      notifyListeners();
      return;
    }

    final todayResponse = await _apiService.getTodayCompletedWorkout(
      userId: session.userId,
    );

    if (todayResponse.success && todayResponse.hasCompletedWorkoutToday) {
      poseStates = todayResponse.poses
          .map((pose) => WorkoutPoseState(pose: pose)..isCompleted = true)
          .toList();
      isGenerating = false;
      generateMessage = todayResponse.message;
      saveMessage = 'You already completed today\'s 3 poses.';
      notifyListeners();
      return;
    }

    final response = await _apiService.getCustomPoses(
      warmupCount: 1,
      mainCount: 1,
      relaxationCount: 1,
    );

    isGenerating = false;

    if (!response.success) {
      generateError = response.message;
      notifyListeners();
      return;
    }

    if (response.poses.length != 3) {
      generateError = 'Exactly 3 yoga poses are required';
      notifyListeners();
      return;
    }

    final workoutDate = _formatDate(DateTime.now());
    final saveResponse = await _apiService.saveCompletedDailyWorkout(
      userId: session.userId,
      workoutDate: workoutDate,
      poses: response.poses,
    );

    poseStates = response.poses
        .map((pose) => WorkoutPoseState(pose: pose))
        .toList();

    if (poseStates.isEmpty) {
      generateError = 'No poses found for the requested plan.';
    } else {
      generateMessage = response.message;
      saveMessage = saveResponse.success
          ? (saveResponse.message.isNotEmpty
                ? saveResponse.message
                : 'Daily completed poses saved')
          : null;
      saveError = saveResponse.success ? null : saveResponse.message;
    }
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void startTimer(int index) {
    if (!_validIndex(index)) {
      return;
    }

    final state = poseStates[index];
    if (state.isCompleted) {
      return;
    }

    _timers[index]?.cancel();
    state.isRunning = true;

    _timers[index] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_validIndex(index)) {
        timer.cancel();
        return;
      }

      final current = poseStates[index];
      if (current.remainingSeconds <= 1) {
        current.remainingSeconds = 0;
        current.isRunning = false;
        current.isCompleted = true;
        timer.cancel();
        _timers.remove(index);
        notifyListeners();
        return;
      }

      current.remainingSeconds -= 1;
      notifyListeners();
    });

    notifyListeners();
  }

  void pauseTimer(int index) {
    if (!_validIndex(index)) {
      return;
    }

    _timers[index]?.cancel();
    _timers.remove(index);
    poseStates[index].isRunning = false;
    notifyListeners();
  }

  void resetTimer(int index) {
    if (!_validIndex(index)) {
      return;
    }

    _timers[index]?.cancel();
    _timers.remove(index);

    final state = poseStates[index];
    state.remainingSeconds = 300;
    state.isRunning = false;
    state.isCompleted = false;
    notifyListeners();
  }

  void setCompleted(int index, bool value) {
    if (!_validIndex(index)) {
      return;
    }

    final state = poseStates[index];
    state.isCompleted = value;

    if (value) {
      _timers[index]?.cancel();
      _timers.remove(index);
      state.isRunning = false;
    }

    notifyListeners();
  }

  String formatTimer(int remainingSeconds) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String categoryLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'warmup':
        return 'Warm-up';
      case 'main':
        return 'Main Set';
      case 'relaxation':
        return 'Relaxation';
      default:
        return 'Pose';
    }
  }

  bool _validIndex(int index) => index >= 0 && index < poseStates.length;

  void _cancelAllTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}
