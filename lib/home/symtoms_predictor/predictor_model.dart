class PredictorQuestion {
  const PredictorQuestion({
    required this.key,
    required this.title,
    required this.isBoolean,
    this.hint,
  });

  final String key;
  final String title;
  final bool isBoolean;
  final String? hint;
}

class PredictorRequest {
  const PredictorRequest({
    required this.irregularPeriods,
    required this.skippedPeriods,
    required this.hairGrowth,
    required this.acne,
    required this.weightGain,
    required this.lowEnergy,
    required this.bodyChanges,
    required this.medicalHistory,
  });

  final String irregularPeriods;
  final String skippedPeriods;
  final String hairGrowth;
  final String acne;
  final String weightGain;
  final String lowEnergy;
  final String bodyChanges;
  final String medicalHistory;

  Map<String, dynamic> toJson() {
    return {
      'irregular_periods': irregularPeriods.toLowerCase(),
      'skipped_periods': skippedPeriods.toLowerCase(),
      'hair_growth': hairGrowth.toLowerCase(),
      'acne': acne.toLowerCase(),
      'weight_gain': weightGain.toLowerCase(),
      'low_energy': lowEnergy.toLowerCase(),
      'body_changes': bodyChanges,
      'medical_history': medicalHistory,
    };
  }
}

class PredictorResponse {
  const PredictorResponse({
    required this.score,
    required this.riskLevel,
    required this.analysis,
  });

  final num score;
  final String riskLevel;
  final String analysis;

  String get formattedScore {
    if (score % 1 == 0) {
      return score.toInt().toString();
    }
    return score.toString();
  }

  factory PredictorResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawScore = json['score'];
    num parsedScore = 0;
    if (rawScore is num) {
      parsedScore = rawScore;
    } else {
      parsedScore = num.tryParse(rawScore?.toString() ?? '0') ?? 0;
    }

    return PredictorResponse(
      score: parsedScore,
      riskLevel: json['risk_level']?.toString() ?? 'Unknown',
      analysis: json['analysis']?.toString() ?? 'No analysis available.',
    );
  }
}

const List<PredictorQuestion> predictorQuestions = <PredictorQuestion>[
  PredictorQuestion(
    key: 'irregular_periods',
    title: 'Do you have irregular periods?',
    isBoolean: true,
  ),
  PredictorQuestion(
    key: 'skipped_periods',
    title: 'Do you often skip periods?',
    isBoolean: true,
  ),
  PredictorQuestion(
    key: 'hair_growth',
    title: 'Do you notice excess facial/body hair growth?',
    isBoolean: true,
  ),
  PredictorQuestion(
    key: 'acne',
    title: 'Do you experience frequent acne breakouts?',
    isBoolean: true,
  ),
  PredictorQuestion(
    key: 'weight_gain',
    title: 'Have you experienced recent unexplained weight gain?',
    isBoolean: true,
  ),
  PredictorQuestion(
    key: 'low_energy',
    title: 'Do you regularly feel low energy or fatigue?',
    isBoolean: true,
  ),
  PredictorQuestion(
    key: 'body_changes',
    title: 'Describe any noticeable body changes in detail.',
    hint: 'Example: bloating, hair thinning, mood shifts, sleep changes.',
    isBoolean: false,
  ),
  PredictorQuestion(
    key: 'medical_history',
    title: 'Share relevant medical history and ongoing medications.',
    hint: 'Include prior diagnosis, thyroid issues, diabetes, etc.',
    isBoolean: false,
  ),
];
