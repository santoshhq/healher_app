import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.healthScore,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.pcosPositive,
    required this.pcosNegative,
    required this.recommendation,
    required this.alternative,
  });

  final String foodName;
  final String calories;
  final String healthScore;
  final String protein;
  final String carbs;
  final String fats;
  final String pcosPositive;
  final String pcosNegative;
  final String recommendation;
  final String alternative;

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final macros = _toMap(json['macros']);
    final pcosImpact = _toMap(json['pcos_impact']);

    return FoodAnalysisResult(
      foodName: json['food_name']?.toString() ?? 'Unknown food',
      calories: json['calories']?.toString() ?? '-',
      healthScore: json['health_score']?.toString() ?? '-',
      protein: macros['protein']?.toString() ?? '-',
      carbs: macros['carbs']?.toString() ?? '-',
      fats: macros['fats']?.toString() ?? '-',
      pcosPositive: pcosImpact['positive']?.toString() ?? '-',
      pcosNegative: pcosImpact['negative']?.toString() ?? '-',
      recommendation: json['recommendation']?.toString() ?? '-',
      alternative: json['alternative']?.toString() ?? '-',
    );
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }
}

class FoodScanHistoryItem {
  const FoodScanHistoryItem({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.healthScore,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.pcosPositive,
    required this.pcosNegative,
    required this.recommendation,
    required this.alternative,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String foodName;
  final String calories;
  final String healthScore;
  final String protein;
  final String carbs;
  final String fats;
  final String pcosPositive;
  final String pcosNegative;
  final String recommendation;
  final String alternative;
  final DateTime? createdAt;

  factory FoodScanHistoryItem.fromJson(Map<String, dynamic> json) {
    final macros = FoodAnalysisResult._toMap(json['macros']);
    final pcosImpact = FoodAnalysisResult._toMap(json['pcos_impact']);

    return FoodScanHistoryItem(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      foodName: json['food_name']?.toString() ?? 'Unknown food',
      calories: json['calories']?.toString() ?? '-',
      healthScore: json['health_score']?.toString() ?? '-',
      protein: macros['protein']?.toString() ?? '-',
      carbs: macros['carbs']?.toString() ?? '-',
      fats: macros['fats']?.toString() ?? '-',
      pcosPositive: pcosImpact['positive']?.toString() ?? '-',
      pcosNegative: pcosImpact['negative']?.toString() ?? '-',
      recommendation: json['recommendation']?.toString() ?? '-',
      alternative: json['alternative']?.toString() ?? '-',
      createdAt: _parseDate(json['createdAt']?.toString()),
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
}

class FoodHistoryResponse {
  const FoodHistoryResponse({
    required this.success,
    required this.userId,
    required this.count,
    required this.scans,
    required this.message,
    required this.rawPayload,
  });

  final bool success;
  final String userId;
  final int count;
  final List<FoodScanHistoryItem> scans;
  final String message;
  final Map<String, dynamic> rawPayload;
}

class FoodAnalysisResponse {
  const FoodAnalysisResponse({
    required this.success,
    required this.message,
    required this.rawPayload,
    this.result,
  });

  final bool success;
  final String message;
  final Map<String, dynamic> rawPayload;
  final FoodAnalysisResult? result;
}

class FoodScannerApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';
  static const String _analysePath = '/food-analyse';
  static const Duration _requestTimeout = Duration(seconds: 90);

  Future<FoodAnalysisResponse> analyseFood({
    required String userId,
    required String imageBase64OrDataUri,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return const FoodAnalysisResponse(
        success: false,
        message: 'User id is required to save scanned food analysis.',
        rawPayload: {},
      );
    }

    final imageData = imageBase64OrDataUri.trim();
    if (imageData.isEmpty) {
      return const FoodAnalysisResponse(
        success: false,
        message: 'Please select an image before analysis.',
        rawPayload: {},
      );
    }

    final uri = Uri.parse('$_baseUrl$_analysePath');

    try {
      final response = await _postAnalyse(
        uri: uri,
        userId: cleanUserId,
        imageData: imageData,
      );

      final payload = _safeDecode(response.body);
      final analysisPayload = _extractAnalysisPayload(payload);
      final contractError = _extractContractError(payload);

      if (contractError != null) {
        return FoodAnalysisResponse(
          success: false,
          message: contractError,
          rawPayload: payload,
        );
      }

      final success = response.statusCode >= 200 && response.statusCode < 300;
      if (!success) {
        final message =
            _extractMessage(payload) ??
            'Food analysis failed with status ${response.statusCode}. Please try with another image.';
        return FoodAnalysisResponse(
          success: false,
          message: message,
          rawPayload: payload,
        );
      }

      return FoodAnalysisResponse(
        success: true,
        message: 'Food analysis completed successfully.',
        rawPayload: analysisPayload,
        result: FoodAnalysisResult.fromJson(analysisPayload),
      );
    } on TimeoutException {
      return const FoodAnalysisResponse(
        success: false,
        message:
            'Food analysis request timed out while waiting for the AI provider. Please retry in a moment. If this continues, the upstream model may be timing out (504).',
        rawPayload: {},
      );
    } on SocketException {
      return const FoodAnalysisResponse(
        success: false,
        message:
            'Network error while reaching food analysis server. Check internet and try again.',
        rawPayload: {},
      );
    } on HttpException {
      return const FoodAnalysisResponse(
        success: false,
        message:
            'Server connection failed for food analysis. Please try again in a moment.',
        rawPayload: {},
      );
    } catch (error) {
      return FoodAnalysisResponse(
        success: false,
        message: 'Unable to analyse image right now: ${error.toString()}',
        rawPayload: {},
      );
    }
  }

  Future<http.Response> _postAnalyse({
    required Uri uri,
    required String userId,
    required String imageData,
  }) async {
    TimeoutException? lastTimeout;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'userId': userId, 'image_data': imageData}),
            )
            .timeout(_requestTimeout);
      } on TimeoutException catch (error) {
        lastTimeout = error;
      }
    }

    throw lastTimeout ?? TimeoutException('Food analysis request timed out');
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
    final message = payload['message'] ?? payload['detail'] ?? payload['error'];
    if (message == null) {
      return null;
    }
    return message.toString();
  }

  String? _extractContractError(Map<String, dynamic> payload) {
    final errorText = payload['error']?.toString().trim();
    if (errorText == null || errorText.isEmpty) {
      return null;
    }

    if (_isUpstreamTimeoutError(errorText)) {
      return 'AI provider timeout (504). Your backend is reachable, but upstream analysis timed out. Please retry in a moment.';
    }

    final hint = payload['hint']?.toString().trim();
    final raw = payload['raw']?.toString().trim();
    final parts = <String>[errorText];

    if (hint != null && hint.isNotEmpty) {
      parts.add('Hint: $hint');
    }

    if (raw != null && raw.isNotEmpty) {
      const maxLength = 220;
      final shortened = raw.length > maxLength
          ? '${raw.substring(0, maxLength)}...'
          : raw;
      parts.add('Raw: $shortened');
    }

    return parts.join('\n');
  }

  bool _isUpstreamTimeoutError(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('504') ||
        normalized.contains('gateway timeout') ||
        normalized.contains('timed out');
  }

  Map<String, dynamic> _extractAnalysisPayload(Map<String, dynamic> payload) {
    // Accept direct payloads and common wrapped response shapes.
    final wrapped = payload['data'] ?? payload['result'];
    if (wrapped is Map<String, dynamic>) {
      return wrapped;
    }
    if (wrapped is Map) {
      return Map<String, dynamic>.from(wrapped);
    }
    return payload;
  }

  Future<FoodHistoryResponse> getFoodHistory({
    required String userId,
    int limit = 50,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return const FoodHistoryResponse(
        success: false,
        userId: '',
        count: 0,
        scans: [],
        message: 'User id is required to fetch scanned food history.',
        rawPayload: {},
      );
    }

    final safeUserId = Uri.encodeComponent(cleanUserId);
    final safeLimit = limit < 1 ? 1 : limit;
    final uri = Uri.parse(
      '$_baseUrl$_analysePath/$safeUserId?limit=$safeLimit',
    );

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_requestTimeout);

      final payload = _safeDecode(response.body);
      final success = response.statusCode >= 200 && response.statusCode < 300;

      if (!success) {
        final notFoundMessage = response.statusCode == 404
            ? 'History endpoint not found on server (GET /food-analyse/{userId}). Please verify backend route deployment.'
            : null;
        return FoodHistoryResponse(
          success: false,
          userId: cleanUserId,
          count: 0,
          scans: const [],
          message:
              notFoundMessage ??
              _extractMessage(payload) ??
              'Unable to fetch scan history (status ${response.statusCode}).',
          rawPayload: payload,
        );
      }

      final scansRaw = payload['scans'];
      final scans = scansRaw is List
          ? scansRaw
                .whereType<Map>()
                .map(
                  (e) => FoodScanHistoryItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : <FoodScanHistoryItem>[];

      final count = (payload['count'] is num)
          ? (payload['count'] as num).toInt()
          : scans.length;

      return FoodHistoryResponse(
        success: true,
        userId: payload['userId']?.toString() ?? cleanUserId,
        count: count,
        scans: scans,
        message: 'Scanned food history loaded.',
        rawPayload: payload,
      );
    } on TimeoutException {
      return FoodHistoryResponse(
        success: false,
        userId: cleanUserId,
        count: 0,
        scans: const [],
        message: 'History request timed out. Please retry in a moment.',
        rawPayload: const {},
      );
    } on SocketException {
      return FoodHistoryResponse(
        success: false,
        userId: cleanUserId,
        count: 0,
        scans: const [],
        message:
            'Network error while fetching food history. Check internet and try again.',
        rawPayload: const {},
      );
    } on HttpException {
      return FoodHistoryResponse(
        success: false,
        userId: cleanUserId,
        count: 0,
        scans: const [],
        message: 'Server connection failed while fetching food history.',
        rawPayload: const {},
      );
    } catch (error) {
      return FoodHistoryResponse(
        success: false,
        userId: cleanUserId,
        count: 0,
        scans: const [],
        message: 'Unable to fetch food history: ${error.toString()}',
        rawPayload: const {},
      );
    }
  }
}
