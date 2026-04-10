import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_widget.dart';

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
  late DateTime _calendarMonth;
  late DateTime _calendarSelected;
  DateTime? _manualCycleStart;
  int? _manualCycleLength;
  int? _manualPeriodLength;
  bool _isMenstrualExpanded = false;

  final List<String> _flowOptions = ['light', 'medium', 'heavy'];
  final List<String> _moodOptions = ['low', 'normal', 'good', 'great'];

  @override
  void initState() {
    super.initState();
    _model = CycleModuleModel(userId: widget.userId);
    _calendarSelected = DateTime.now();
    _calendarMonth = DateTime(_calendarSelected.year, _calendarSelected.month);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _model.fetchCycles();
      await _model.fetchDailyLogs();
      await _model.fetchCurrentCycleSummary();
      await _model.fetchMonthCalendarSummary(_calendarMonth);
      await _model.fetchMonthlyDailyLogs(_calendarMonth);

      if (!mounted) {
        return;
      }

      final latest = _latestCycleRecord;
      if (latest != null) {
        setState(() {
          _calendarSelected = _normalize(latest.startDate);
          _calendarMonth = DateTime(
            latest.startDate.year,
            latest.startDate.month,
          );
        });
      }
    });
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
    final selected = await _showStyledCalendarPicker(initialDate: initialDate);

    if (selected != null) {
      onDatePicked(selected);
    }
  }

  Future<DateTime?> _showStyledCalendarPicker({
    required DateTime initialDate,
  }) async {
    final normalizedInitial = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        DateTime selectedDate = normalizedInitial;
        DateTime displayedMonth = DateTime(
          normalizedInitial.year,
          normalizedInitial.month,
        );

        const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

        List<DateTime> monthCells(DateTime month) {
          final firstOfMonth = DateTime(month.year, month.month, 1);
          final leading = firstOfMonth.weekday % 7;
          final start = firstOfMonth.subtract(Duration(days: leading));
          return List.generate(
            42,
            (index) => DateTime(start.year, start.month, start.day + index),
          );
        }

        String monthTitle(DateTime date) {
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
          return monthNames[date.month - 1];
        }

        bool isSameDate(DateTime a, DateTime b) {
          return a.year == b.year && a.month == b.month && a.day == b.day;
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final today = DateTime.now();
            final normalizedToday = DateTime(
              today.year,
              today.month,
              today.day,
            );
            final cells = monthCells(displayedMonth);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 30,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setModalState(() {
                            displayedMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month - 1,
                            );
                          }),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFF3D3441),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          monthTitle(displayedMonth),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C232F),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${displayedMonth.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF49404E),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setModalState(() {
                            displayedMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month + 1,
                            );
                          }),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF3D3441),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final weekday in weekdays)
                          Expanded(
                            child: Center(
                              child: Text(
                                weekday,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7D7381),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: cells.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final date = cells[index];
                        final inCurrentMonth =
                            date.month == displayedMonth.month &&
                            date.year == displayedMonth.year;
                        final isSelected = isSameDate(date, selectedDate);
                        final isToday = isSameDate(date, normalizedToday);

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setModalState(() => selectedDate = date);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFF8DDEB)
                                  : Colors.transparent,
                              border: isToday
                                  ? Border.all(
                                      color: const Color(0xFFD24787),
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                            child: Text(
                              '${date.day}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: !inCurrentMonth
                                    ? const Color(0xFFC5BEC9)
                                    : (isSelected
                                          ? const Color(0xFFD24787)
                                          : const Color(0xFF342D3A)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6F6678),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(selectedDate);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD24787),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Done',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Future<void> _openDailyLogDialog() async {
    final symptomsController = TextEditingController(
      text: _model.symptomsController.text,
    );
    final sleepController = TextEditingController(
      text: _model.sleepController.text,
    );
    final waterController = TextEditingController(
      text: _model.waterController.text,
    );

    String selectedFlow = _model.selectedFlow;
    String selectedMood = _model.selectedMood;
    bool didExercise = _model.didExercise;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final inputDecoration = InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8F4F7),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF675E70),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEADCE3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFD24787),
                  width: 1.4,
                ),
              ),
            );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1E3EA)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF9DEE9),
                              border: Border.all(
                                color: const Color(0xFFF2C7D8),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFFD24787),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save Daily Log',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF241D28),
                                  ),
                                ),
                                Text(
                                  _formatDate(_calendarSelected),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6D6675),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedFlow,
                              decoration: inputDecoration.copyWith(
                                labelText: 'Flow',
                              ),
                              items: _flowOptions
                                  .map(
                                    (flow) => DropdownMenuItem<String>(
                                      value: flow,
                                      child: Text(
                                        flow,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setModalState(() => selectedFlow = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedMood,
                              decoration: inputDecoration.copyWith(
                                labelText: 'Mood',
                              ),
                              items: _moodOptions
                                  .map(
                                    (mood) => DropdownMenuItem<String>(
                                      value: mood,
                                      child: Text(
                                        mood,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setModalState(() => selectedMood = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: symptomsController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Symptoms (comma separated)',
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sleepController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: inputDecoration.copyWith(
                                labelText: 'Sleep (hrs)',
                              ),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: waterController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: inputDecoration.copyWith(
                                labelText: 'Water (L)',
                              ),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F2F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEADCE3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () =>
                                    setModalState(() => didExercise = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: didExercise
                                        ? const Color(0xFFD24787)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Exercise: Yes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: didExercise
                                          ? Colors.white
                                          : const Color(0xFF554D5D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () =>
                                    setModalState(() => didExercise = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !didExercise
                                        ? const Color(0xFFD24787)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Exercise: No',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: !didExercise
                                          ? Colors.white
                                          : const Color(0xFF554D5D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                FocusScope.of(dialogContext).unfocus();
                                Navigator.of(dialogContext).pop(false);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                side: const BorderSide(
                                  color: Color(0xFFD7CCD3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5C5565),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final sleep = double.tryParse(
                                  sleepController.text.trim(),
                                );
                                final water = double.tryParse(
                                  waterController.text.trim(),
                                );

                                if (sleep == null ||
                                    sleep < 0 ||
                                    water == null ||
                                    water < 0) {
                                  if (!mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enter valid sleep and water values.',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red.shade600,
                                    ),
                                  );
                                  return;
                                }

                                _model.symptomsController.text =
                                    symptomsController.text.trim();
                                _model.sleepController.text = sleepController
                                    .text
                                    .trim();
                                _model.waterController.text = waterController
                                    .text
                                    .trim();
                                _model.setFlow(selectedFlow);
                                _model.setMood(selectedMood);
                                _model.setExercise(didExercise);
                                _model.setLogDate(_calendarSelected);

                                FocusScope.of(dialogContext).unfocus();
                                Navigator.of(dialogContext).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                backgroundColor: const Color(0xFFD24787),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Save Log',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    FocusManager.instance.primaryFocus?.unfocus();
    symptomsController.dispose();
    sleepController.dispose();
    waterController.dispose();

    if (shouldSave == true && mounted) {
      await _submitDailyLog();
    }
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

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _safeInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  Future<void> _openCycleSetupDialog() async {
    String cycleText =
        _manualCycleLength?.toString() ??
        _model.cycleLengthController.text.trim();
    String periodText =
        _manualPeriodLength?.toString() ??
        _model.periodLengthController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, _) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Cycle Setup',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: cycleText,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cycle Length (days)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => cycleText = value,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: periodText,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Period Length (days)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => periodText = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cycle = int.tryParse(cycleText.trim());
                    final period = int.tryParse(periodText.trim());

                    if (cycle == null ||
                        cycle <= 0 ||
                        period == null ||
                        period <= 0) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter valid cycle and period lengths.',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _manualCycleLength = cycle;
                      _manualPeriodLength = period;
                      _manualCycleStart ??= _normalize(_calendarSelected);
                    });

                    _model.cycleLengthController.text = '$cycle';
                    _model.periodLengthController.text = '$period';

                    FocusScope.of(dialogContext).unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD24787),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  CycleRecord? get _latestCycleRecord {
    if (_model.cycles.isEmpty) {
      return null;
    }
    final sorted = List<CycleRecord>.from(_model.cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted.first;
  }

  DateTime get _cycleStart {
    final summaryStart = _model.currentCycleSummary?.currentCycleStart;
    if (summaryStart != null) {
      return _normalize(summaryStart);
    }
    if (_manualCycleStart != null) {
      return _normalize(_manualCycleStart!);
    }
    final latest = _latestCycleRecord;
    return _normalize(latest?.startDate ?? _model.cycleStartDate);
  }

  int get _cycleLength {
    final summaryLength = _model.currentCycleSummary?.cycleLength;
    if (summaryLength != null && summaryLength > 0) {
      return summaryLength;
    }
    if (_manualCycleLength != null) {
      return _manualCycleLength!;
    }
    final latest = _latestCycleRecord;
    return latest?.cycleLength ??
        _safeInt(_model.cycleLengthController.text, 28);
  }

  int get _periodLength {
    final summaryLength = _model.currentCycleSummary?.periodLength;
    if (summaryLength != null && summaryLength > 0) {
      return summaryLength;
    }
    if (_manualPeriodLength != null) {
      return _manualPeriodLength!;
    }
    final latest = _latestCycleRecord;
    return latest?.periodLength ??
        _safeInt(_model.periodLengthController.text, 5);
  }

  DateTime get _predictedPeriodStart {
    final summaryDate = _model.currentCycleSummary?.predictedNextPeriod;
    if (summaryDate != null) {
      return _normalize(summaryDate);
    }
    if (_manualCycleStart != null) {
      return _normalize(_cycleStart.add(Duration(days: _cycleLength)));
    }
    final latest = _latestCycleRecord;
    if (latest?.predictedNext != null) {
      return _normalize(latest!.predictedNext!);
    }
    return _normalize(_cycleStart.add(Duration(days: _cycleLength)));
  }

  DateTime get _ovulationDate {
    final summaryDate = _model.currentCycleSummary?.ovulationDate;
    if (summaryDate != null) {
      return _normalize(summaryDate);
    }
    if (_manualCycleStart != null || _manualCycleLength != null) {
      return _normalize(
        _cycleStart.add(Duration(days: (_cycleLength - 14).clamp(8, 25))),
      );
    }

    final latest = _latestCycleRecord;
    if (latest?.ovulationDate != null) {
      return _normalize(latest!.ovulationDate!);
    }
    return _normalize(
      _cycleStart.add(Duration(days: (_cycleLength - 14).clamp(8, 25))),
    );
  }

  String _calendarMonthText(DateTime date) {
    const names = [
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
    return names[date.month - 1];
  }

  String _prettyMonthDay(DateTime date) {
    return '${_calendarMonthText(date)} ${date.day}';
  }

  List<DateTime> _monthCells(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday % 7;
    final start = first.subtract(Duration(days: leading));
    return List.generate(
      42,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  bool _isPeriodDay(DateTime date) {
    final normalized = _normalize(date);
    final start = _cycleStart;
    final end = _cycleStart.add(Duration(days: _periodLength - 1));
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  bool _isPredictedPeriodDay(DateTime date) {
    final normalized = _normalize(date);
    final start = _predictedPeriodStart;
    final end = start.add(Duration(days: _periodLength - 1));
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  bool _isFertileWindowDay(DateTime date) {
    final normalized = _normalize(date);
    final start = _ovulationDate.subtract(const Duration(days: 4));
    final end = _ovulationDate.add(const Duration(days: 1));
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  int get _daysSinceLastPeriod {
    final summaryDays = _model.currentCycleSummary?.daysSinceLastPeriod;
    if (summaryDays != null) {
      return summaryDays;
    }
    final now = _normalize(DateTime.now());
    return now.difference(_cycleStart).inDays.clamp(0, 9999);
  }

  MonthCalendarDay? _backendDayFor(DateTime date) {
    final days = _model.currentMonthCalendar?.days;
    if (days == null || days.isEmpty) {
      return null;
    }

    for (final day in days) {
      if (_sameDay(day.date, date)) {
        return day;
      }
    }

    return null;
  }

  String _statusLabelForCalendarDay(MonthCalendarDay? day) {
    if (day == null) return 'normal_day';
    return day.status;
  }

  Color _statusColorForCalendarDay(MonthCalendarDay? day) {
    switch (_statusLabelForCalendarDay(day)) {
      case 'period_day':
        return const Color(0xFFF6D5E3);
      case 'predicted_period_day':
        return const Color(0xFFFDE3C5);
      case 'fertile_window_day':
        return const Color(0xFFD7D6FF);
      case 'ovulation_day':
        return const Color(0xFFC9F0E5);
      default:
        return const Color(0xFFF8F8F9);
    }
  }

  String _calendarStatusTag(MonthCalendarDay? day) {
    switch (_statusLabelForCalendarDay(day)) {
      case 'period_day':
        return 'Period';
      case 'predicted_period_day':
        return 'Predicted';
      case 'fertile_window_day':
        return 'Fertile';
      case 'ovulation_day':
        return 'Ovulation';
      default:
        return 'Normal';
    }
  }

  Widget _buildCycleSummaryCard() {
    final summary = _model.currentCycleSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final confidence =
        summary.confidence?.level ??
        (summary.confidence?.score != null
            ? '${(summary.confidence!.score! * 100).round()}% confidence'
            : 'Confidence unavailable');

    String formatSummaryDate(DateTime? date) {
      if (date == null) return '-';
      return '${_calendarMonthText(date)} ${date.day}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8DCE0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _isMenstrualExpanded = !_isMenstrualExpanded;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF9DEE9),
                    border: Border.all(color: const Color(0xFFF2C7D8)),
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    size: 18,
                    color: Color(0xFFD24787),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary.currentPhase ?? 'Cycle Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241D28),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isMenstrualExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: Color(0xFF6D6675),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            crossFadeState: _isMenstrualExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.phaseRule ?? confidence,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6D6675),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryChip(
                        'Start',
                        formatSummaryDate(summary.currentCycleStart),
                      ),
                      _summaryChip(
                        'Next',
                        formatSummaryDate(summary.predictedNextPeriod),
                      ),
                      _summaryChip(
                        'Ovulation',
                        formatSummaryDate(summary.ovulationDate),
                      ),
                      _summaryChip(
                        'Fertile',
                        '${formatSummaryDate(summary.fertileWindowStart)} - ${formatSummaryDate(summary.fertileWindowEnd)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tap to view cycle details',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF817989),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9DEE4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7B7380),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF241D28),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCalendarDate() async {
    final picked = await _showStyledCalendarPicker(
      initialDate: _calendarSelected,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _calendarSelected = _normalize(picked);
      _calendarMonth = DateTime(picked.year, picked.month);
      _manualCycleStart = _normalize(picked);
    });
    _model.setCycleStartDate(picked);
    await _model.fetchMonthCalendarSummary(_calendarMonth);
    await _model.fetchMonthlyDailyLogs(_calendarMonth);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        final cells = _monthCells(_calendarMonth);
        const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => HomeWidget(
                                userId: widget.userId,
                                fullName: widget.fullName,
                              ),
                            ),
                          );
                        },
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEDEDEF),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF231A28),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Cycle Tracker',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF161217),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          onPressed: _openCycleSetupDialog,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Color(0xFF221A27),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_model.currentCycleSummary != null) ...[
                    _buildCycleSummaryCard(),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFECE8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _pickCalendarDate,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: Color(0xFFD24787),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _calendarMonthText(_calendarMonth),
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F1724),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: Color(0xFFD24787),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '${_calendarMonth.year}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6D6675),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (final d in weekdayLabels)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF8A7E8A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cells.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 6,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final date = cells[index];
                            final inMonth = date.month == _calendarMonth.month;
                            final isSelected = _sameDay(
                              date,
                              _calendarSelected,
                            );
                            final backendDay = _backendDayFor(date);
                            final backendStatus = _statusLabelForCalendarDay(
                              backendDay,
                            );
                            final isPeriod =
                                backendStatus == 'period_day' ||
                                (backendDay == null && _isPeriodDay(date));
                            final isPredicted =
                                backendStatus == 'predicted_period_day' ||
                                (backendDay == null &&
                                    _isPredictedPeriodDay(date));
                            final isFertile =
                                backendStatus == 'fertile_window_day' ||
                                (backendDay == null &&
                                    _isFertileWindowDay(date));
                            final isOvulation =
                                backendStatus == 'ovulation_day';

                            Color textColor;
                            if (!inMonth) {
                              textColor = const Color(0xFFB4B0B8);
                            } else {
                              textColor = const Color(0xFF221C27);
                            }

                            BoxDecoration? decoration;
                            if (backendDay != null || inMonth) {
                              decoration = BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColorForCalendarDay(backendDay),
                              );
                            }

                            Border? border;
                            if (isSelected) {
                              border = Border.all(
                                color: const Color(0xFF5956D6),
                                width: 1.3,
                              );
                            } else if (isPredicted) {
                              border = Border.all(
                                color: const Color(0xFFD24787),
                                width: 1.2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              );
                            } else if (isOvulation) {
                              border = Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 1.2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              );
                            }

                            String statusLabel = '';
                            if (isPeriod && inMonth) {
                              statusLabel = 'P';
                            } else if (isFertile && inMonth) {
                              statusLabel = 'F';
                            } else if (isOvulation && inMonth) {
                              statusLabel = 'O';
                            }

                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                final picked = _normalize(date);
                                setState(() {
                                  _calendarSelected = picked;
                                  _manualCycleStart = picked;
                                });
                                _model.setCycleStartDate(picked);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration:
                                    (decoration ??
                                            const BoxDecoration(
                                              shape: BoxShape.circle,
                                            ))
                                        .copyWith(border: border),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${date.day}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    if (statusLabel.isNotEmpty)
                                      Text(
                                        statusLabel,
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF8FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _buildLegendItem(
                          const Color(0xFFF6D5E3),
                          'P',
                          'Period',
                        ),
                        _buildLegendItem(
                          const Color(0xFFFDE3C5),
                          'Pd',
                          'Predicted',
                        ),
                        _buildLegendItem(
                          const Color(0xFFD7D6FF),
                          'F',
                          'Fertile',
                        ),
                        _buildLegendItem(
                          const Color(0xFFC9F0E5),
                          'O',
                          'Ovulation',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF07AB1), Color(0xFFE85E9C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE85E9C).withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 24,
                          color: Color(0xFFFFFFFF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _model.currentCycleSummary?.predictedNextPeriod ==
                                    null
                                ? 'Your next period is being calculated from your cycle history.'
                                : 'Your period is likely to start on or around ${_prettyMonthDay(_predictedPeriodStart)}.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_model.fetchCyclesError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _model.fetchCyclesError!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _model.isSubmittingCycle
                              ? null
                              : () {
                                  final cycleLength = int.tryParse(
                                    _model.cycleLengthController.text.trim(),
                                  );
                                  final periodLength = int.tryParse(
                                    _model.periodLengthController.text.trim(),
                                  );

                                  if (cycleLength == null ||
                                      cycleLength <= 0 ||
                                      periodLength == null ||
                                      periodLength <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please tap the + icon and enter cycle length and period length first.',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red.shade600,
                                      ),
                                    );
                                    return;
                                  }

                                  _model.setCycleStartDate(_calendarSelected);
                                  _submitCycle();
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(
                              color: Color(0xFFD24787),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _model.isSubmittingCycle
                                ? 'Saving...'
                                : 'Save Cycle Start',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD24787),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD24787).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _model.isSubmittingLog
                                ? null
                                : _openDailyLogDialog,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: const Color(0xFFD24787),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _model.isSubmittingLog
                                  ? 'Saving...'
                                  : 'Save Daily Log',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF5F3F6),
                          ),
                          child: TextButton.icon(
                            onPressed: _openCycleHistoryDialog,
                            icon: const Icon(
                              Icons.calendar_view_month_rounded,
                              color: Color(0xFFD24787),
                              size: 20,
                            ),
                            label: Text(
                              'Cycle History',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD24787),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF5F3F6),
                          ),
                          child: TextButton.icon(
                            onPressed: _openDailyLogHistoryDialog,
                            icon: const Icon(
                              Icons.fact_check_rounded,
                              color: Color(0xFF7B1FA2),
                              size: 20,
                            ),
                            label: Text(
                              'Logs History',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7B1FA2),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _legendPredictedDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFFD24787), width: 1.1),
      ),
    );
  }

  Widget _legendLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF28242C),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String abbr, String label) {
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: color.withOpacity(0.4), width: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5D5560),
            ),
          ),
        ],
      ),
    );
  }
}
