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
    );
  }
}

class CycleListResponse {
  const CycleListResponse({
    required this.success,
    required this.message,
    required this.cycles,
  });

  final bool success;
  final String message;
  final List<CycleRecord> cycles;
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

  Future<ApiStatus> addCycle({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    required int cycleLength,
    required int periodLength,
  }) async {
    final uri = Uri.parse('$_baseUrl/add-cycle');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'startDate': _toBackendDateTime(startDate),
          if (endDate != null) 'endDate': _toBackendDateTime(endDate),
          'cycleLength': cycleLength,
          'periodLength': periodLength,
        }),
      );

      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Add cycle request completed';

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

  Future<ApiStatus> addDailyLog({
    required String userId,
    required String date,
    required String flow,
    required List<String> symptoms,
    required String mood,
    required double sleep,
    required double water,
    required bool exercise,
  }) async {
    final uri = Uri.parse('$_baseUrl/logs-daily');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'date': date,
          'flow': flow,
          'symptoms': symptoms,
          'mood': mood,
          'sleep': sleep,
          'water': water,
          'exercise': exercise,
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
    final uri = Uri.parse('$_baseUrl/cycles/$userId');

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Cycle list request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final cyclesJson = payload['cycles'];
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

        return CycleListResponse(
          success: true,
          message: message,
          cycles: cycles,
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

    final uri = Uri.parse('$_baseUrl/logs-daily/$cleanUserId');

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

  String _toBackendDateTime(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)}T${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
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
}
