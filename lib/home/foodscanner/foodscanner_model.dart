import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/foodscanner_api_service.dart';

class FoodScannerModel extends ChangeNotifier {
  FoodScannerModel({FoodScannerApiService? apiService})
    : _apiService = apiService ?? FoodScannerApiService();

  final FoodScannerApiService _apiService;
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;
  String? imageBase64;
  FoodAnalysisResult? result;
  Map<String, dynamic>? rawResultPayload;

  bool isPickingImage = false;
  bool isAnalyzing = false;

  String? pickError;
  String? analyzeError;
  String? analyzeMessage;

  Future<void> setImageFromPath(String imagePath) async {
    isPickingImage = true;
    pickError = null;
    analyzeError = null;
    analyzeMessage = null;
    rawResultPayload = null;
    notifyListeners();

    try {
      final file = File(imagePath);
      final exists = await file.exists();
      if (!exists) {
        isPickingImage = false;
        pickError = 'Captured image not found. Please try again.';
        notifyListeners();
        return;
      }

      final bytes = await file.readAsBytes();
      final encoded = base64Encode(bytes);

      selectedImage = XFile(imagePath);
      imageBase64 = encoded;
      result = null;
      rawResultPayload = null;
      pickError = null;
      isPickingImage = false;
      notifyListeners();
    } catch (_) {
      isPickingImage = false;
      pickError = 'Unable to process captured image. Please try again.';
      notifyListeners();
    }
  }

  Future<void> pickFromGallery() async {
    isPickingImage = true;
    pickError = null;
    analyzeError = null;
    analyzeMessage = null;
    rawResultPayload = null;
    notifyListeners();

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 768,
        maxHeight: 768,
      );

      isPickingImage = false;

      if (image == null) {
        pickError = 'No image selected.';
        notifyListeners();
        return;
      }

      final bytes = await File(image.path).readAsBytes();
      final encoded = base64Encode(bytes);

      selectedImage = image;
      imageBase64 = encoded;
      result = null;
      rawResultPayload = null;
      pickError = null;
      notifyListeners();
    } catch (_) {
      isPickingImage = false;
      pickError = 'Unable to access image. Please try again.';
      notifyListeners();
    }
  }

  Future<void> setImageFromPathAndAnalyse(String imagePath) async {
    await setImageFromPath(imagePath);
    if (selectedImage == null) {
      return;
    }
    await analyseImage();
  }

  Future<void> pickFromGalleryAndAnalyse() async {
    await pickFromGallery();
    if (selectedImage == null) {
      return;
    }
    await analyseImage();
  }

  Future<void> analyseImage() async {
    final imageData = imageBase64?.trim() ?? '';
    if (imageData.isEmpty) {
      analyzeError = 'Please capture or upload an image first.';
      notifyListeners();
      return;
    }

    isAnalyzing = true;
    analyzeError = null;
    analyzeMessage = null;
    notifyListeners();

    final response = await _apiService.analyseFood(
      imageBase64OrDataUri: imageData,
    );

    isAnalyzing = false;

    if (!response.success || response.result == null) {
      analyzeError = response.message;
      analyzeMessage = null;
      rawResultPayload = response.rawPayload.isEmpty
          ? null
          : response.rawPayload;
      notifyListeners();
      return;
    }

    result = response.result;
    rawResultPayload = response.rawPayload;
    analyzeMessage = response.message;
    analyzeError = null;
    notifyListeners();
  }

  void clear() {
    selectedImage = null;
    imageBase64 = null;
    result = null;
    rawResultPayload = null;
    pickError = null;
    analyzeError = null;
    analyzeMessage = null;
    notifyListeners();
  }
}

