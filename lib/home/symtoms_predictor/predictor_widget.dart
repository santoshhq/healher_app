import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'predictor_model.dart';
import 'services/predictor_api_service.dart';

class PredictorWidget extends StatefulWidget {
  const PredictorWidget({required this.fullName, super.key});

  final String fullName;

  @override
  State<PredictorWidget> createState() => _PredictorWidgetState();
}

class _PredictorWidgetState extends State<PredictorWidget> {
  static const int _questionsPerSlide = 2;

  final PredictorApiService _apiService = PredictorApiService();
  final Map<String, String> _answers = <String, String>{};
  final TextEditingController _bodyChangesController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();

  int _slideIndex = 0;
  bool _isSubmitting = false;
  PredictorResponse? _result;
  String? _error;

  final Color _primaryPink = const Color(0xFFD94F7C);
  final Color _textPrimary = const Color(0xFF1A1A1A);
  final Color _textSecondary = const Color(0xFF6B6B6B);

  int get _totalSlides =>
      (predictorQuestions.length / _questionsPerSlide).ceil();

  @override
  void dispose() {
    _bodyChangesController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  bool _isCurrentSlideValid() {
    final start = _slideIndex * _questionsPerSlide;
    final end = (start + _questionsPerSlide).clamp(
      0,
      predictorQuestions.length,
    );

    for (int i = start; i < end; i++) {
      final question = predictorQuestions[i];

      if (question.isBoolean) {
        final value = (_answers[question.key] ?? '').trim().toLowerCase();
        if (value != 'yes' && value != 'no') {
          return false;
        }
      } else {
        final value = _textValueFor(question.key).trim();
        if (value.isEmpty) {
          return false;
        }
      }
    }

    return true;
  }

  String _textValueFor(String key) {
    switch (key) {
      case 'body_changes':
        return _bodyChangesController.text;
      case 'medical_history':
        return _medicalHistoryController.text;
      default:
        return '';
    }
  }

  void _goNext() {
    if (!_isCurrentSlideValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer both questions to continue.'),
        ),
      );
      return;
    }

    if (_slideIndex < _totalSlides - 1) {
      setState(() {
        _slideIndex += 1;
      });
    }
  }

  void _goPrevious() {
    if (_slideIndex > 0) {
      setState(() {
        _slideIndex -= 1;
      });
    }
  }

  Future<void> _submit() async {
    if (!_isCurrentSlideValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete both questions first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final request = PredictorRequest(
      irregularPeriods: (_answers['irregular_periods'] ?? '').toLowerCase(),
      skippedPeriods: (_answers['skipped_periods'] ?? '').toLowerCase(),
      hairGrowth: (_answers['hair_growth'] ?? '').toLowerCase(),
      acne: (_answers['acne'] ?? '').toLowerCase(),
      weightGain: (_answers['weight_gain'] ?? '').toLowerCase(),
      lowEnergy: (_answers['low_energy'] ?? '').toLowerCase(),
      bodyChanges: _bodyChangesController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
    );

    try {
      final response = await _apiService.assess(request);
      if (!mounted) return;

      setState(() {
        _result = response;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'moderate':
        return const Color(0xFFEF6C00);
      case 'low':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Widget _buildBooleanQuestion(PredictorQuestion question) {
    final selected = (_answers[question.key] ?? '').toLowerCase();

    Widget option(String label, String value) {
      final isSelected = selected == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _answers[question.key] = value;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primaryPink : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryPink : Colors.grey.shade300,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              option('Yes', 'yes'),
              const SizedBox(width: 10),
              option('No', 'no'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextQuestion(PredictorQuestion question) {
    final controller = question.key == 'body_changes'
        ? _bodyChangesController
        : _medicalHistoryController;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          if (question.hint != null) ...[
            const SizedBox(height: 6),
            Text(
              question.hint!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Type your details here...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: _textSecondary,
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryPink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent() {
    final start = _slideIndex * _questionsPerSlide;
    final end = (start + _questionsPerSlide).clamp(
      0,
      predictorQuestions.length,
    );
    final items = predictorQuestions.sublist(start, end);

    return Column(
      children: items.map((question) {
        if (question.isBoolean) {
          return _buildBooleanQuestion(question);
        }
        return _buildTextQuestion(question);
      }).toList(),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final riskColor = _riskColor(result.riskLevel);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assessment Result',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Risk: ${result.riskLevel}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: riskColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Score: ${result.formattedScore}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              result.analysis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _result = null;
                  _slideIndex = 0;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primaryPink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Retake Assessment',
                style: GoogleFonts.plusJakartaSans(
                  color: _primaryPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _slideIndex == _totalSlides - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          _result == null ? 'Symptoms Predictor' : 'Prediction Result',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ),
      body: _result != null
          ? _buildResultView()
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi ${widget.fullName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Slide ${_slideIndex + 1} of $_totalSlides',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: _buildSlideContent(),
                  ),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF7C7C7)),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF9E2A2A),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      if (_slideIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : _goPrevious,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _primaryPink),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Previous',
                              style: GoogleFonts.plusJakartaSans(
                                color: _primaryPink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (_slideIndex > 0) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : (isLastSlide ? _submit : _goNext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPink,
                            disabledBackgroundColor: const Color(0xFFF2B9CC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isLastSlide ? 'Submit' : 'Next',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
