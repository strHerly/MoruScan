import 'dart:io';
import 'package:flutter/material.dart';

class Recognition {
  final Rect location;
  final String label;
  final double score;

  Recognition(this.location, this.label, this.score);
}

class SeverityAnalysis {
  final double severityPercentage;
  final String level;
  final Color color;
  final String recommendation;
  final String recommendationTagalog;
  final int leafPixels;
  final int infectedPixels;

  SeverityAnalysis({
    required this.severityPercentage,
    required this.level,
    required this.color,
    required this.recommendation,
    required this.recommendationTagalog,
    required this.leafPixels,
    required this.infectedPixels,
  });
}

class ScanStateService extends ChangeNotifier {
  File? image;
  List<Recognition> recognitions = [];
  SeverityAnalysis? severityAnalysis;
  String resultText = 'No detections yet';
  bool isScanning = false;
  bool isPickerActive = false;
  DateTime? lastScanTime; 

  void beginScan(File selectedImage) {
    image = selectedImage;
    recognitions = [];
    severityAnalysis = null;
    resultText = 'Verifying image...';
    isScanning = true;
    isPickerActive = true;
    notifyListeners();
  }

  void updateStatus(String status) {
    resultText = status;
    notifyListeners();
  }

  void completeScan({
    required File finalImage,
    required List<Recognition> results,
    required SeverityAnalysis severity,
    required String resultText,
  }) {
    image = finalImage;
    recognitions = results;
    severityAnalysis = severity;
    this.resultText = resultText;
    isScanning = false;
    isPickerActive = false;
    lastScanTime = DateTime.now();
    notifyListeners();
  }

  void failScan(String message) {
    isScanning = false;
    isPickerActive = false;
    resultText = message;
    notifyListeners();
  }

  void reset() {
    image = null;
    recognitions = [];
    severityAnalysis = null;
    resultText = 'No detections yet';
    isScanning = false;
    isPickerActive = false;
    notifyListeners();
  }
}