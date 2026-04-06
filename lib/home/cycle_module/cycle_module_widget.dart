import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/app_theme.dart';

import 'cycle_module_model.dart';
import 'services/cycle_api_service.dart';

class CycleModuleWidget extends StatefulWidget {
  const CycleModuleWidget({
    required this.userId,
    required this.fullName,
    super.key,
  });

  final String userId;
  final String fullName;

  @override
  State<CycleModuleWidget> createState() => _CycleModuleWidgetState();
}

class _CycleModuleWidgetState extends State<CycleModuleWidget> {
  late final CycleModuleModel _model;

  final List<String> _flowOptions = ['light', 'medium', 'heavy'];
  final List<String> _moodOptions = ['low', 'normal', 'good', 'great'];

  @override
  void initState() {
    super.initState();
    _model = CycleModuleModel(userId: widget.userId);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onDatePicked,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      onDatePicked(selected);
    }
  }

  Future<void> _submitCycle() async {
    final success = await _model.submitCycle();
    if (!mounted) {
      return;
    }

    final message = success
        ? (_model.addCycleMessage ?? 'Cycle Added')
        : (_model.addCycleError ?? 'Unable to add cycle');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : Colors.red.shade600,
      ),
    );
  }

  Future<void> _submitDailyLog() async {
    final success = await _model.submitDailyLog();
    if (!mounted) {
      return;
    }

    final message = success
        ? (_model.addLogMessage ?? 'Log saved')
        : (_model.addLogError ?? 'Unable to save log');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : Colors.red.shade600,
      ),
    );
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _monthLabel(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  List<MapEntry<String, List<CycleRecord>>> _groupCyclesByMonth(
    List<CycleRecord> cycles,
  ) {
    final sortedCycles = List<CycleRecord>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final grouped = <String, List<CycleRecord>>{};
    for (final cycle in sortedCycles) {
      final key = _monthKey(cycle.startDate);
      grouped.putIfAbsent(key, () => <CycleRecord>[]).add(cycle);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  Widget _buildCycleHistoryItem({
    required CycleRecord cycle,
    required int index,
    bool compact = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5DCE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Cycle ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.favorite_rounded,
                size: 16,
                color: const Color(0xFFE91E63).withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Start: ${_formatDate(cycle.startDate)}   End: ${cycle.endDate != null ? _formatDate(cycle.endDate!) : '-'}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF4D4556),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cycle: ${cycle.cycleLength} days   Period: ${cycle.periodLength} days',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF4D4556),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ovulation: ${cycle.ovulationDate != null ? _formatDate(cycle.ovulationDate!) : '-'}   Next: ${cycle.predictedNext != null ? _formatDate(cycle.predictedNext!) : '-'}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF4D4556),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogHistoryItem({
    required DailyLogRecord log,
    bool compact = false,
  }) {
    final symptomsText = log.symptoms.isEmpty
        ? 'None'
        : log.symptoms.join(', ');

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE1F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  log.date,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                log.exercise
                    ? Icons.fitness_center_rounded
                    : Icons.hotel_rounded,
                size: 16,
                color: const Color(0xFF7B1FA2).withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Flow: ${log.flow.toUpperCase()}   Mood: ${log.mood.toUpperCase()}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF4D4556),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sleep: ${log.sleep} hrs   Water: ${log.water} L   Exercise: ${log.exercise ? 'Yes' : 'No'}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF4D4556),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Symptoms: $symptomsText',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF4D4556),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCycleHistoryDialog() async {
    if (_model.cycles.isEmpty && !_model.isFetchingCycles) {
      await _model.fetchCycles();
    }
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxWidth = MediaQuery.of(dialogContext).size.width * 0.92;
        final maxHeight = MediaQuery.of(dialogContext).size.height * 0.78;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: AnimatedBuilder(
            animation: _model,
            builder: (context, _) {
              final monthGroups = _groupCyclesByMonth(_model.cycles);

              return Container(
                width: maxWidth > 420 ? 420 : maxWidth,
                height: maxHeight > 620 ? 620 : maxHeight,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFBFD),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cycle History',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2A2230),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _model.isFetchingCycles
                              ? null
                              : _model.fetchCycles,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      'Sorted by month (latest first)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C7385),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _model.isFetchingCycles
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                              ),
                            )
                          : _model.fetchCyclesError != null
                          ? Center(
                              child: Text(
                                _model.fetchCyclesError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : _model.cycles.isEmpty
                          ? Center(
                              child: Text(
                                'No cycle records available yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7383),
                                ),
                              ),
                            )
                          : Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final group in monthGroups) ...[
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEDF4),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          _monthLabel(
                                            group.value.first.startDate,
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFE91E63),
                                          ),
                                        ),
                                      ),
                                      for (
                                        int i = 0;
                                        i < group.value.length;
                                        i++
                                      )
                                        _buildCycleHistoryItem(
                                          cycle: group.value[i],
                                          index: i,
                                          compact: true,
                                        ),
                                      const SizedBox(height: 4),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openDailyLogHistoryDialog() async {
    if (_model.dailyLogs.isEmpty && !_model.isFetchingLogs) {
      await _model.fetchDailyLogs();
    }
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxWidth = MediaQuery.of(dialogContext).size.width * 0.92;
        final maxHeight = MediaQuery.of(dialogContext).size.height * 0.78;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: AnimatedBuilder(
            animation: _model,
            builder: (context, _) {
              final sortedLogs = List<DailyLogRecord>.from(_model.dailyLogs)
                ..sort((a, b) => b.date.compareTo(a.date));

              return Container(
                width: maxWidth > 420 ? 420 : maxWidth,
                height: maxHeight > 620 ? 620 : maxHeight,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFBFD),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Daily Logs History',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2A2230),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _model.isFetchingLogs
                              ? null
                              : _model.fetchDailyLogs,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF7B1FA2),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      'All saved daily wellness logs (latest first)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C7385),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _model.isFetchingLogs
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                              ),
                            )
                          : _model.fetchLogsError != null
                          ? Center(
                              child: Text(
                                _model.fetchLogsError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : sortedLogs.isEmpty
                          ? Center(
                              child: Text(
                                'No daily logs available yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7383),
                                ),
                              ),
                            )
                          : Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final log in sortedLogs)
                                      _buildDailyLogHistoryItem(
                                        log: log,
                                        compact: true,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6D6474),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF9A92A2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F5FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9E0EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.4),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF514C57),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _inputDecoration(label: label, hint: hint),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1A22),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF746C7B),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF4DAE7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFE91E63)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF433A49),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurfaceCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFCFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71453), Color(0xFFE94882), Color(0xFFF785A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -14,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cycle Care',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track trends and symptom patterns to stay one step ahead.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_model.cycleLengthController.text} d',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Cycle Length',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_model.periodLengthController.text} d',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Period Length',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_model.cycles.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Saved Cycles',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = AppTheme.brandPrimary;

    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.brandInk,
            elevation: 0,
            centerTitle: false,
            title: Text(
              'Cycle Tracker',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandInk,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _model.isFetchingCycles ? null : _model.fetchCycles,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: AppTheme.pageBackgroundDecoration(),
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -90,
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE91E63).withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  top: 140,
                  left: -70,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF48FB1).withValues(alpha: 0.15),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 14),
                        _buildSurfaceCard(
                          children: [
                            _buildSectionTitle(
                              title: 'Add Cycle',
                              subtitle:
                                  'Save your cycle start and duration details',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDatePickerChip(
                                    label:
                                        'Start ${_formatDate(_model.cycleStartDate)}',
                                    icon: Icons.event_available_rounded,
                                    onTap: () => _pickDate(
                                      initialDate: _model.cycleStartDate,
                                      onDatePicked: _model.setCycleStartDate,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDatePickerChip(
                                    label: _model.cycleEndDate == null
                                        ? 'End Optional'
                                        : 'End ${_formatDate(_model.cycleEndDate!)}',
                                    icon: Icons.event_note_rounded,
                                    onTap: () => _pickDate(
                                      initialDate:
                                          _model.cycleEndDate ??
                                          _model.cycleStartDate,
                                      onDatePicked: _model.setCycleEndDate,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInput(
                                    label: 'Cycle Length',
                                    controller: _model.cycleLengthController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInput(
                                    label: 'Period Length',
                                    controller: _model.periodLengthController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            if (_model.addCycleError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _model.addCycleError!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _model.isSubmittingCycle
                                    ? null
                                    : _submitCycle,
                                icon: _model.isSubmittingCycle
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  _model.isSubmittingCycle
                                      ? 'Saving...'
                                      : 'Save Cycle',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSurfaceCard(
                          children: [
                            _buildSectionTitle(
                              title: 'Daily Log',
                              subtitle: 'Track mood, flow, and wellness habits',
                            ),
                            const SizedBox(height: 12),
                            _buildDatePickerChip(
                              label: 'Log Date ${_formatDate(_model.logDate)}',
                              icon: Icons.calendar_month_rounded,
                              onTap: () => _pickDate(
                                initialDate: _model.logDate,
                                onDatePicked: _model.setLogDate,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _model.selectedFlow,
                                    items: _flowOptions
                                        .map(
                                          (e) => DropdownMenuItem<String>(
                                            value: e,
                                            child: Text(
                                              e.toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _model.setFlow(value);
                                      }
                                    },
                                    decoration: _inputDecoration(label: 'Flow'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _model.selectedMood,
                                    items: _moodOptions
                                        .map(
                                          (e) => DropdownMenuItem<String>(
                                            value: e,
                                            child: Text(
                                              e.toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _model.setMood(value);
                                      }
                                    },
                                    decoration: _inputDecoration(label: 'Mood'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInput(
                              label: 'Symptoms (comma separated)',
                              controller: _model.symptomsController,
                              hint: 'cramps, headache',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInput(
                                    label: 'Sleep Hours',
                                    controller: _model.sleepController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInput(
                                    label: 'Water Intake (L)',
                                    controller: _model.waterController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7FB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFF4DAE7),
                                ),
                              ),
                              child: SwitchListTile.adaptive(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                activeColor: primary,
                                title: Text(
                                  'Exercise done today',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4A4152),
                                  ),
                                ),
                                value: _model.didExercise,
                                onChanged: _model.setExercise,
                              ),
                            ),
                            if (_model.addLogError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _model.addLogError!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _model.isSubmittingLog
                                    ? null
                                    : _submitDailyLog,
                                icon: _model.isSubmittingLog
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.edit_note_rounded),
                                label: Text(
                                  _model.isSubmittingLog
                                      ? 'Saving...'
                                      : 'Save Daily Log',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSurfaceCard(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _openCycleHistoryDialog,
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7FB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF4DAE7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 38,
                                      width: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE3EE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_view_month_rounded,
                                        color: Color(0xFFE91E63),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cycle History',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF2A2230),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tap to open fixed-size monthly timeline',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: const Color(0xFF7A7383),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Color(0xFF8B8295),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _openDailyLogHistoryDialog,
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F1FC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE8D9F1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 38,
                                      width: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFE1F7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.fact_check_rounded,
                                        color: Color(0xFF7B1FA2),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Daily Logs History',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF2A2230),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tap to view all saved daily logs',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: const Color(0xFF7A7383),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Color(0xFF8B8295),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
