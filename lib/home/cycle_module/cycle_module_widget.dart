import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cycle_module_model.dart';

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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9A95A1),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFE91E63);
    const Color background = Color(0xFFF8F2F5);

    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            title: Text(
              '${widget.fullName} • Cycle Module',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1B20),
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Cycle',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D1B20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDate(
                                  initialDate: _model.cycleStartDate,
                                  onDatePicked: _model.setCycleStartDate,
                                ),
                                icon: const Icon(
                                  Icons.event_available,
                                  size: 16,
                                ),
                                label: Text(
                                  'Start ${_formatDate(_model.cycleStartDate)}',
                                  style: GoogleFonts.poppins(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDate(
                                  initialDate:
                                      _model.cycleEndDate ??
                                      _model.cycleStartDate,
                                  onDatePicked: _model.setCycleEndDate,
                                ),
                                icon: const Icon(Icons.event_note, size: 16),
                                label: Text(
                                  _model.cycleEndDate == null
                                      ? 'End Optional'
                                      : 'End ${_formatDate(_model.cycleEndDate!)}',
                                  style: GoogleFonts.poppins(fontSize: 11),
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
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _model.addCycleError!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _model.isSubmittingCycle
                                ? null
                                : _submitCycle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _model.isSubmittingCycle
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Cycle',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Daily Log',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D1B20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(
                            initialDate: _model.logDate,
                            onDatePicked: _model.setLogDate,
                          ),
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            'Log Date ${_formatDate(_model.logDate)}',
                            style: GoogleFonts.poppins(fontSize: 12),
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
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
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
                                decoration: InputDecoration(
                                  labelText: 'Flow',
                                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _model.selectedMood,
                                items: _moodOptions
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
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
                                decoration: InputDecoration(
                                  labelText: 'Mood',
                                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInput(
                          label: 'Symptoms (comma separated)',
                          controller: _model.symptomsController,
                          hint: 'cramps, bloating',
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
                        const SizedBox(height: 6),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Exercise done',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: _model.didExercise,
                          onChanged: _model.setExercise,
                        ),
                        if (_model.addLogError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _model.addLogError!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _model.isSubmittingLog
                                ? null
                                : _submitDailyLog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _model.isSubmittingLog
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Daily Log',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D1B20),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _model.isFetchingCycles
                                  ? null
                                  : _model.fetchCycles,
                              child: Text('Load', style: GoogleFonts.poppins()),
                            ),
                          ],
                        ),
                        if (_model.fetchCyclesError != null)
                          Text(
                            _model.fetchCyclesError!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.red.shade600,
                            ),
                          ),
                        if (_model.isFetchingCycles)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          )
                        else if (_model.cycles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No cycles found. Enter user ID and tap Load.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF7F7986),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _model.cycles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final cycle = _model.cycles[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cycle ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1D1B20),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Start: ${_formatDate(cycle.startDate)}  End: ${cycle.endDate != null ? _formatDate(cycle.endDate!) : '-'}',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                    Text(
                                      'Cycle Length: ${cycle.cycleLength}  Period Length: ${cycle.periodLength}',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                    Text(
                                      'Ovulation: ${cycle.ovulationDate != null ? _formatDate(cycle.ovulationDate!) : '-'}  Next: ${cycle.predictedNext != null ? _formatDate(cycle.predictedNext!) : '-'}',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
