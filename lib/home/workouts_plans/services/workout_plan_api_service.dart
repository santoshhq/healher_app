import 'dart:convert';

import 'package:http/http.dart' as http;

class WorkoutPose {
  const WorkoutPose({
    required this.name,
    required this.videoUrl,
    required this.category,
    required this.duration,
    required this.benefits,
  });

  final String name;
  final String videoUrl;
  final String category;
  final int duration;
  final List<String> benefits;

  factory WorkoutPose.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'];
    final benefits = <String>[];

    if (rawBenefits is List) {
      for (final item in rawBenefits) {
        if (item != null) {
          benefits.add(item.toString());
        }
      }
    }

    return WorkoutPose(
      name: json['name']?.toString() ?? 'Unknown Pose',
      videoUrl: json['video_url']?.toString() ?? '',
      category: json['category']?.toString() ?? 'main',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      benefits: benefits,
    );
  }
}

class WorkoutPlanResponse {
  const WorkoutPlanResponse({
    required this.success,
    required this.message,
    required this.poses,
  });

  final bool success;
  final String message;
  final List<WorkoutPose> poses;
}

class WorkoutPlanApiService {
  static const String _baseUrl = 'http://13.222.13.211:8080';

  Future<WorkoutPlanResponse> getCustomPoses({
    required int warmupCount,
    required int mainCount,
    required int relaxationCount,
  }) async {
    final uri = Uri.parse('$_baseUrl/get-custom-poses').replace(
      queryParameters: {
        'warmup_count': warmupCount.toString(),
        'main_count': mainCount.toString(),
        'relaxation_count': relaxationCount.toString(),
      },
    );

    try {
      final response = await http.get(uri);
      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Workout plan request completed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final posesJson = payload['poses'];
        final poses = <WorkoutPose>[];

        if (posesJson is List) {
          for (final item in posesJson) {
            if (item is Map<String, dynamic>) {
              poses.add(WorkoutPose.fromJson(item));
            } else if (item is Map) {
              poses.add(WorkoutPose.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        return WorkoutPlanResponse(success: true, message: message, poses: poses);
      }

      return WorkoutPlanResponse(success: false, message: message, poses: const []);
    } catch (_) {
      return const WorkoutPlanResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
        poses: [],
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
}
