import 'dart:convert';

import 'package:http/http.dart' as http;

import '../predictor_model.dart';

class PredictorApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  Future<PredictorResponse> assess(PredictorRequest request) async {
    final uri = Uri.parse('$_baseUrl/assess');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PredictorApiException(
          'Assessment failed (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const PredictorApiException('Invalid response format.');
      }

      return PredictorResponse.fromJson(decoded);
    } on FormatException {
      throw const PredictorApiException('Invalid server response payload.');
    } catch (error) {
      if (error is PredictorApiException) {
        rethrow;
      }
      throw const PredictorApiException(
        'Unable to submit assessment. Please try again.',
      );
    }
  }
}

class PredictorApiException implements Exception {
  const PredictorApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

