class ChatHistoryItem {
  const ChatHistoryItem({
    required this.threadId,
    required this.userQuery,
    required this.aiResponse,
    required this.createdAt,
  });

  final String threadId;
  final String userQuery;
  final String aiResponse;
  final DateTime? createdAt;

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      threadId: json['thread_id']?.toString() ?? '',
      userQuery: json['user_query']?.toString() ?? '',
      aiResponse: json['ai_response']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ChatHistoryResponse {
  const ChatHistoryResponse({
    required this.userId,
    required this.count,
    required this.responses,
  });

  final String userId;
  final int count;
  final List<ChatHistoryItem> responses;

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final mapped = <ChatHistoryItem>[];
    final source = json['responses'];

    if (source is List) {
      for (final item in source) {
        if (item is Map<String, dynamic>) {
          mapped.add(ChatHistoryItem.fromJson(item));
        } else if (item is Map) {
          mapped.add(ChatHistoryItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ChatHistoryResponse(
      userId: json['userId']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? mapped.length,
      responses: mapped,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isStreaming;

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? createdAt,
    bool? isStreaming,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
