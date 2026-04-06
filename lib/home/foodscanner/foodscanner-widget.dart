import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/app_theme.dart';

import 'foodscanner_model.dart';

class FoodScannerWidget extends StatefulWidget {
  const FoodScannerWidget({super.key});

  @override
  State<FoodScannerWidget> createState() => _FoodScannerWidgetState();
}

class _FoodScannerWidgetState extends State<FoodScannerWidget> {
  late final FoodScannerModel _model;

  Future<void> _openCameraFlow() async {
    final capturedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _FoodCameraCaptureWidget()),
    );

    if (!mounted || capturedPath == null || capturedPath.trim().isEmpty) {
      return;
    }

    await _model.setImageFromPath(capturedPath);
  }

  @override
  void initState() {
    super.initState();
    _model = FoodScannerModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color background,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _model.result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Text(
            result.foodName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricChip(
                'Calories',
                result.calories,
                const Color(0xFFFF8A65),
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                'Health Score',
                result.healthScore,
                const Color(0xFF43A047),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Macronutrients',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2835),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMacroCard('Protein', result.protein),
              _buildMacroCard('Carbs', result.carbs),
              _buildMacroCard('Fats', result.fats),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightTile(
            title: 'PCOS Positive',
            value: result.pcosPositive,
            color: const Color(0xFFE8F5E9),
            accent: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 8),
          _buildInsightTile(
            title: 'PCOS Caution',
            value: result.pcosNegative,
            color: const Color(0xFFFFEBEE),
            accent: const Color(0xFFC62828),
          ),
          const SizedBox(height: 10),
          _buildInsightTile(
            title: 'Recommendation',
            value: result.recommendation,
            color: const Color(0xFFF3E5F5),
            accent: const Color(0xFF7B1FA2),
          ),
          const SizedBox(height: 8),
          _buildInsightTile(
            title: 'Alternative',
            value: result.alternative,
            color: const Color(0xFFE3F2FD),
            accent: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  Widget _buildRawResponseCard() {
    final payload = _model.rawResultPayload;
    if (payload == null || payload.isEmpty) {
      return const SizedBox.shrink();
    }

    final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Response',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            prettyJson,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE5E7EB),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C6774),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1B20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(String title, String value) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6F6978),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2835),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile({
    required String title,
    required String value,
    required Color color,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2E2835),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17253C), Color(0xFF275F95), Color(0xFF367CB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Meal Intelligence',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture or upload a meal to get instant nutrition and PCOS-safe suggestions.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePanel() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE1EF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _model.selectedImage == null
          ? Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF5F8FC),
                          const Color(0xFFF5ECF3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 30,
                        color: Color(0xFF7B7384),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7B7384),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Image.file(
              File(_model.selectedImage!.path),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppTheme.brandInk,
            title: Text(
              'Food Scanner',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _model.clear,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          body: Container(
            decoration: AppTheme.pageBackgroundDecoration(),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 840;

                        if (!isWide) {
                          return _buildImagePanel();
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildImagePanel()),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 230,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFEAE1EF),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scan Checklist',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _scanTip('Keep food fully visible'),
                                    _scanTip('Use bright lighting'),
                                    _scanTip('Avoid motion blur'),
                                    _scanTip('Capture top-down angle'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildActionButton(
                          label: 'Scan Camera',
                          icon: Icons.camera_alt_rounded,
                          onPressed: _model.isPickingImage || _model.isAnalyzing
                              ? null
                              : _openCameraFlow,
                          background: const Color(0xFF0F9D85),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          label: 'Upload Image',
                          icon: Icons.photo_library_rounded,
                          onPressed: _model.isPickingImage || _model.isAnalyzing
                              ? null
                              : _model.pickFromGallery,
                          background: AppTheme.brandPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _model.isAnalyzing ||
                                _model.isPickingImage ||
                                _model.selectedImage == null
                            ? null
                            : _model.analyseImage,
                        icon: _model.isAnalyzing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.analytics_outlined),
                        label: Text(
                          _model.isAnalyzing
                              ? 'Analyzing your food...'
                              : 'Analyze Food',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    if (_model.pickError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _model.pickError!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_model.analyzeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _model.analyzeError!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_model.analyzeMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _model.analyzeMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _buildResultCard(),
                    _buildRawResponseCard(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scanTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Color(0xFF356EA9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4D4657),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCameraCaptureWidget extends StatefulWidget {
  const _FoodCameraCaptureWidget();

  @override
  State<_FoodCameraCaptureWidget> createState() =>
      _FoodCameraCaptureWidgetState();
}

class _FoodCameraCaptureWidgetState extends State<_FoodCameraCaptureWidget> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isInitializing = false;
          _cameraError = 'No camera found on this device.';
        });
        return;
      }

      final preferred = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        preferred,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _cameraError =
            'Unable to open camera. Please check permissions and try again.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final file = await controller.takePicture();
      if (!mounted) {
        return;
      }
      Navigator.pop(context, file.path);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCapturing = false;
        _cameraError = 'Failed to capture image. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Capture Food Image',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _cameraError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _cameraError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 22,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCapturing
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCapturing ? null : _capturePhoto,
                          icon: _isCapturing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_rounded),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                          ),
                          label: Text(
                            _isCapturing ? 'Capturing...' : 'Capture',
                            style: GoogleFonts.poppins(
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
