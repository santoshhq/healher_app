import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiStatus {
  const ApiStatus({required this.success, required this.message});

  final bool success;
  final String message;
}

class CycleRecord {
  const CycleRecord({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.cycleLength,
    required this.periodLength,
    this.predictedNext,
    this.ovulationDate,
    this.createdAt,
    this.timezoneOffsetMinutes,
    this.entryType,
    this.isConfirmed,
    this.notes,
    this.status,
  });

  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int cycleLength;
  final int periodLength;
  final DateTime? predictedNext;
  final DateTime? ovulationDate;
  final DateTime? createdAt;
  final int? timezoneOffsetMinutes;
  final String? entryType;
  final bool? isConfirmed;
  final String? notes;
  final String? status;

  factory CycleRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      return DateTime.tryParse(value.toString());
    }

    return CycleRecord(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      startDate: parseDate(json['startDate']) ?? DateTime.now(),
      endDate: parseDate(json['endDate']),
      cycleLength: int.tryParse(json['cycleLength']?.toString() ?? '0') ?? 0,
      periodLength: int.tryParse(json['periodLength']?.toString() ?? '0') ?? 0,
      predictedNext: parseDate(json['predictedNext']),
      ovulationDate: parseDate(json['ovulationDate']),
      createdAt: parseDate(json['createdAt']),
      timezoneOffsetMinutes: int.tryParse(
        json['timezoneOffsetMinutes']?.toString() ?? '',
      ),
      entryType: json['entryType']?.toString(),
      isConfirmed: json['isConfirmed'] == true,
      notes: json['notes']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class CycleConfidence {
  const CycleConfidence({
    required this.raw,
    this.level,
    this.score,
    this.reason,
  });

  final Map<String, dynamic> raw;
  final String? level;
  final double? score;
  final String? reason;

  factory CycleConfidence.fromJson(Map<String, dynamic> json) {
    return CycleConfidence(
      raw: json,
      level: json['level']?.toString() ?? json['confidenceLevel']?.toString(),
      score: double.tryParse(json['score']?.toString() ?? ''),
      reason: json['reason']?.toString() ?? json['message']?.toString(),
    );
  }
}

class CycleSummary {
  const CycleSummary({
    required this.raw,
    this.currentCycleStart,
    this.predictedNextPeriod,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.currentPhase,
    this.phaseRule,
    this.daysSinceLastPeriod,
    this.cycleLength,
    this.periodLength,
    this.confidence,
  });

  final Map<String, dynamic> raw;
  final DateTime? currentCycleStart;
  final DateTime? predictedNextPeriod;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final String? currentPhase;
  final String? phaseRule;
  final int? daysSinceLastPeriod;
  final int? cycleLength;
  final int? periodLength;
  final CycleConfidence? confidence;

  factory CycleSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return CycleSummary(
      raw: json,
      currentCycleStart: parseDate(
        json['currentCycleStart'] ?? json['cycleStart'] ?? json['startDate'],
      ),
      predictedNextPeriod: parseDate(
        json['predictedNextPeriod'] ??
            json['predictedNext'] ??
            json['nextPeriodDate'],
      ),
      ovulationDate: parseDate(json['ovulationDate']),
      fertileWindowStart: parseDate(json['fertileWindowStart']),
      fertileWindowEnd: parseDate(json['fertileWindowEnd']),
      currentPhase:
          json['currentPhase']?.toString() ?? json['phase']?.toString(),
      phaseRule: json['phaseRule']?.toString(),
      daysSinceLastPeriod: int.tryParse(
        json['daysSinceLastPeriod']?.toString() ?? '',
      ),
      cycleLength: int.tryParse(json['cycleLength']?.toString() ?? ''),
      periodLength: int.tryParse(json['periodLength']?.toString() ?? ''),
      confidence: json['confidence'] is Map<String, dynamic>
          ? CycleConfidence.fromJson(json['confidence'] as Map<String, dynamic>)
          : json['confidence'] is Map
          ? CycleConfidence.fromJson(
              Map<String, dynamic>.from(json['confidence'] as Map),
            )
          : null,
    );
  }
}

class CycleListResponse {
  const CycleListResponse({
    required this.success,
    required this.message,
    required this.cycles,
    this.currentCycleSummary,
    this.predictionConfidence,
  });

