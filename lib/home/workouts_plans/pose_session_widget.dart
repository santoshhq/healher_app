import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/ui/app_theme.dart';

import 'services/workout_plan_api_service.dart';

class PoseSessionWidget extends StatefulWidget {
  const PoseSessionWidget({required this.pose, super.key});

  final WorkoutPose pose;

  @override
  State<PoseSessionWidget> createState() => _PoseSessionWidgetState();
}

class _PoseSessionWidgetState extends State<PoseSessionWidget> {
  static const int _initialSeconds = 300;

  Timer? _timer;
  int _remainingSeconds = _initialSeconds;
  bool _isRunning = false;
  bool _isCompleted = false;

  WebViewController? _webController;
  bool _canShowWebView = false;
  YoutubePlayerController? _youtubeController;
  bool _isYouTubeVideo = false;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    final rawUrl = widget.pose.videoUrl.trim();
    final uri = Uri.tryParse(rawUrl);
    final youtubeId = _extractYouTubeId(rawUrl);

    if (youtubeId != null) {
      _isYouTubeVideo = true;
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: youtubeId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
      return;
    }

    final canShow =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    _canShowWebView = canShow;

    if (canShow) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(uri);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _youtubeController?.close();
    super.dispose();
  }

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return segment.isEmpty ? null : segment;
    }

    if (host.contains('youtube.com')) {
      final watchId = uri.queryParameters['v'];
      if (watchId != null && watchId.isNotEmpty) {
        return watchId;
      }

      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex >= 0 && embedIndex + 1 < uri.pathSegments.length) {
        return uri.pathSegments[embedIndex + 1];
      }
    }

    return null;
  }

  Future<void> _playVideoInBox() async {
    if (_isYouTubeVideo && _youtubeController != null) {
      _youtubeController!.playVideo();
      if (mounted) {
        setState(() {
          _isVideoPlaying = true;
        });
      }
      return;
    }

    if (_webController != null) {
      await _webController!.runJavaScript("""
        (function() {
          var video = document.querySelector('video');
          if (video) { video.play(); }
        })();
        """);
      if (mounted) {
        setState(() {
          _isVideoPlaying = true;
        });
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video player is unavailable for this URL.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _pauseVideoInBox() async {
    if (_isYouTubeVideo && _youtubeController != null) {
      _youtubeController!.pauseVideo();
      if (mounted) {
        setState(() {
          _isVideoPlaying = false;
        });
      }
      return;
    }

    if (_webController != null) {
      await _webController!.runJavaScript("""
        (function() {
          var video = document.querySelector('video');
          if (video) { video.pause(); }
        })();
        """);
      if (mounted) {
        setState(() {
          _isVideoPlaying = false;
        });
      }
    }
  }

  String _formatTimer(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.pose.videoUrl.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _startTimer() {
    if (_isCompleted || _isRunning) {
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _isCompleted = true;
        });
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _initialSeconds;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  Color _categoryColor() {
    switch (widget.pose.category.toLowerCase()) {
      case 'warmup':
        return const Color(0xFFFF8A65);
      case 'main':
        return const Color(0xFFE91E63);
      case 'relaxation':
        return const Color(0xFF26A69A);
      default:
        return const Color(0xFF9575CD);
    }
  }

  Widget _buildTimerRing(Color categoryColor) {
    final progress = 1 - (_remainingSeconds / _initialSeconds);

    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 8,
              backgroundColor: categoryColor.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTimer(_remainingSeconds),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E2835),
                ),
              ),
              Text(
                'remaining',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6F6A78),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandInk,
        title: Text(
          widget.pose.name,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: AppTheme.pageBackgroundDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isYouTubeVideo && _youtubeController != null
                      ? YoutubePlayer(
                          controller: _youtubeController!,
                          aspectRatio: 16 / 9,
                        )
                      : _canShowWebView && _webController != null
                      ? WebViewWidget(controller: _webController!)
                      : Center(
                          child: Text(
                            'Video preview is unavailable',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                if (_isYouTubeVideo || _canShowWebView)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _playVideoInBox,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              'Start Video',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pauseVideoInBox,
                            icon: const Icon(Icons.pause_rounded),
                            label: Text(
                              'Pause Video',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF625C69),
                              minimumSize: const Size.fromHeight(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isYouTubeVideo || _canShowWebView)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      _isVideoPlaying
                          ? 'Video status: Playing'
                          : 'Video status: Paused',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF6C6674),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (widget.pose.videoUrl.trim().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openExternally,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        'Open Video Externally',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: categoryColor,
                        side: BorderSide(
                          color: categoryColor.withOpacity(0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          widget.pose.category.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.pose.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D1B20),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Suggested duration: ${widget.pose.duration} min',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6F6A78),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Benefits',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2835),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.pose.benefits
                            .map(
                              (benefit) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F3F8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  benefit,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFF4B4454),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF4D7E2)),
                        ),
                        child: Row(
                          children: [
                            _buildTimerRing(categoryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Session Timer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2E2835),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isCompleted
                                        ? 'Completed. Great work!'
                                        : _isRunning
                                        ? 'In progress'
                                        : 'Ready to begin',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6F6A78),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isCompleted
                                          ? const Color(0xFFE6F4EA)
                                          : const Color(0xFFEDE7F6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _isCompleted
                                          ? 'Completed'
                                          : _isRunning
                                          ? 'Active'
                                          : 'Paused',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _isCompleted
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF5E35B1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isRunning ? _pauseTimer : _startTimer,
                              icon: Icon(
                                _isRunning
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                              ),
                              label: Text(
                                _isRunning ? 'Pause' : 'Start',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: categoryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetTimer,
                              icon: const Icon(
                                Icons.replay_circle_filled_rounded,
                              ),
                              label: Text(
                                'Reset',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6F687A),
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            'Mark Completed & Back',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            backgroundColor: const Color(0xFFE6F4EA),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
