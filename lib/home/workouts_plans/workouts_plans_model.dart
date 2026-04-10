import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.userId,
    WorkoutPlanApiService? apiService,
    AuthSessionService? authSessionService,
  }) : _apiService = apiService ?? WorkoutPlanApiService(),
       _authSessionService = authSessionService ?? AuthSessionService();

  final String? userId;

  final WorkoutPlanApiService _apiService;
  final AuthSessionService _authSessionService;
  static const _dailyPlanCachePrefix = 'workout_plan.daily_cache';
  final Map<int, Timer> _timers = {};
  Timer? _generateUnlockTimer;
  bool _isSavingCompletion = false;

  bool isGenerating = false;
  bool isLoadingToday = false;
  bool isGenerateLocked = false;
  String? generateError;
  String? generateMessage;
  String? generateLockMessage;
  String? saveMessage;
  String? saveError;

  List<WorkoutPoseState> poseStates = [];

  int get totalCount => poseStates.length;

  int get completedCount =>
      poseStates.where((state) => state.isCompleted).length;

  String getWorkoutDate() => _currentWorkoutCycleDate();

  Future<String?> _resolveUserId() async {
    final direct = userId?.trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final session = await _authSessionService.getSession();
    final fromSession = session?.userId.trim() ?? '';
    return fromSession.isEmpty ? null : fromSession;
  }

  Future<void> loadTodayCompletedWorkout() async {
    _cancelAllTimers();
    isLoadingToday = true;
    generateError = null;
    generateMessage = null;
    saveMessage = null;
    saveError = null;
    poseStates = [];
    notifyListeners();

    final resolvedUserId = await _resolveUserId();
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      isLoadingToday = false;
      generateError = 'User session not found. Please login again.';
      notifyListeners();
      return;
    }

    final workoutDate = _currentWorkoutCycleDate();
    final todayResponse = await _apiService.getTodayCompletedWorkout(
      userId: resolvedUserId,
      workoutDate: workoutDate,
    );

    isLoadingToday = false;

    if (!todayResponse.success) {
      final cachedStates = await _readCachedPlan(
        resolvedUserId: resolvedUserId,
        workoutDate: workoutDate,
      );
      if (cachedStates.isNotEmpty) {
        poseStates = cachedStates;
        _setGenerateLockForWorkoutDate(
          workoutDate: workoutDate,
          hasWorkout: true,
        );
        generateMessage = 'Loaded your saved workout plan for today.';
        notifyListeners();
        return;
      }

      _setGenerateLockForWorkoutDate(
        workoutDate: workoutDate,
        hasWorkout: false,
      );
      generateError = todayResponse.message;
      notifyListeners();
      return;
    }

    poseStates = todayResponse.poses
        .map(
          (pose) => WorkoutPoseState(pose: pose)
            ..isCompleted =
                pose.completed ||
                todayResponse.status?.toLowerCase() == 'completed',
        )
        .toList();

    if (poseStates.isNotEmpty) {
      await _cacheCurrentPlan(
        resolvedUserId: resolvedUserId,
        workoutDate: workoutDate,
      );
    }

    if (poseStates.isEmpty) {
      final cachedStates = await _readCachedPlan(
        resolvedUserId: resolvedUserId,
        workoutDate: workoutDate,
      );
      if (cachedStates.isNotEmpty) {
        poseStates = cachedStates;
      }
    }

    _setGenerateLockForWorkoutDate(
      workoutDate: workoutDate,
      hasWorkout: poseStates.isNotEmpty || todayResponse.completedCount > 0,
    );

    generateMessage = poseStates.isEmpty
        ? 'No completed workout found for today.'
        : todayResponse.message;
    notifyListeners();
  }

  Future<void> generateWorkoutPlan() async {
    if (isGenerateLocked) {
      generateError =
          generateLockMessage ??
          'Generate Workout Plan will unlock at 1:00 AM IST.';
      notifyListeners();
      return;
    }

    isGenerating = true;
    generateError = null;
    generateMessage = null;
    saveMessage = null;
    saveError = null;
    poseStates = [];
    notifyListeners();

    final resolvedUserId = await _resolveUserId();
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      isGenerating = false;
      generateError = 'User session not found. Please login again.';
      notifyListeners();
      return;
    }

    final workoutDate = _currentWorkoutCycleDate();
    // First, try fetching today's existing plan for this user.
    final todayResponse = await _apiService.getTodayCompletedWorkout(
      userId: resolvedUserId,
      workoutDate: workoutDate,
    );

    final hasTodayPlan =
        todayResponse.success && todayResponse.poses.isNotEmpty;

    if (hasTodayPlan && todayResponse.hasCompletedWorkoutToday) {
      _cancelAllTimers();
      poseStates = todayResponse.poses
          .map((pose) => WorkoutPoseState(pose: pose)..isCompleted = true)
          .toList();
      _setGenerateLockForWorkoutDate(
        workoutDate: workoutDate,
        hasWorkout: true,
      );
      isGenerating = false;
      generateMessage = todayResponse.message;
      saveMessage = 'You already completed today\'s 3 poses.';
      notifyListeners();
      return;
    }

    if (hasTodayPlan) {
      _cancelAllTimers();
      poseStates = todayResponse.poses
          .map(
            (pose) =>
                WorkoutPoseState(pose: pose)..isCompleted = pose.completed,
          )
          .toList();

      if (poseStates.length != 3) {
        isGenerating = false;
        generateError = 'Exactly 3 yoga poses are required';
        notifyListeners();
        return;
      }

      await _cacheCurrentPlan(
        resolvedUserId: resolvedUserId,
        workoutDate: workoutDate,
      );

      isGenerating = false;

      _setGenerateLockForWorkoutDate(
        workoutDate: workoutDate,
        hasWorkout: true,
      );
      generateMessage = todayResponse.message;
      saveMessage = null;
      saveError = null;
      notifyListeners();
      return;
    }

    // If today's plan is not present, create one using user + date.
    final generatedResponse = await _apiService.getCustomPoses(
      warmupCount: 1,
      mainCount: 1,
      relaxationCount: 1,
      userId: resolvedUserId,
      workoutDate: workoutDate,
    );

    isGenerating = false;

    if (!generatedResponse.success) {
      _setGenerateLockForWorkoutDate(
        workoutDate: workoutDate,
        hasWorkout: false,
      );
      generateError = generatedResponse.message;
      notifyListeners();
      return;
    }

    if (generatedResponse.poses.length != 3) {
      _setGenerateLockForWorkoutDate(
        workoutDate: workoutDate,
        hasWorkout: false,
      );
      generateError = 'Exactly 3 yoga poses are required';
      notifyListeners();
      return;
    }

    _cancelAllTimers();
    poseStates = generatedResponse.poses
        .map((pose) => WorkoutPoseState(pose: pose))
        .toList();

    await _cacheCurrentPlan(
      resolvedUserId: resolvedUserId,
      workoutDate: workoutDate,
    );

    _setGenerateLockForWorkoutDate(workoutDate: workoutDate, hasWorkout: true);
    generateMessage = generatedResponse.message;
    saveMessage = null;
    saveError = null;
    notifyListeners();
  }

  void stopGeneratingWithError(String message) {
    isGenerating = false;
    generateError = message;
    notifyListeners();
  }

  Future<void> _saveCompletedWorkoutIfReady() async {
    if (_isSavingCompletion) return;
    if (poseStates.isEmpty) return;
    if (completedCount < totalCount) return;

    _isSavingCompletion = true;
    try {
      final resolvedUserId = await _resolveUserId();
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        saveError = 'User session not found. Please login again.';
        notifyListeners();
        return;
      }

      final workoutDate = _currentWorkoutCycleDate();
      final poses = poseStates.map((state) => state.pose).toList();
      final saveResponse = await _apiService.saveCompletedDailyWorkout(
        userId: resolvedUserId,
        workoutDate: workoutDate,
        poses: poses,
      );

      if (saveResponse.success) {
        saveError = null;
        saveMessage = saveResponse.message.isNotEmpty
            ? saveResponse.message
            : 'Daily completed poses saved';
        _setGenerateLockForWorkoutDate(
          workoutDate: workoutDate,
          hasWorkout: true,
        );
      } else {
        saveError = saveResponse.message;
      }
      notifyListeners();
    } finally {
      _isSavingCompletion = false;
    }
  }

  String _currentWorkoutCycleDate() =>
      _formatDate(_effectiveWorkoutCycleTime());

  DateTime _nowIst() {
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  DateTime _effectiveWorkoutCycleTime() {
    final nowIst = _nowIst();
    // Workout day resets at 1:00 AM IST.
    // 12:00 AM to 12:59 AM still belongs to previous workout day.
    if (nowIst.hour < 1) {
      return nowIst.subtract(const Duration(days: 1));
    }
    return nowIst;
  }

  String _dailyPlanCacheKey({
    required String resolvedUserId,
    required String workoutDate,
  }) => '$_dailyPlanCachePrefix.$resolvedUserId.$workoutDate';

  Future<void> _cacheCurrentPlan({
    required String resolvedUserId,
    required String workoutDate,
  }) async {
    if (poseStates.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final payload = poseStates
        .map(
          (state) => {
            'pose': {
              'name': state.pose.name,
              'video_url': state.pose.videoUrl,
              'category': state.pose.category,
              'duration': state.pose.duration,
              'benefits': state.pose.benefits,
              'difficulty': state.pose.difficulty,
              'tags': state.pose.tags,
              'focus': state.pose.focus,
              'completed': state.isCompleted,
            },
            'isCompleted': state.isCompleted,
          },
        )
        .toList();

    await prefs.setString(
      _dailyPlanCacheKey(
        resolvedUserId: resolvedUserId,
        workoutDate: workoutDate,
      ),
      jsonEncode(payload),
    );
  }

  Future<List<WorkoutPoseState>> _readCachedPlan({
    required String resolvedUserId,
    required String workoutDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _dailyPlanCacheKey(
        resolvedUserId: resolvedUserId,
        workoutDate: workoutDate,
      ),
    );

    if (raw == null || raw.isEmpty) {
      return const <WorkoutPoseState>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <WorkoutPoseState>[];
      }

      final states = <WorkoutPoseState>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final poseJsonRaw = map['pose'];
        if (poseJsonRaw is! Map) {
          continue;
        }
        final poseJson = Map<String, dynamic>.from(poseJsonRaw);
        final pose = WorkoutPose.fromJson(poseJson);
        final state = WorkoutPoseState(pose: pose)
          ..isCompleted = map['isCompleted'] == true || pose.completed;
        states.add(state);
      }
      return states;
    } catch (_) {
      return const <WorkoutPoseState>[];
    }
  }

  void _setGenerateLockForWorkoutDate({
    required String workoutDate,
    required bool hasWorkout,
  }) {
    _generateUnlockTimer?.cancel();

    if (!hasWorkout) {
      isGenerateLocked = false;
      generateLockMessage = null;
      return;
    }

    final dateParts = workoutDate.split('-');
    if (dateParts.length != 3) {
      isGenerateLocked = true;
      generateLockMessage =
          'Generate Workout Plan is locked for this cycle and unlocks at 1:00 AM IST.';
      return;
    }

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) {
      isGenerateLocked = true;
      generateLockMessage =
          'Generate Workout Plan is locked for this cycle and unlocks at 1:00 AM IST.';
      return;
    }

    final unlockAtIst = DateTime(year, month, day + 1, 1);
    final nowIst = _nowIst();

    if (!nowIst.isBefore(unlockAtIst)) {
      isGenerateLocked = false;
      generateLockMessage = null;
      return;
    }

    isGenerateLocked = true;
    generateLockMessage =
        'You already generated a plan for this cycle. It unlocks at 1:00 AM IST.';

    final waitDuration = unlockAtIst.difference(nowIst);
    _generateUnlockTimer = Timer(waitDuration, () {
      isGenerateLocked = false;
      generateLockMessage = null;
      loadTodayCompletedWorkout();
      notifyListeners();
    });
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
      if (completedCount == totalCount) {
        unawaited(_saveCompletedWorkoutIfReady());
      }
    }

    unawaited(() async {
      final resolvedUserId = await _resolveUserId();
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        return;
      }
      await _cacheCurrentPlan(
        resolvedUserId: resolvedUserId,
        workoutDate: _currentWorkoutCycleDate(),
      );
    }());

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
    _generateUnlockTimer?.cancel();
    super.dispose();
  }
}