  final bool success;
  final String message;
  final List<CycleRecord> cycles;
  final CycleSummary? currentCycleSummary;
  final CycleConfidence? predictionConfidence;
}

class AddCycleResponse {
  const AddCycleResponse({
    required this.success,
    required this.message,
    this.savedCycle,
    this.currentCycleSummary,
    this.predictionConfidence,
  });

  final bool success;
  final String message;
  final CycleRecord? savedCycle;
  final CycleSummary? currentCycleSummary;
  final CycleConfidence? predictionConfidence;
}

class MonthCalendarDay {
  const MonthCalendarDay({
    required this.date,
    required this.status,
    this.isPeriodDay = false,
    this.isPredictedPeriodDay = false,
    this.isFertileWindowDay = false,
    this.isOvulationDay = false,
    this.count,
    this.raw = const {},
  });

  final DateTime date;
  final String status;
  final bool isPeriodDay;
  final bool isPredictedPeriodDay;
  final bool isFertileWindowDay;
  final bool isOvulationDay;
  final int? count;
  final Map<String, dynamic> raw;

  factory MonthCalendarDay.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return MonthCalendarDay(
      date: parseDate(json['date']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'normal_day',
      isPeriodDay:
          json['isPeriodDay'] == true ||
          json['status']?.toString() == 'period_day',
      isPredictedPeriodDay:
          json['isPredictedPeriodDay'] == true ||
          json['status']?.toString() == 'predicted_period_day',
      isFertileWindowDay:
          json['isFertileWindowDay'] == true ||
          json['status']?.toString() == 'fertile_window_day',
      isOvulationDay:
          json['isOvulationDay'] == true ||
          json['status']?.toString() == 'ovulation_day',
      count: int.tryParse(json['count']?.toString() ?? ''),
      raw: json,
    );
  }
}

class MonthCalendarResponse {
  const MonthCalendarResponse({
    required this.success,
    required this.message,
    required this.days,
    this.currentCycleSummary,
    this.aggregateCounts = const {},
  });

  final bool success;
  final String message;
  final List<MonthCalendarDay> days;
  final CycleSummary? currentCycleSummary;
  final Map<String, int> aggregateCounts;
}

class MonthlyDailyLogSummaryResponse {
  const MonthlyDailyLogSummaryResponse({
    required this.success,
    required this.message,
    required this.userId,
    required this.count,
    required this.logs,
    this.flowCounts = const {},
    this.averageSleep,
    this.averageWater,
    this.exerciseDays,
  });

  final bool success;
  final String message;
  final String userId;
  final int count;
  final List<DailyLogRecord> logs;
  final Map<String, int> flowCounts;
  final double? averageSleep;
  final double? averageWater;
  final int? exerciseDays;
}

class DailyLogRecord {
  const DailyLogRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.flow,
    required this.symptoms,
    required this.mood,
    required this.sleep,
    required this.water,
    required this.exercise,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String date;
  final String flow;
  final List<String> symptoms;
  final String mood;
  final double sleep;
  final double water;
  final bool exercise;
  final DateTime? createdAt;

