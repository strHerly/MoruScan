// moruscan_home.dart - new
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';
import 'dart:math' as math;

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

class MoruScanHomePage extends StatefulWidget {
  const MoruScanHomePage({super.key});

  @override
  State<MoruScanHomePage> createState() => _MoruScanHomePageState();
}

class _MoruScanHomePageState extends State<MoruScanHomePage> {
  File? _image;
  Interpreter? _interpreter;
  Interpreter? _encoderInterpreter;
  List<String>? _labels;
  List<Recognition> _recognitions = [];
  String _resultText = 'No detections yet';
  bool _isPickerActive = false;
  bool _isScanning = false;
  int _totalScans = 0;
  int _spotsDetected = 0;
  SeverityAnalysis? _severityAnalysis;
  
  // Mulberry gallery vectors
  List<List<double>>? _mulberryGallery;
  static const double MULBERRY_THRESHOLD = 0.7;
  
  // Instance variables for coordinate transformation
  double _preprocessScale = 1.0;
  int _preprocessPadX = 0;
  int _preprocessPadY = 0;

  // Keys for persisting last scan state
  static const String _kLastImagePath   = 'last_scan_image_path';
  static const String _kLastResultText  = 'last_scan_result_text';
  static const String _kLastSeverityPct = 'last_scan_severity_pct';
  static const String _kLastSeverityLvl = 'last_scan_severity_level';
  static const String _kLastLeafPx      = 'last_scan_leaf_pixels';
  static const String _kLastInfectedPx  = 'last_scan_infected_pixels';
  static const String _kLastSpotCount   = 'last_scan_spot_count';
  static const String _kLastRecommEn    = 'last_scan_recommendation';
  static const String _kLastRecommTl    = 'last_scan_recommendation_tagalog';

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadEncoder();
    _loadMulberryGallery();
    _loadLabels();
    _loadStats();
    _restoreLastScan(); // ← restore previous scan on re-entry
  }

  @override
  void dispose() {
    _interpreter?.close();
    _encoderInterpreter?.close();
    super.dispose();
  }


  Future<void> _persistLastScan({
    required String imagePath,
    required String resultText,
    required SeverityAnalysis severity,
    required int spotCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastImagePath,   imagePath);
    await prefs.setString(_kLastResultText,  resultText);
    await prefs.setDouble(_kLastSeverityPct, severity.severityPercentage);
    await prefs.setString(_kLastSeverityLvl, severity.level);
    await prefs.setInt   (_kLastLeafPx,      severity.leafPixels);
    await prefs.setInt   (_kLastInfectedPx,  severity.infectedPixels);
    await prefs.setInt   (_kLastSpotCount,   spotCount);
    await prefs.setString(_kLastRecommEn,    severity.recommendation);
    await prefs.setString(_kLastRecommTl,    severity.recommendationTagalog);
  }

  SeverityAnalysis _buildSeverityFromPrefs({
    required double pct,
    required String level,
    required int leafPx,
    required int infectedPx,
    required String recommEn,
    required String recommTl,
  }) {
    Color color;
    switch (level) {
      case 'HEALTHY':          color = const Color(0xFF27ae60); break;
      case 'LOW SEVERITY':     color = const Color(0xFFB8860B); break;
      case 'MODERATE SEVERITY':color = const Color(0xFFf39c12); break;
      default:                 color = const Color(0xFFe74c3c); break;
    }
    return SeverityAnalysis(
      severityPercentage:    pct,
      level:                 level,
      color:                 color,
      recommendation:        recommEn,
      recommendationTagalog: recommTl,
      leafPixels:            leafPx,
      infectedPixels:        infectedPx,
    );
  }

  /// Load the last scan back into the UI on startup / re-navigation.
  Future<void> _restoreLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_kLastImagePath);
    if (imagePath == null) return;

    final file = File(imagePath);
    if (!file.existsSync()) return; // image was deleted – nothing to restore

    final pct      = prefs.getDouble(_kLastSeverityPct) ?? 0.0;
    final level    = prefs.getString(_kLastSeverityLvl) ?? 'HEALTHY';
    final leafPx   = prefs.getInt   (_kLastLeafPx)     ?? 0;
    final infPx    = prefs.getInt   (_kLastInfectedPx) ?? 0;
    final recommEn = prefs.getString(_kLastRecommEn)   ?? '';
    final recommTl = prefs.getString(_kLastRecommTl)   ?? '';
    final spotCount= prefs.getInt   (_kLastSpotCount)  ?? 0;
    final resultTxt= prefs.getString(_kLastResultText) ?? 'No detections yet';

    final fakeBoxes = List.generate(
      spotCount,
      (_) => Recognition(const Rect.fromLTWH(0, 0, 0, 0), 'spot', 1.0),
    );

    setState(() {
      _image           = file;
      _resultText      = resultTxt;
      _recognitions    = fakeBoxes;
      _severityAnalysis = _buildSeverityFromPrefs(
        pct:       pct,
        level:     level,
        leafPx:    leafPx,
        infectedPx: infPx,
        recommEn:  recommEn,
        recommTl:  recommTl,
      );
    });
  }

  Future<void> _clearLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _kLastImagePath, _kLastResultText, _kLastSeverityPct,
      _kLastSeverityLvl, _kLastLeafPx, _kLastInfectedPx,
      _kLastSpotCount, _kLastRecommEn, _kLastRecommTl,
    ]) {
      await prefs.remove(key);
    }
  }

  // ───  METHODS ───────────────────────────────────────────

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalScans    = prefs.getInt('total_scans') ?? 0;
      _spotsDetected = prefs.getInt('total_spots') ?? 0;
    });
  }

  Future<void> _updateStats(int spotsFound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_scans', _totalScans + 1);
    await prefs.setInt('total_spots', _spotsDetected + spotsFound);
    setState(() {
      _totalScans++;
      _spotsDetected += spotsFound;
    });
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      if (Platform.isAndroid) {
        try { options.addDelegate(GpuDelegateV2()); } catch (e) { if (kDebugMode) print('GPU not available'); }
      } else if (Platform.isIOS) {
        try { options.addDelegate(GpuDelegate()); } catch (e) { if (kDebugMode) print('Metal not available'); }
      }
      options.threads = 4;
      _interpreter = await Interpreter.fromAsset('assets/best_float16.tflite', options: options);
    } catch (e) {
      _interpreter = await Interpreter.fromAsset('assets/best_float16.tflite');
    }
  }

  Future<void> _loadEncoder() async {
    try {
      _encoderInterpreter = await Interpreter.fromAsset('assets/mulberry_encoder.tflite');
      if (kDebugMode) print('Loaded mulberry encoder');
    } catch (e) {
      if (kDebugMode) print('Error loading encoder: $e');
    }
  }

  Future<void> _loadMulberryGallery() async {
    try {
      final data = await rootBundle.load('assets/mulberry_fingerprint.npy');
      final bytes = data.buffer.asUint8List();
      int offset = 128;
      final floatList = Float32List.view(bytes.buffer, offset, (bytes.length - offset) ~/ 4);
      const int vectorSize = 1280;
      final numVectors = floatList.length ~/ vectorSize;
      _mulberryGallery = List.generate(
        numVectors,
        (i) => floatList.sublist(i * vectorSize, (i + 1) * vectorSize).toList(),
      );
      if (kDebugMode) print('Loaded ${_mulberryGallery!.length} reference vectors');
    } catch (e) {
      if (kDebugMode) print('Error loading gallery: $e');
    }
  }

  Future<void> _loadLabels() async {
    final labelsData = await rootBundle.loadString('assets/labels.txt');
    setState(() {
      _labels = labelsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
    });
  }

  Future<bool> _verifyMulberryLeaf(File imageFile) async {
    if (_encoderInterpreter == null || _mulberryGallery == null) return true;
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes)!;
      image = img.copyResize(image, width: 224, height: 224);
      final input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) => List.generate(3, (c) {
        final pixel = image.getPixel(x, y);
        double value = c == 0 ? pixel.r.toDouble() : c == 1 ? pixel.g.toDouble() : pixel.b.toDouble();
        return (value / 127.5) - 1.0;
      }))));
      var output = List.filled(1 * 1280, 0.0).reshape([1, 1280]);
      _encoderInterpreter!.run(input, output);
      final maxSimilarity = _getMaxSimilarity(output[0], _mulberryGallery!);
      if (kDebugMode) print('Mulberry similarity: ${maxSimilarity.toStringAsFixed(3)}');
      return maxSimilarity >= MULBERRY_THRESHOLD;
    } catch (e) {
      if (kDebugMode) print('Error in verification: $e');
      return true;
    }
  }

  double _getMaxSimilarity(List<double> testVector, List<List<double>> gallery) {
    final testNorm = _normalize(testVector);
    double maxSim = -1.0;
    for (var galleryVector in gallery) {
      final similarity = _cosineSimilarity(testNorm, _normalize(galleryVector));
      if (similarity > maxSim) maxSim = similarity;
    }
    return maxSim;
  }

  List<double> _normalize(List<double> vector) {
    final norm = math.sqrt(vector.fold<double>(0, (sum, val) => sum + val * val));
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    for (int i = 0; i < a.length; i++) dot += a[i] * b[i];
    return dot;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickerActive) return;
    setState(() => _isPickerActive = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth:    source == ImageSource.camera ? 2048 : null,
        maxHeight:   source == ImageSource.camera ? 2048 : null,
        imageQuality: source == ImageSource.camera ? 92   : null,
      );
      if (picked == null) return;

      // Clear previous scan immediately so the UI resets visually
      await _clearLastScan();

      setState(() {
        _image            = File(picked.path);
        _recognitions     = [];
        _severityAnalysis = null;
        _resultText       = 'Verifying image...';
        _isScanning       = true;
      });

      final isMulberry = await _verifyMulberryLeaf(File(picked.path));

      if (!isMulberry) {
        setState(() {
          _isScanning = false;
          _resultText = 'Not a mulberry leaf';
        });
        _showNotMulberryDialog();
        return;
      }

      setState(() => _resultText = 'Analyzing the leaf...');
      await _runDetection(File(picked.path));
      setState(() => _isScanning = false);
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  void _showNotMulberryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          const Text('Not a Mulberry Leaf'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The image you uploaded does not appear to be a mulberry leaf.', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('Please upload a clear photo of a mulberry leaf for accurate disease detection.', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<SeverityAnalysis> _calculateSeverity(File imageFile, List<Recognition> boxes) async {
    final bytes = await imageFile.readAsBytes();
    var image = img.decodeImage(bytes)!;
    double scaleFactor = 1.0;
    if (image.width > 1000 || image.height > 1000) {
      final maxDim = image.width > image.height ? image.width : image.height;
      scaleFactor = 1000 / maxDim;
      image = img.copyResize(image, width: (image.width * scaleFactor).toInt(), height: (image.height * scaleFactor).toInt());
    }
    final leafMask          = _getLeafMaskAggressive(image);
    final boxMask           = _createBoxMask(image, boxes);
    final totalLeafMask     = _bitwiseOr(leafMask, boxMask);
    final actualInfectedMask= _bitwiseAnd(boxMask, totalLeafMask);
    int leafPixels          = _countNonZero(totalLeafMask);
    int infectedPixels      = _countNonZero(actualInfectedMask);
    if (leafPixels == 0) leafPixels = 1;
    double severity         = (infectedPixels / leafPixels * 100);

    String level; Color color; String recommendation; String recommendationTagalog;

    if (boxes.isEmpty) {
      level = "HEALTHY"; color = const Color(0xFF27ae60);
      recommendation = "No leaf spots detected. Continue routine monitoring for early signs of disease and maintain proper plant care.";
      recommendationTagalog = "Walang nakitang batik o mantsa sa dahon. Malusog ang inyong halaman. Magpatuloy lamang sa regular na pagbabantay at pag-aalaga upang mapanatili ang kalusugan nito.";
      severity = 0.0;
    } else if (severity < 2.0) {
      level = "LOW SEVERITY"; color = const Color(0xFFB8860B);
      recommendation = "Maintain proper nutrition and regular irrigation. Continue monitoring the plant closely for any changes.";
      recommendationTagalog = "Panatilihin ang sapat na nutrisyon at regular na patubig. Magpatuloy sa masusing pagsubaybay sa halaman para sa anumang pagbabago o paglala ng kondisyon.";
    } else if (severity < 7.0) {
      level = "MODERATE SEVERITY"; color = const Color(0xFFf39c12);
      recommendation = "Remove affected leaves immediately and apply appropriate fungicide treatment. Improve air circulation around the plant.";
      recommendationTagalog = "Alisin kaagad ang mga apektadong dahon at maglagay ng tamang fungicide. Siguruhing maayos ang sirkulasyon ng hangin sa paligid ng halaman upang maiwasan ang pagkalat ng sakit.";
    } else {
      level = "HIGH SEVERITY"; color = const Color(0xFFe74c3c);
      recommendation = "Inspect the entire plant thoroughly. If symptoms are widespread, implement heavy pruning or consider plant removal to prevent further spread.";
      recommendationTagalog = "Suriin nang lubusan ang buong halaman. Kung laganap na ang impeksyon, gumawa ng malawakang pagputol ng mga sanga o isaalang-alang ang pagtanggal ng halaman upang pigilan ang pagkalat sa ibang pananim.";
    }

    return SeverityAnalysis(
      severityPercentage: severity, level: level, color: color,
      recommendation: recommendation, recommendationTagalog: recommendationTagalog,
      leafPixels: leafPixels, infectedPixels: infectedPixels,
    );
  }

  img.Image _getLeafMaskAggressive(img.Image image) {
    final grayscale = img.grayscale(image);
    final blurred   = img.gaussianBlur(grayscale, radius: 3);
    final mask      = _otsuThreshold(blurred);
    final corners   = [
      mask.getPixel(0, 0).r, mask.getPixel(mask.width - 1, 0).r,
      mask.getPixel(0, mask.height - 1).r, mask.getPixel(mask.width - 1, mask.height - 1).r,
    ];
    final cornerMean = corners.reduce((a, b) => a + b) / corners.length;
    if (cornerMean > 127) {
      for (int y = 0; y < mask.height; y++) {
        for (int x = 0; x < mask.width; x++) {
          final inv = 255 - mask.getPixel(x, y).r.toInt();
          mask.setPixel(x, y, img.ColorRgb8(inv, inv, inv));
        }
      }
    }
    var result = _morphologyClose(mask, kernelSize: 5);
    result     = _morphologyOpen(result, kernelSize: 5);
    return result;
  }

  img.Image _otsuThreshold(img.Image image) {
    List<int> histogram = List.filled(256, 0);
    for (int y = 0; y < image.height; y++) for (int x = 0; x < image.width; x++) histogram[image.getPixel(x, y).r.toInt()]++;
    final total = image.width * image.height;
    double sum = 0;
    for (int i = 0; i < 256; i++) sum += i * histogram[i];
    double sumB = 0; int wB = 0; int wF = 0; double maxVariance = 0; int threshold = 0;
    for (int i = 0; i < 256; i++) {
      wB += histogram[i]; if (wB == 0) continue;
      wF = total - wB;    if (wF == 0) break;
      sumB += i * histogram[i];
      double mB = sumB / wB; double mF = (sum - sumB) / wF;
      double variance = wB * wF * (mB - mF) * (mB - mF);
      if (variance > maxVariance) { maxVariance = variance; threshold = i; }
    }
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) for (int x = 0; x < image.width; x++) {
      final v = image.getPixel(x, y).r.toInt() > threshold ? 255 : 0;
      result.setPixel(x, y, img.ColorRgb8(v, v, v));
    }
    return result;
  }

  img.Image _morphologyClose(img.Image image, {required int kernelSize}) { var r = _dilate(image, kernelSize); return _erode(r, kernelSize); }
  img.Image _morphologyOpen (img.Image image, {required int kernelSize}) { var r = _erode(image, kernelSize);  return _dilate(r, kernelSize); }

  img.Image _dilate(img.Image image, int kernelSize) {
    final result = img.Image(width: image.width, height: image.height);
    final half   = kernelSize ~/ 2;
    for (int y = 0; y < image.height; y++) for (int x = 0; x < image.width; x++) {
      int maxVal = 0;
      for (int ky = -half; ky <= half; ky++) for (int kx = -half; kx <= half; kx++) {
        final val = image.getPixel((x + kx).clamp(0, image.width - 1), (y + ky).clamp(0, image.height - 1)).r.toInt();
        if (val > maxVal) maxVal = val;
      }
      result.setPixel(x, y, img.ColorRgb8(maxVal, maxVal, maxVal));
    }
    return result;
  }

  img.Image _erode(img.Image image, int kernelSize) {
    final result = img.Image(width: image.width, height: image.height);
    final half   = kernelSize ~/ 2;
    for (int y = 0; y < image.height; y++) for (int x = 0; x < image.width; x++) {
      int minVal = 255;
      for (int ky = -half; ky <= half; ky++) for (int kx = -half; kx <= half; kx++) {
        final val = image.getPixel((x + kx).clamp(0, image.width - 1), (y + ky).clamp(0, image.height - 1)).r.toInt();
        if (val < minVal) minVal = val;
      }
      result.setPixel(x, y, img.ColorRgb8(minVal, minVal, minVal));
    }
    return result;
  }

  img.Image _createBoxMask(img.Image image, List<Recognition> boxes) {
    final mask = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < mask.height; y++) for (int x = 0; x < mask.width; x++) mask.setPixel(x, y, img.ColorRgb8(0, 0, 0));
    for (var box in boxes) {
      int x1 = (box.location.left  * image.width ).toInt().clamp(0, image.width  - 1);
      int y1 = (box.location.top   * image.height).toInt().clamp(0, image.height - 1);
      int x2 = ((box.location.left + box.location.width)  * image.width ).toInt().clamp(0, image.width  - 1);
      int y2 = ((box.location.top  + box.location.height) * image.height).toInt().clamp(0, image.height - 1);
      for (int y = y1; y <= y2; y++) for (int x = x1; x <= x2; x++) mask.setPixel(x, y, img.ColorRgb8(255, 255, 255));
    }
    return mask;
  }

  img.Image _bitwiseOr(img.Image mask1, img.Image mask2) {
    final result = img.Image(width: mask1.width, height: mask1.height);
    for (int y = 0; y < result.height; y++) for (int x = 0; x < result.width; x++) {
      final v = mask1.getPixel(x, y).r.toInt() | mask2.getPixel(x, y).r.toInt();
      result.setPixel(x, y, img.ColorRgb8(v, v, v));
    }
    return result;
  }

  img.Image _bitwiseAnd(img.Image mask1, img.Image mask2) {
    final result = img.Image(width: mask1.width, height: mask1.height);
    for (int y = 0; y < result.height; y++) for (int x = 0; x < result.width; x++) {
      final v = mask1.getPixel(x, y).r.toInt() & mask2.getPixel(x, y).r.toInt();
      result.setPixel(x, y, img.ColorRgb8(v, v, v));
    }
    return result;
  }

  int _countNonZero(img.Image mask) {
    int count = 0;
    for (int y = 0; y < mask.height; y++) for (int x = 0; x < mask.width; x++) if (mask.getPixel(x, y).r > 0) count++;
    return count;
  }

  void _showSeverityReportModal(BuildContext context) {
    if (_severityAnalysis == null) return;
    final analysis = _severityAnalysis!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: analysis.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.analytics, color: analysis.color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(analysis.level == "HEALTHY" ? "Healthy Leaf" : "Infection Level",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: analysis.color, borderRadius: BorderRadius.circular(12)),
                      child: Text(analysis.level, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ])),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (analysis.level != "HEALTHY") ...[
                      Center(child: Column(children: [
                        Text("${analysis.severityPercentage.toStringAsFixed(2)}%",
                          style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: analysis.color, height: 1.0)),
                        const SizedBox(height: 8),
                        Text("Infection Index", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                      ])),
                      const SizedBox(height: 32),
                    ],
                    if (analysis.level != "HEALTHY")
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("QUANTITATIVE METRICS",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF34495e))),
                          const SizedBox(height: 16),
                          _buildMetricRow("Total Leaf Area",
                            "${analysis.leafPixels.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} px"),
                          const SizedBox(height: 12),
                          _buildMetricRow("Infected Area",
                            "${analysis.infectedPixels.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} px"),
                          const SizedBox(height: 12),
                          _buildMetricRow("Detected Spots", "${_recognitions.length}"),
                        ]),
                      ),
                    if (analysis.level != "HEALTHY") const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: analysis.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: analysis.color.withOpacity(0.3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.lightbulb_outline, color: analysis.color, size: 20),
                          const SizedBox(width: 8),
                          Text("RECOMMENDED ACTION",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: analysis.color)),
                        ]),
                        const SizedBox(height: 12),
                        Text(analysis.recommendation,
                          style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF2c3e50))),
                        const SizedBox(height: 12),
                        Text(analysis.recommendationTagalog,
                          style: const TextStyle(fontSize: 13, height: 1.6, fontStyle: FontStyle.italic, color: Color(0xFF34495e))),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF7f8c8d))),
        Text(value,  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF2c3e50))),
      ],
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  void _showFullscreenImage(BuildContext context) {
    if (_image == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          InteractiveViewer(
            minScale: 1.0, maxScale: 10.0,
            boundaryMargin: const EdgeInsets.all(50),
            child: Center(child: Image.file(_image!, fit: BoxFit.contain)),
          ),
          Positioned(
            top: 40, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Pinch to zoom (up to 10x) • ${_recognitions.length} spots detected',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<String> _saveImageWithBoxes(File originalImage, List<Recognition> boxes) async {
    final bytes = await originalImage.readAsBytes();
    var image   = img.decodeImage(bytes)!;
    for (var box in boxes) {
      int left   = (box.location.left  * image.width ).toInt().clamp(0, image.width  - 1);
      int top    = (box.location.top   * image.height).toInt().clamp(0, image.height - 1);
      int right  = ((box.location.left + box.location.width)  * image.width ).toInt().clamp(0, image.width  - 1);
      int bottom = ((box.location.top  + box.location.height) * image.height).toInt().clamp(0, image.height - 1);
      img.drawRect(image, x1: left, y1: top, x2: right, y2: bottom, color: img.ColorRgb8(0, 0, 255), thickness: 3);
      String labelText = '${box.label} ${(box.score * 100).toStringAsFixed(1)}%';
      int labelWidth   = (labelText.length * 8).clamp(60, image.width - left);
      int labelHeight  = 20;
      int labelTop     = (top - labelHeight - 2).clamp(0, image.height - labelHeight);
      img.fillRect(image, x1: left, y1: labelTop,
        x2: (left + labelWidth).clamp(0, image.width), y2: (labelTop + labelHeight).clamp(0, image.height),
        color: img.ColorRgb8(0, 0, 255));
      img.drawString(image, labelText, font: img.arial14, x: left + 2, y: labelTop + 3, color: img.ColorRgb8(255, 255, 255));
    }
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath   = '${directory.path}/detected_$timestamp.jpg';
    await File(newPath).writeAsBytes(img.encodeJpg(image));
    return newPath;
  }

  static Future<Map<String, dynamic>> _preprocessImage(File file) async {
    final bytes      = await file.readAsBytes();
    final image      = img.decodeImage(bytes)!;
    const int modelSize = 800;
    final scaleW     = modelSize / image.width;
    final scaleH     = modelSize / image.height;
    final scale      = scaleW < scaleH ? scaleW : scaleH;
    final scaledW    = (image.width  * scale).round();
    final scaledH    = (image.height * scale).round();
    final padX       = (modelSize - scaledW) ~/ 2;
    final padY       = (modelSize - scaledH) ~/ 2;
    final resized    = img.copyResize(image, width: scaledW, height: scaledH);
    final padded     = img.Image(width: modelSize, height: modelSize);
    img.fill(padded, color: img.ColorRgb8(0, 0, 0));
    img.compositeImage(padded, resized, dstX: padX, dstY: padY);
    final input = List.generate(1, (_) => List.generate(modelSize, (_) => List.generate(modelSize, (_) => List.filled(3, 0.0))));
    for (int y = 0; y < modelSize; y++) for (int x = 0; x < modelSize; x++) {
      final pixel = padded.getPixel(x, y);
      input[0][y][x][0] = pixel.r / 255.0;
      input[0][y][x][1] = pixel.g / 255.0;
      input[0][y][x][2] = pixel.b / 255.0;
    }
    return {
      'input': input, 'scale': scale, 'padX': padX, 'padY': padY,
      'modelSize': modelSize, 'originalWidth': image.width, 'originalHeight': image.height,
    };
  }

  Future<void> _runDetection(File imageFile) async {
    if (_interpreter == null || _labels == null) return;

    final preprocessResult = await compute(_preprocessImage, imageFile);
    final input = preprocessResult['input'];
    _preprocessScale = preprocessResult['scale'];
    _preprocessPadX = preprocessResult['padX'];
    _preprocessPadY = preprocessResult['padY'];
    final modelSize = preprocessResult['modelSize'];
    final origWidth = preprocessResult['originalWidth'];
    final origHeight = preprocessResult['originalHeight'];

    var output = List.filled(1 * 5 * 13125, 0.0).reshape([1, 5, 13125]);
    _interpreter!.run(input, output);

    List<Recognition> candidates = [];
    for (int i = 0; i < 13125; i++) {
      double confidence = output[0][4][i];
      if (confidence.isNaN || confidence.isInfinite || confidence < 0.25) continue;
      double cx = output[0][0][i]; double cy = output[0][1][i];
      double w  = output[0][2][i]; double h  = output[0][3][i];
      if ([cx, cy, w, h].any((v) => v.isNaN || v.isInfinite)) continue;
      double unpadCx = cx * modelSize - _preprocessPadX;
      double unpadCy = cy * modelSize - _preprocessPadY;
      double normCx  = (unpadCx / _preprocessScale) / origWidth;
      double normCy  = (unpadCy / _preprocessScale) / origHeight;
      double normW   = (w * modelSize / _preprocessScale) / origWidth;
      double normH   = (h * modelSize / _preprocessScale) / origHeight;
      candidates.add(Recognition(
        Rect.fromLTWH(normCx - normW / 2, normCy - normH / 2, normW, normH),
        _labels![0], confidence,
      ));
    }

    final results  = _applyNMS(candidates);
    final severity = await _calculateSeverity(imageFile, results);
    await _updateStats(results.length);

    String imagePathToSave;
    if (results.isNotEmpty) {
      imagePathToSave = await _saveImageWithBoxes(imageFile, results);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      imagePathToSave = '${directory.path}/original_$timestamp.jpg';
      await imageFile.copy(imagePathToSave);
    }

    final resultText = results.isEmpty ? "Healthy leaf" : "Detected ${results.length} spots";

    // ← Persist so navigation back restores this scan
    await _persistLastScan(
      imagePath:  imagePathToSave,
      resultText: resultText,
      severity:   severity,
      spotCount:  results.length,
    );

    setState(() {
      _image            = File(imagePathToSave);
      _recognitions     = results;
      _severityAnalysis = severity;
      _resultText       = resultText;
    });

    await HistoryPage.saveRecord(
      result:                results.isEmpty ? "Healthy leaf" : "Leaf spots detected",
      severityIndex:         severity.severityPercentage,
      leafPixels:            severity.leafPixels,
      infectedPixels:        severity.infectedPixels,
      recommendation:        severity.recommendation,
      recommendationTagalog: severity.recommendationTagalog,
      imagePath:             imagePathToSave,
      spotsDetected:         results.length,
    );
  }

  List<Recognition> _applyNMS(List<Recognition> boxes) {
    if (boxes.isEmpty) return [];
    boxes.sort((a, b) => b.score.compareTo(a.score));
    List<Recognition> selected = [];
    while (boxes.isNotEmpty) {
      var first = boxes.removeAt(0);
      selected.add(first);
      boxes.removeWhere((next) {
        var inter = first.location.intersect(next.location);
        if (inter.width <= 0 || inter.height <= 0) return false;
        double interArea = inter.width * inter.height;
        double unionArea = (first.location.width * first.location.height) +
                           (next.location.width  * next.location.height)  - interArea;
        return (interArea / unionArea) > 0.40;
      });
    }
    return selected;
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const double displaySize = 300.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('MoruScan Detection',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Stats banner ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(children: [
                  _buildStatCard(icon: Icons.image_search, label: 'Total Scans', value: '$_totalScans', color: Colors.white),
                  const SizedBox(width: 12),
                  _buildStatCard(icon: Icons.bug_report,   label: 'Spots Found', value: '$_spotsDetected', color: Colors.white),
                ]),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text('Scan Your Leaf',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text('Take a clear photo of the affected leaf',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 15),

                  // ── Image display ──
                  Container(
                    width: displaySize, height: displaySize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: _image == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate, size: 80, color: Colors.green.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          Text('No image selected', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ])
                      : Stack(children: [
                          GestureDetector(
                            onTap: () { if (_recognitions.isNotEmpty && !_isScanning) _showFullscreenImage(context); },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_image!, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
                            ),
                          ),
                          if (_isScanning)
                            Positioned.fill(child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            )),
                          if (_recognitions.isNotEmpty && !_isScanning)
                            Positioned(
                              bottom: 8, left: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.touch_app, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Tap to view fullscreen & zoom',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            ),
                        ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Result / severity card ──
            GestureDetector(
              onTap: _severityAnalysis != null ? () => _showSeverityReportModal(context) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _severityAnalysis == null ? Colors.grey[200] : _severityAnalysis!.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _severityAnalysis == null ? Colors.grey.shade300 : _severityAnalysis!.color.withOpacity(0.3),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _severityAnalysis == null ? Icons.info_outline : Icons.analytics,
                    color: _severityAnalysis?.color ?? Colors.grey[600], size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_resultText,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: _severityAnalysis?.color ?? Colors.grey[700])),
                    if (_severityAnalysis != null) ...[
                      const SizedBox(height: 4),
                      Text('Tap for detailed analysis & recommendations',
                        style: TextStyle(fontSize: 12, color: _severityAnalysis!.color, fontStyle: FontStyle.italic)),
                    ],
                  ])),
                  if (_severityAnalysis != null)
                    Icon(Icons.arrow_forward_ios, size: 16, color: _severityAnalysis!.color),
                ]),
              ),
            ),

            const SizedBox(height: 20),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _actionButton(Icons.camera_alt,    "Camera",  () => _pickImage(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(child: _actionButton(Icons.photo_library, "Gallery", () => _pickImage(ImageSource.gallery))),
              ]),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9))),
        ]),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isScanning ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2, disabledBackgroundColor: Colors.grey,
      ),
      child: Column(children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}