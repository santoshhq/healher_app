import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/foodscanner_api_service.dart';

// ─── Design Tokens (Aligned with App Theme) ─────────────────────────────────
class _ScannedFoodsDS {
  // Brand colors from AppTheme
  static const pageBg = Color(0xFFF8F3F5);
  static const cardBg = Color(0xFFFFFFFF);
  static const brandInk = Color(0xFF201425);
  static const brandPrimary = Color(0xFFDB3D74);
  static const textPrimary = Color(0xFF201425);
  static const textSecondary = Color(0xFF6F6574);
  static const textMuted = Color(0xFFB3ABB6);

  // Health Score Colors (from nutrition tab)
  static const scoreHealthy = Color(0xFF5FD4A3); // Green - 7-10
  static const scoreHealthyLight = Color(0xFFD1F3EC);
  static const scoreModerate = Color(0xFFFFC66D); // Orange - 4-6
  static const scoreModerateLight = Color(0xFFFEF4DE);
  static const scoreUnhealthy = Color(0xFFFF6B6B); // Red - 0-3
  static const scoreUnhealthyLight = Color(0xFFFFE8E8);

  // Radii
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;

  static TextStyle headline(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle bodyText(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? textSecondary,
      );
}

class ScannedFoodsPage extends StatefulWidget {
  const ScannedFoodsPage({super.key, required this.userId, this.limit = 50});

  final String userId;
  final int limit;

  @override
  State<ScannedFoodsPage> createState() => _ScannedFoodsPageState();
}

class _ScannedFoodsPageState extends State<ScannedFoodsPage> {
  final FoodScannerApiService _apiService = FoodScannerApiService();
  late Future<FoodHistoryResponse> _historyFuture;
  List<FoodScanHistoryItem> _allScans = [];
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<FoodHistoryResponse> _loadHistory() async {
    final response = await _apiService.getFoodHistory(
      userId: widget.userId,
      limit: widget.limit,
    );
    if (response.success) {
      _allScans = response.scans;
      _currentPage = 1;
    }
    return response;
  }

  Future<void> _refresh() async {
    setState(() {
      _allScans = [];
      _currentPage = 1;
    });
    final future = _loadHistory();
    setState(() {
      _historyFuture = future;
    });
    await future;
  }

  int get _totalPages => (_allScans.length / _itemsPerPage).ceil();

