import 'dart:convert';

import 'package:http/http.dart' as http;

import '../chatbot_model.dart';

class ChatbotApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  Future<ChatHistoryResponse> getResponses({
    required String userId,
    int limit = 50,
  }) async {
    final safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw const ChatbotApiException('User ID is required.');
    }

    final uri = Uri.parse(
      '$_baseUrl/responses/${Uri.encodeComponent(safeUserId)}',
    ).replace(queryParameters: {'limit': limit.toString()});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatbotApiException(
          'Failed to load chat history (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ChatbotApiException('Unexpected history response format.');
      }

      return ChatHistoryResponse.fromJson(decoded);
    } on FormatException {
      throw const ChatbotApiException('Invalid history response payload.');
    } catch (error) {
      if (error is ChatbotApiException) {
        rethrow;
      }
      throw const ChatbotApiException(
        'Unable to fetch chat history. Please try again.',
      );
    }
  }

  Stream<String> streamAnswer({
    required String userId,
    required String question,
  }) async* {
    final safeUserId = userId.trim();
    final safeQuestion = question.trim();

    if (safeUserId.isEmpty) {
      throw const ChatbotApiException('User ID is required.');
    }

    if (safeQuestion.isEmpty) {
      throw const ChatbotApiException('Question cannot be empty.');
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/question'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'userId': safeUserId, 'question': safeQuestion});

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 40));

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final body = await streamedResponse.stream.bytesToString();
        final suffix = body.trim().isEmpty ? '' : ' ${body.trim()}';
        throw ChatbotApiException(
          'Chat request failed (${streamedResponse.statusCode}).$suffix',
        );
      }

      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
        if (chunk.isNotEmpty) {
          yield chunk;
        }
      }
    } catch (error) {
      if (error is ChatbotApiException) {
        rethrow;
      }
      throw const ChatbotApiException(
        'Unable to send your message. Please check internet and try again.',
      );
    } finally {
      client.close();
    }
  }
}

class ChatbotApiException implements Exception {
  const ChatbotApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