  factory DailyLogRecord.fromJson(Map<String, dynamic> json) {
    final symptoms = <String>[];
    final rawSymptoms = json['symptoms'];
    if (rawSymptoms is List) {
      for (final item in rawSymptoms) {
        if (item != null) {
          final value = item.toString().trim();
          if (value.isNotEmpty) {
            symptoms.add(value);
          }
        }
      }
    }

    return DailyLogRecord(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      flow: json['flow']?.toString() ?? 'medium',
      symptoms: symptoms,
      mood: json['mood']?.toString() ?? 'normal',
      sleep: double.tryParse(json['sleep']?.toString() ?? '0') ?? 0,
      water: double.tryParse(json['water']?.toString() ?? '0') ?? 0,
      exercise: json['exercise'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class DailyLogListResponse {
  const DailyLogListResponse({
    required this.success,
    required this.message,
    required this.userId,
    required this.count,
    required this.logs,
  });

  final bool success;
  final String message;
  final String userId;
  final int count;
  final List<DailyLogRecord> logs;
}

class CycleApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  int _defaultTimezoneOffsetMinutes() {
    return DateTime.now().timeZoneOffset.inMinutes;
  }

  String _toBackendDate(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)}';
  }

  Future<AddCycleResponse> addCycle({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    required int cycleLength,
    required int periodLength,
    int? timezoneOffsetMinutes,
    String entryType = 'actual',
    bool isConfirmed = true,
    String? notes,
  }) async {
    final uri = Uri.parse('$_baseUrl/add-cycle');
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId.trim(),
          'startDate': _toBackendDate(startDate),
          if (endDate != null) 'endDate': _toBackendDate(endDate),
          'cycleLength': cycleLength,
          'periodLength': periodLength,
          'timezoneOffsetMinutes': resolvedOffset,
          'entryType': entryType,
          'isConfirmed': isConfirmed,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        }),
      );

      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Add cycle request completed';

      final savedCycleJson =
          payload['savedCycle'] ??
          payload['cycle'] ??
          payload['data']?['savedCycle'];
      final summaryJson =
          payload['currentCycleSummary'] ??
          payload['summary'] ??
          payload['data']?['currentCycleSummary'];
      final confidenceJson =
          payload['confidence'] ??
          payload['predictionConfidence'] ??
          payload['data']?['confidence'];

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AddCycleResponse(
          success: true,
          message: message,
          savedCycle: _parseCycleRecord(savedCycleJson),
          currentCycleSummary: _parseCycleSummary(summaryJson),
          predictionConfidence: _parseCycleConfidence(confidenceJson),
        );
      }

      return AddCycleResponse(success: false, message: message);
    } catch (_) {
      return const AddCycleResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Future<ApiStatus> addDailyLog({
    required String userId,
    required String date,
    required String flow,
    required List<String> symptoms,
    required String mood,
    required double sleep,
    required double water,
    required bool exercise,
    int? timezoneOffsetMinutes,
    String? notes,
  }) async {
    final uri = Uri.parse('$_baseUrl/logs-daily');
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId.trim(),
          'date': date,
          'flow': flow,
          'symptoms': symptoms,
          'mood': mood,
          'sleep': sleep,
          'water': water,
          'exercise': exercise,
          'timezoneOffsetMinutes': resolvedOffset,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        }),
      );

      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Add daily log request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiStatus(success: true, message: message);
      }

      return ApiStatus(success: false, message: message);
    } catch (_) {
      return const ApiStatus(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Future<CycleListResponse> getCyclesByUserId(String userId) async {
    return getCyclesByUserIdWithTimezone(userId);
  }

  Future<CycleListResponse> getCyclesByUserIdWithTimezone(
    String userId, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri = Uri.parse('$_baseUrl/cycles/$cleanUserId').replace(
      queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
    );

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Cycle list request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final cyclesJson =
            payload['cycles'] ?? payload['history'] ?? payload['records'];
        final cycles = <CycleRecord>[];

        if (cyclesJson is List) {
          for (final item in cyclesJson) {
            if (item is Map<String, dynamic>) {
              cycles.add(CycleRecord.fromJson(item));
            } else if (item is Map) {
              cycles.add(CycleRecord.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        final summaryJson =
            payload['currentCycleSummary'] ??
            payload['summary'] ??
            payload['cycleSummary'];
        final confidenceJson =
            payload['predictionConfidence'] ?? payload['confidence'];

        return CycleListResponse(
          success: true,
          message: message,
          cycles: cycles,
          currentCycleSummary: _parseCycleSummary(summaryJson),
          predictionConfidence: _parseCycleConfidence(confidenceJson),
        );
      }

      return CycleListResponse(
        success: false,
        message: message,
        cycles: const [],
      );
    } catch (_) {
      return const CycleListResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
        cycles: [],
      );
    }
  }

  Future<DailyLogListResponse> getDailyLogsByUserId(String userId) async {
    return getDailyLogsByUserIdWithTimezone(userId);
  }

  Future<DailyLogListResponse> getDailyLogsByUserIdWithTimezone(
    String userId, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return const DailyLogListResponse(
        success: false,
        message: 'User ID is required to fetch daily logs',
        userId: '',
        count: 0,
        logs: [],
      );
    }

    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri = Uri.parse('$_baseUrl/logs-daily/$cleanUserId').replace(
      queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
    );

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Daily logs request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final logsJson = payload['logs'];
        final logs = <DailyLogRecord>[];

        if (logsJson is List) {
          for (final item in logsJson) {
            if (item is Map<String, dynamic>) {
              logs.add(DailyLogRecord.fromJson(item));
            } else if (item is Map) {
              logs.add(
                DailyLogRecord.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        final count =
            int.tryParse(payload['count']?.toString() ?? '') ?? logs.length;

        return DailyLogListResponse(
          success: true,
          message: message,
          userId: payload['userId']?.toString() ?? cleanUserId,
          count: count,
          logs: logs,
        );
      }

      return DailyLogListResponse(
        success: false,
        message: message,
        userId: cleanUserId,
        count: 0,
        logs: const [],
      );
    } catch (_) {
      return DailyLogListResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
        userId: cleanUserId,
        count: 0,
        logs: const [],
      );
    }
  }

  Future<ApiStatus> updateDailyLog({
    required String userId,
    required String logDate,
    required String flow,
    required List<String> symptoms,
    required String mood,
    required double sleep,
    required double water,
    required bool exercise,
    int? timezoneOffsetMinutes,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/logs-daily/${Uri.encodeComponent(userId.trim())}/$logDate',
    );
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId.trim(),
          'date': logDate,
          'flow': flow,
          'symptoms': symptoms,
          'mood': mood,
          'sleep': sleep,
          'water': water,
          'exercise': exercise,
          'timezoneOffsetMinutes': resolvedOffset,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        }),
      );

      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Update daily log request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiStatus(success: true, message: message);
      }

      return ApiStatus(success: false, message: message);
    } catch (_) {
      return const ApiStatus(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Future<CycleSummaryResponse> getCycleSummary(
    String userId, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri = Uri.parse('$_baseUrl/cycle-summary/$cleanUserId').replace(
      queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
    );
    return _fetchCycleSummary(uri);
  }

  Future<CycleSummaryResponse> getCurrentCycleSummary(
    String userId, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri = Uri.parse('$_baseUrl/current-cycle-summary/$cleanUserId')
        .replace(
          queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
        );
    return _fetchCycleSummary(uri);
  }

  Future<PredictionConfidenceResponse> getPredictionConfidence(
    String userId, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri = Uri.parse('$_baseUrl/prediction-confidence/$cleanUserId')
        .replace(
          queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
        );

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Prediction confidence request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final confidenceJson =
            payload['confidence'] ?? payload['data'] ?? payload;
        return PredictionConfidenceResponse(
          success: true,
          message: message,
          confidence: _parseCycleConfidence(confidenceJson),
        );
      }

      return PredictionConfidenceResponse(success: false, message: message);
    } catch (_) {
      return const PredictionConfidenceResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Future<MonthCalendarResponse> getMonthCalendarSummary(
    String userId,
    int year,
    int month, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri = Uri.parse('$_baseUrl/month-calendar/$cleanUserId/$year/$month')
        .replace(
          queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
        );

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Month calendar request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final daysJson = payload['days'] ?? payload['calendarDays'] ?? [];
        final days = <MonthCalendarDay>[];
        if (daysJson is List) {
          for (final item in daysJson) {
            if (item is Map<String, dynamic>) {
              days.add(MonthCalendarDay.fromJson(item));
            } else if (item is Map) {
              days.add(
                MonthCalendarDay.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        final aggregateCounts = <String, int>{};
        final rawCounts = payload['aggregateCounts'] ?? payload['counts'];
        if (rawCounts is Map) {
          for (final entry in rawCounts.entries) {
            aggregateCounts[entry.key.toString()] =
                int.tryParse(entry.value?.toString() ?? '') ?? 0;
          }
        }

        return MonthCalendarResponse(
          success: true,
          message: message,
          days: days,
          currentCycleSummary: _parseCycleSummary(
            payload['currentCycleSummary'] ?? payload['summary'],
          ),
          aggregateCounts: aggregateCounts,
        );
      }

      return MonthCalendarResponse(
        success: false,
        message: message,
        days: const [],
      );
    } catch (_) {
      return const MonthCalendarResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
        days: [],
      );
    }
  }

  Future<MonthlyDailyLogSummaryResponse> getDailyLogsByMonth(
    String userId,
    int year,
    int month, {
    int? timezoneOffsetMinutes,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return const MonthlyDailyLogSummaryResponse(
        success: false,
        message: 'User ID is required to fetch daily logs',
        userId: '',
        count: 0,
        logs: [],
      );
    }

    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();
    final uri =
        Uri.parse(
          '$_baseUrl/logs-daily/$cleanUserId/month/$year/$month',
        ).replace(
          queryParameters: {'timezoneOffsetMinutes': resolvedOffset.toString()},
        );

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Monthly daily log request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final logsJson = payload['logs'];
        final logs = <DailyLogRecord>[];

        if (logsJson is List) {
          for (final item in logsJson) {
            if (item is Map<String, dynamic>) {
              logs.add(DailyLogRecord.fromJson(item));
            } else if (item is Map) {
              logs.add(
                DailyLogRecord.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        final count =
            int.tryParse(payload['count']?.toString() ?? '') ?? logs.length;
        final flowCounts = <String, int>{};
        final rawFlowCounts = payload['flowCounts'] ?? payload['flows'];
        if (rawFlowCounts is Map) {
          for (final entry in rawFlowCounts.entries) {
            flowCounts[entry.key.toString()] =
                int.tryParse(entry.value?.toString() ?? '') ?? 0;
          }
        }

        final averageSleep = double.tryParse(
          payload['averageSleep']?.toString() ?? '',
        );
        final averageWater = double.tryParse(
          payload['averageWater']?.toString() ?? '',
        );
        final exerciseDays = int.tryParse(
          payload['exerciseDays']?.toString() ?? '',
        );

        return MonthlyDailyLogSummaryResponse(
          success: true,
          message: message,
          userId: payload['userId']?.toString() ?? cleanUserId,
          count: count,
          logs: logs,
          flowCounts: flowCounts,
          averageSleep: averageSleep,
          averageWater: averageWater,
          exerciseDays: exerciseDays,
        );
      }

      return MonthlyDailyLogSummaryResponse(
        success: false,
        message: message,
        userId: cleanUserId,
        count: 0,
        logs: const [],
      );
    } catch (_) {
      return MonthlyDailyLogSummaryResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
        userId: cleanUserId,
        count: 0,
        logs: const [],
      );
    }
  }

  Future<ApiStatus> editCycle({
    required String cycleId,
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    required int cycleLength,
    required int periodLength,
    int? timezoneOffsetMinutes,
    String? notes,
    bool isConfirmed = true,
    String entryType = 'actual',
  }) async {
    final uri = Uri.parse('$_baseUrl/edit-cycle/$cycleId');
    final resolvedOffset =
        timezoneOffsetMinutes ?? _defaultTimezoneOffsetMinutes();

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId.trim(),
          'startDate': _toBackendDate(startDate),
          if (endDate != null) 'endDate': _toBackendDate(endDate),
          'cycleLength': cycleLength,
          'periodLength': periodLength,
          'timezoneOffsetMinutes': resolvedOffset,
          'entryType': entryType,
          'isConfirmed': isConfirmed,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        }),
      );

      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Edit cycle request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiStatus(success: true, message: message);
      }

      return ApiStatus(success: false, message: message);
    } catch (_) {
      return const ApiStatus(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  String? _extractMessage(Map<String, dynamic> payload) {
    final message = payload['message'] ?? payload['error'] ?? payload['detail'];
    if (message == null) {
      return null;
    }
    return message.toString();
  }

  CycleRecord? _parseCycleRecord(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CycleRecord.fromJson(value);
    }
    if (value is Map) {
      return CycleRecord.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  CycleSummary? _parseCycleSummary(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CycleSummary.fromJson(value);
    }
    if (value is Map) {
      return CycleSummary.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  CycleConfidence? _parseCycleConfidence(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CycleConfidence.fromJson(value);
    }
    if (value is Map) {
      return CycleConfidence.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  Future<CycleSummaryResponse> _fetchCycleSummary(Uri uri) async {
    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Cycle summary request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final summaryJson =
            payload['currentCycleSummary'] ?? payload['summary'] ?? payload;
        return CycleSummaryResponse(
          success: true,
          message: message,
          summary: _parseCycleSummary(summaryJson),
        );
      }

      return CycleSummaryResponse(success: false, message: message);
    } catch (_) {
      return CycleSummaryResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
      );
    }
  }
}

class CycleSummaryResponse {
  const CycleSummaryResponse({
    required this.success,
    required this.message,
    this.summary,
  });

  final bool success;
  final String message;
  final CycleSummary? summary;
}

class PredictionConfidenceResponse {
  const PredictionConfidenceResponse({
    required this.success,
    required this.message,
    this.confidence,
  });

  final bool success;
  final String message;
  final CycleConfidence? confidence;
}
