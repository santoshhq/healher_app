import 'package:flutter/material.dart';

import 'services/cycle_api_service.dart';

class CycleModuleModel extends ChangeNotifier {
  CycleModuleModel({required String userId, CycleApiService? apiService})
    : _apiService = apiService ?? CycleApiService() {
    userIdController.text = userId;
  }

  final CycleApiService _apiService;

  final TextEditingController userIdController = TextEditingController();
  final TextEditingController cycleLengthController = TextEditingController(
    text: '28',
  );
  final TextEditingController periodLengthController = TextEditingController(
    text: '5',
  );
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController sleepController = TextEditingController(
    text: '7.5',
  );
  final TextEditingController waterController = TextEditingController(
    text: '2.5',
  );

  DateTime cycleStartDate = DateTime.now();
  DateTime? cycleEndDate;
  DateTime logDate = DateTime.now();

  String selectedFlow = 'medium';
  String selectedMood = 'normal';
  bool didExercise = true;

  bool isSubmittingCycle = false;
  bool isSubmittingLog = false;
  bool isFetchingCycles = false;
  bool isFetchingLogs = false;

  String? addCycleMessage;
  String? addCycleError;
  String? addLogMessage;
  String? addLogError;
  String? fetchCyclesError;
  String? fetchLogsError;

  List<CycleRecord> cycles = [];
  List<DailyLogRecord> dailyLogs = [];

  void setCycleStartDate(DateTime value) {
    cycleStartDate = value;
    notifyListeners();
  }

  void setCycleEndDate(DateTime? value) {
    cycleEndDate = value;
    notifyListeners();
  }

  void setLogDate(DateTime value) {
    logDate = value;
    notifyListeners();
  }

  void setFlow(String value) {
    selectedFlow = value;
    notifyListeners();
  }

  void setMood(String value) {
    selectedMood = value;
    notifyListeners();
  }

  void setExercise(bool value) {
    didExercise = value;
    notifyListeners();
  }

  Future<bool> submitCycle() async {
    final userId = userIdController.text.trim();
    final cycleLength = int.tryParse(cycleLengthController.text.trim());
    final periodLength = int.tryParse(periodLengthController.text.trim());

    if (userId.isEmpty) {
      addCycleError = 'User ID is required';
      notifyListeners();
      return false;
    }

    if (cycleLength == null || cycleLength <= 0) {
      addCycleError = 'Cycle length must be a valid number';
      notifyListeners();
      return false;
    }

    if (periodLength == null || periodLength <= 0) {
      addCycleError = 'Period length must be a valid number';
      notifyListeners();
      return false;
    }

    isSubmittingCycle = true;
    addCycleError = null;
    addCycleMessage = null;
    notifyListeners();

    final response = await _apiService.addCycle(
      userId: userId,
      startDate: cycleStartDate,
      endDate: cycleEndDate,
      cycleLength: cycleLength,
      periodLength: periodLength,
    );

    isSubmittingCycle = false;

    if (response.success) {
      addCycleMessage = response.message;
      addCycleError = null;
      notifyListeners();
      return true;
    }

    addCycleError = response.message;
    addCycleMessage = null;
    notifyListeners();
    return false;
  }

  Future<bool> submitDailyLog() async {
    final userId = userIdController.text.trim();
    final sleep = double.tryParse(sleepController.text.trim());
    final water = double.tryParse(waterController.text.trim());

    if (userId.isEmpty) {
      addLogError = 'User ID is required';
      notifyListeners();
      return false;
    }

    if (sleep == null || sleep < 0) {
      addLogError = 'Sleep hours must be a valid number';
      notifyListeners();
      return false;
    }

    if (water == null || water < 0) {
      addLogError = 'Water intake must be a valid number';
      notifyListeners();
      return false;
    }

    final symptoms = symptomsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    isSubmittingLog = true;
    addLogError = null;
    addLogMessage = null;
    notifyListeners();

    final response = await _apiService.addDailyLog(
      userId: userId,
      date: _formatDate(logDate),
      flow: selectedFlow,
      symptoms: symptoms,
      mood: selectedMood,
      sleep: sleep,
      water: water,
      exercise: didExercise,
    );

    isSubmittingLog = false;

    if (response.success) {
      addLogMessage = response.message;
      addLogError = null;
      await fetchDailyLogs();
      notifyListeners();
      return true;
    }

    addLogError = response.message;
    addLogMessage = null;
    notifyListeners();
    return false;
  }

  Future<void> fetchCycles() async {
    final userId = userIdController.text.trim();
    if (userId.isEmpty) {
      fetchCyclesError = 'User ID is required to fetch cycles';
      notifyListeners();
      return;
    }

    isFetchingCycles = true;
    fetchCyclesError = null;
    notifyListeners();

    final response = await _apiService.getCyclesByUserId(userId);

    isFetchingCycles = false;

    if (response.success) {
      cycles = response.cycles;
      fetchCyclesError = null;
      notifyListeners();
      return;
    }

    fetchCyclesError = response.message;
    notifyListeners();
  }

  Future<void> fetchDailyLogs() async {
    final userId = userIdController.text.trim();
    if (userId.isEmpty) {
      fetchLogsError = 'User ID is required to fetch daily logs';
      notifyListeners();
      return;
    }

    isFetchingLogs = true;
    fetchLogsError = null;
    notifyListeners();

    final response = await _apiService.getDailyLogsByUserId(userId);

    isFetchingLogs = false;

    if (response.success) {
      dailyLogs = response.logs;
      fetchLogsError = null;
      notifyListeners();
      return;
    }

    fetchLogsError = response.message;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  void dispose() {
    userIdController.dispose();
    cycleLengthController.dispose();
    periodLengthController.dispose();
    symptomsController.dispose();
    sleepController.dispose();
    waterController.dispose();
    super.dispose();
  }
}
