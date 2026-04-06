import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chatbot_model.dart';
import 'services/chatbot_api_service.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({
    required this.userId,
    required this.fullName,
    super.key,
  });

  final String userId;
  final String fullName;

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final ChatbotApiService _apiService = ChatbotApiService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = <ChatMessage>[];

  bool _isLoadingHistory = true;
  bool _isSending = false;
  bool _stickToBottom = true;
  String? _errorMessage;

  final Color _primaryPink = const Color(0xFFD94F7C);
  final Color _lightPink = const Color(0xFFFDE8EF);
  final Color _textPrimary = const Color(0xFF1A1A1A);
  final Color _textSecondary = const Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    _stickToBottom = distanceToBottom <= 80;
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    try {
      final history = await _apiService.getResponses(userId: widget.userId);
      final mappedMessages = <ChatMessage>[];

      final sorted = List<ChatHistoryItem>.from(history.responses)
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });

      for (final response in sorted) {
        final time = response.createdAt ?? DateTime.now();

        if (response.userQuery.trim().isNotEmpty) {
          mappedMessages.add(
            ChatMessage(
              text: response.userQuery.trim(),
              isUser: true,
              createdAt: time,
            ),
          );
        }

        if (response.aiResponse.trim().isNotEmpty) {
          mappedMessages.add(
            ChatMessage(
              text: response.aiResponse.trim(),
              isUser: false,
              createdAt: time.add(const Duration(milliseconds: 1)),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(mappedMessages);
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    final question = _questionController.text.trim();
    if (question.isEmpty) {
      return;
    }

    _questionController.clear();

    final now = DateTime.now();
    final userMessage = ChatMessage(
      text: question,
      isUser: true,
      createdAt: now,
    );
    final placeholder = ChatMessage(
      text: '',
      isUser: false,
      createdAt: now.add(const Duration(milliseconds: 1)),
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(placeholder);
      _errorMessage = null;
      _isSending = true;
    });

    _scrollToBottom();

    final aiIndex = _messages.length - 1;
    var accumulated = '';

    try {
      await for (final chunk in _apiService.streamAnswer(
        userId: widget.userId,
        question: question,
      )) {
        accumulated += chunk;

        if (!mounted || aiIndex >= _messages.length) {
          return;
        }

        setState(() {
          _messages[aiIndex] = _messages[aiIndex].copyWith(
            text: accumulated,
            isStreaming: true,
          );
        });
        _scrollToBottom(force: true, immediate: true);
      }

      if (!mounted || aiIndex >= _messages.length) {
        return;
      }

      setState(() {
        _messages[aiIndex] = _messages[aiIndex].copyWith(isStreaming: false);
      });
    } catch (error) {
      if (!mounted || aiIndex >= _messages.length) {
        return;
      }

      final fallback = accumulated.isEmpty
          ? 'Unable to fetch response right now. Please try again.'
          : accumulated;

      setState(() {
        _messages[aiIndex] = _messages[aiIndex].copyWith(
          text: fallback,
          isStreaming: false,
        );
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom(force: true);
    }
  }

  void _scrollToBottom({bool force = false, bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      if (!force && !_stickToBottom) {
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;

      if (immediate) {
        _scrollController.jumpTo(maxScroll);
        return;
      }

      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? _primaryPink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text.isEmpty && message.isStreaming
                  ? 'Thinking...'
                  : message.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.45,
                color: isUser ? Colors.white : _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isUser ? Colors.white70 : _textSecondary,
                  ),
                ),
                if (message.isStreaming) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: isUser ? Colors.white70 : _primaryPink,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Health Coach',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              'Hi ${widget.fullName}, ask me anything',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF7C7C7)),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9E2A2A),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 46,
                          color: _primaryPink,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                            'Start a conversation',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Try: Can you suggest a PCOS-friendly dinner?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      enabled: !_isSending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask about symptoms, food, or wellness...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _primaryPink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPink,
                        disabledBackgroundColor: _lightPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        _isSending ? Icons.hourglass_top : Icons.send_rounded,
                        color: _isSending ? _primaryPink : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