  List<FoodScanHistoryItem> get _currentPageItems {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _allScans.sublist(
      startIndex,
      endIndex > _allScans.length ? _allScans.length : endIndex,
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final month = _monthName(local.month);
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day • $hour:$minute $suffix';
  }

  String _monthName(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '-';
    return names[month - 1];
  }

  double _parseScore(String score) {
    try {
      final leftPart = score.split('/').first.trim();
      final parsed = double.tryParse(
        leftPart.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      return (parsed ?? 0).clamp(0, 10);
    } catch (_) {
      return 0;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 7) return _ScannedFoodsDS.scoreHealthy;
    if (score >= 4) return _ScannedFoodsDS.scoreModerate;
    return _ScannedFoodsDS.scoreUnhealthy;
  }

  Color _getScoreCardBgColor(double score) {
    if (score >= 7) return _ScannedFoodsDS.scoreHealthyLight;
    if (score >= 4) return _ScannedFoodsDS.scoreModerateLight;
    return _ScannedFoodsDS.scoreUnhealthyLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ScannedFoodsDS.pageBg,
      appBar: AppBar(
        backgroundColor: _ScannedFoodsDS.pageBg,
        elevation: 0,
        title: Text(
          'Scanned Foods',
          style: _ScannedFoodsDS.headline(22, weight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<FoodHistoryResponse>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: _ScannedFoodsDS.brandPrimary,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final response = snapshot.data;
          if (response == null || !response.success || response.scans.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _ScannedFoodsDS.brandPrimary,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Food Cards
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentPageItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _currentPageItems[index];
                        return _buildFoodScoreCard(item);
                      },
                    ),
                    const SizedBox(height: 24),
                    // Pagination
                    if (_totalPages > 1) _buildPaginationControls(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodScoreCard(FoodScanHistoryItem item) {
    final score = _parseScore(item.healthScore);
    final scoreColor = _getScoreColor(score);
    final scoreBgColor = _getScoreCardBgColor(score);

    return GestureDetector(
      onTap: () => _showFoodDetailsDialog(context, item, score, scoreColor),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _ScannedFoodsDS.cardBg,
          borderRadius: BorderRadius.circular(_ScannedFoodsDS.r14),
          border: Border.all(
            color: scoreColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scoreColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Food Name & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ScannedFoodsDS.headline(
                      15,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: _ScannedFoodsDS.bodyText(
                      11,
                      color: _ScannedFoodsDS.textMuted,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: Score Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scoreBgColor,
                borderRadius: BorderRadius.circular(_ScannedFoodsDS.r12),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: _ScannedFoodsDS.headline(
                      18,
                      color: scoreColor,
                      weight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '/10',
                    style: _ScannedFoodsDS.bodyText(
                      8,
                      color: scoreColor,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Column(
      children: [
        // Page indicator
        Text(
          'Page $_currentPage of $_totalPages',
          style: _ScannedFoodsDS.bodyText(
            11,
            color: _ScannedFoodsDS.textMuted,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // Pagination buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous
              if (_currentPage > 1)
                _paginationButton(
                  label: '← Previous',
                  isActive: true,
                  onTap: () => setState(() => _currentPage--),
                ),
              if (_currentPage > 1) const SizedBox(width: 8),
              // Page numbers
              ..._buildPageNumbers(),
              // Next
              if (_currentPage < _totalPages) const SizedBox(width: 8),
              if (_currentPage < _totalPages)
                _paginationButton(
                  label: 'Next →',
                  isActive: true,
                  onTap: () => setState(() => _currentPage++),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Item info
        Text(
          'Showing ${((_currentPage - 1) * _itemsPerPage) + 1}–${((_currentPage - 1) * _itemsPerPage) + _currentPageItems.length} of ${_allScans.length}',
          style: _ScannedFoodsDS.bodyText(
            10,
            color: _ScannedFoodsDS.textMuted,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageButtons = [];
    final totalPages = _totalPages;

    int startPage = 1;
    int endPage = totalPages;

    if (totalPages > 7) {
      if (_currentPage <= 3) {
        endPage = 4;
      } else if (_currentPage >= totalPages - 2) {
        startPage = totalPages - 3;
      } else {
        startPage = _currentPage - 1;
        endPage = _currentPage + 1;
      }
    }

    if (startPage > 1) {
      pageButtons.add(
        _paginationButton(
          label: '1',
          isActive: _currentPage == 1,
          onTap: () => setState(() => _currentPage = 1),
        ),
      );
      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        Text(
          '...',
          style: _ScannedFoodsDS.bodyText(12, color: _ScannedFoodsDS.textMuted),
        ),
      );
      pageButtons.add(const SizedBox(width: 4));
    }

    // Add pages
    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        _paginationButton(
          label: '$i',
          isActive: i == _currentPage,
          onTap: () => setState(() => _currentPage = i),
        ),
      );
      if (i < endPage) {
        pageButtons.add(const SizedBox(width: 4));
      }
    }

    // Ellipsis and last page
    if (endPage < totalPages) {
      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        Text(
          '...',
          style: _ScannedFoodsDS.bodyText(12, color: _ScannedFoodsDS.textMuted),
        ),
      );
      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        _paginationButton(
          label: '$totalPages',
          isActive: false,
          onTap: () => setState(() => _currentPage = totalPages),
        ),
      );
    }

    return pageButtons;
  }

  Widget _paginationButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_ScannedFoodsDS.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? _ScannedFoodsDS.brandPrimary : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? _ScannedFoodsDS.brandPrimary
                  : _ScannedFoodsDS.textMuted.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(_ScannedFoodsDS.r12),
          ),
          child: Text(
            label,
            style: _ScannedFoodsDS.bodyText(
              12,
              color: isActive ? Colors.white : _ScannedFoodsDS.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: _ScannedFoodsDS.brandPrimary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _ScannedFoodsDS.cardBg,
              borderRadius: BorderRadius.circular(_ScannedFoodsDS.r16),
              border: Border.all(
                color: _ScannedFoodsDS.textMuted.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ScannedFoodsDS.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dining_rounded,
                  size: 48,
                  color: _ScannedFoodsDS.brandPrimary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No scanned foods yet',
                  textAlign: TextAlign.center,
                  style: _ScannedFoodsDS.headline(18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start scanning your meals to track their health score',
                  textAlign: TextAlign.center,
                  style: _ScannedFoodsDS.bodyText(
                    12,
                    color: _ScannedFoodsDS.textMuted,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      color: _ScannedFoodsDS.brandPrimary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _ScannedFoodsDS.cardBg,
              borderRadius: BorderRadius.circular(_ScannedFoodsDS.r16),
              border: Border.all(
                color: _ScannedFoodsDS.scoreUnhealthy.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ScannedFoodsDS.scoreUnhealthy.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: _ScannedFoodsDS.scoreUnhealthy,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load',
                  textAlign: TextAlign.center,
                  style: _ScannedFoodsDS.headline(18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to load your scanned foods. Pull to retry.',
                  textAlign: TextAlign.center,
                  style: _ScannedFoodsDS.bodyText(
                    12,
                    color: _ScannedFoodsDS.textMuted,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFoodDetailsDialog(
    BuildContext context,
    FoodScanHistoryItem item,
    double score,
    Color scoreColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: _ScannedFoodsDS.cardBg,
              borderRadius: BorderRadius.circular(_ScannedFoodsDS.r16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ──── Header with Food Name & Score ────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_ScannedFoodsDS.r16),
                      topRight: Radius.circular(_ScannedFoodsDS.r16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.foodName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _ScannedFoodsDS.headline(
                                20,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Score Circle
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreCardBgColor(
                                score,
                              ).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(
                                _ScannedFoodsDS.r12,
                              ),
                              border: Border.all(
                                color: scoreColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  score.toStringAsFixed(1),
                                  style: _ScannedFoodsDS.headline(
                                    22,
                                    color: scoreColor,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '/10',
                                  style: _ScannedFoodsDS.bodyText(
                                    8,
                                    color: scoreColor,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDate(item.createdAt),
                        style: _ScannedFoodsDS.bodyText(
                          11,
                          color: _ScannedFoodsDS.textMuted,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ──── Scrollable Content ────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Nutritional Information ──
                      Text(
                        'Nutritional Information',
                        style: _ScannedFoodsDS.headline(
                          14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.0,
                        children: [
                          _nutributionInfoCard(
                            'Protein',
                            item.protein,
                            _ScannedFoodsDS.brandPrimary,
                          ),
                          _nutributionInfoCard(
                            'Carbs',
                            item.carbs,
                            const Color(0xFFFFC66D),
                          ),
                          _nutributionInfoCard(
                            'Fats',
                            item.fats,
                            const Color(0xFF5FD4A3),
                          ),
                          _nutributionInfoCard(
                            'Calories',
                            '${item.calories}',
                            const Color(0xFFFF6B6B),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Recommendation ──
                      Text(
                        'Health Recommendation',
                        style: _ScannedFoodsDS.headline(
                          14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.06),
                          border: Border.all(
                            color: scoreColor.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(
                            _ScannedFoodsDS.r12,
                          ),
                        ),
                        child: Text(
                          item.recommendation.isEmpty
                              ? 'No recommendation available'
                              : item.recommendation,
                          style: _ScannedFoodsDS.bodyText(
                            12,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Close Button ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ScannedFoodsDS.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _ScannedFoodsDS.r12,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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

  Widget _nutributionInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(_ScannedFoodsDS.r12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: _ScannedFoodsDS.bodyText(
              11,
              color: _ScannedFoodsDS.textMuted,
              weight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: _ScannedFoodsDS.headline(
              16,
              color: color,
              weight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
