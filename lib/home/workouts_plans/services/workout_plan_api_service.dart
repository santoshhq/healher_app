import 'dart:convert';

import 'package:http/http.dart' as http;

class WorkoutPose {
  const WorkoutPose({
    required this.name,
    required this.videoUrl,
    required this.category,
    required this.duration,
    required this.benefits,
    required this.difficulty,
    required this.tags,
    required this.focus,
    this.completed = false,
  });

  final String name;
  final String videoUrl;
  final String category;
  final int duration;
  final List<String> benefits;
  final String difficulty;
  final List<String> tags;
  final List<String> focus;
  final bool completed;

  factory WorkoutPose.fromJson(Map<String, dynamic> json) {
    final benefits = _toStringList(json['benefits']);
    final tags = _toStringList(json['tags']);
    final focus = _toStringList(json['focus']);

    return WorkoutPose(
      name: json['name']?.toString() ?? 'Unknown Pose',
      videoUrl: json['video_url']?.toString() ?? '',
      category: json['category']?.toString() ?? 'main',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      benefits: benefits,
      difficulty: json['difficulty']?.toString() ?? 'beginner',
      tags: tags,
      focus: focus,
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toDailyWorkoutJson() {
    return {
      'name': name,
      'benefits': benefits,
      'category': category,
      'duration': duration,
      'video_url': videoUrl,
      'difficulty': difficulty,
      'tags': tags,
      'focus': focus,
      'completed': true,
    };
  }

  static List<String> _toStringList(dynamic source) {
    final result = <String>[];
    if (source is List) {
      for (final item in source) {
        if (item != null) {
          final value = item.toString().trim();
          if (value.isNotEmpty) {
            result.add(value);
          }
        }
      }
    }
    return result;
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

class SaveCompletedWorkoutResponse {
  const SaveCompletedWorkoutResponse({
    required this.success,
    required this.message,
    this.workoutId,
    this.userId,
    this.completedCount,
  });

  final bool success;
  final String message;
  final String? workoutId;
  final String? userId;
  final int? completedCount;
}

class TodayCompletedWorkoutResponse {
  const TodayCompletedWorkoutResponse({
    required this.success,
    required this.message,
    required this.userId,
    required this.workoutDate,
    required this.poses,
    required this.completedCount,
    this.status,
  });

  final bool success;
  final String message;
  final String userId;
  final String workoutDate;
  final List<WorkoutPose> poses;
  final int completedCount;
  final String? status;

  bool get hasCompletedWorkoutToday =>
      status?.toLowerCase() == 'completed' && completedCount == 3;
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
      final message =
          _extractMessage(payload) ?? 'Workout plan request completed';

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

        return WorkoutPlanResponse(
          success: true,
          message: message,
          poses: poses,
        );
      }

      return WorkoutPlanResponse(
        success: false,
        message: message,
        poses: const [],
      );
    } catch (_) {
      return const WorkoutPlanResponse(
        success: false,
        message: 'Unable to connect. Please check internet and try again.',
        poses: [],
      );
    }
  }

  Future<SaveCompletedWorkoutResponse> saveCompletedDailyWorkout({
    required String userId,
    required String workoutDate,
    required List<WorkoutPose> poses,
  }) async {
    if (userId.trim().isEmpty) {
      return const SaveCompletedWorkoutResponse(
        success: false,
        message: 'User not found. Please login again.',
      );
    }

    if (poses.length != 3) {
      return const SaveCompletedWorkoutResponse(
        success: false,
        message: 'Exactly 3 yoga poses are required',
      );
    }

    final uri = Uri.parse('$_baseUrl/daily-workout/complete');
    final body = {
      'userId': userId,
      'workoutDate': workoutDate,
      'poses': poses.map((pose) => pose.toDailyWorkoutJson()).toList(),
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final payload = _safeDecode(response.body);
      final message = _extractMessage(payload) ?? 'Daily workout save failed';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SaveCompletedWorkoutResponse(
          success: true,
          message: message,
          workoutId: payload['workoutId']?.toString(),
          userId: payload['userId']?.toString(),
          completedCount: int.tryParse(
            payload['completedCount']?.toString() ?? '',
          ),
        );
      }

      return SaveCompletedWorkoutResponse(success: false, message: message);
    } catch (_) {
      return const SaveCompletedWorkoutResponse(
        success: false,
        message: 'Unable to save completed workout. Please try again.',
      );
    }
  }

  Future<TodayCompletedWorkoutResponse> getTodayCompletedWorkout({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      return const TodayCompletedWorkoutResponse(
        success: false,
        message: 'User not found. Please login again.',
        userId: '',
        workoutDate: '',
        poses: [],
        completedCount: 0,
      );
    }

    final uri = Uri.parse('$_baseUrl/daily-workout/today/$userId');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      final payload = _safeDecode(response.body);
      final message =
          _extractMessage(payload) ?? 'Unable to fetch today workout';

      final poses = _parsePoses(payload['poses']);
      final completedCount =
          int.tryParse(payload['completedCount']?.toString() ?? '') ??
          poses.length;

      final success = response.statusCode >= 200 && response.statusCode < 300;
      return TodayCompletedWorkoutResponse(
        success: success,
        message: message,
        userId: payload['userId']?.toString() ?? userId,
        workoutDate: payload['workoutDate']?.toString() ?? '',
        poses: poses,
        completedCount: completedCount,
        status: payload['status']?.toString(),
      );
    } catch (_) {
      return TodayCompletedWorkoutResponse(
        success: false,
        message: 'Unable to fetch today completed workout. Please try again.',
        userId: userId,
        workoutDate: '',
        poses: const [],
        completedCount: 0,
      );
    }
  }

  List<WorkoutPose> _parsePoses(dynamic posesJson) {
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
    return poses;
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
