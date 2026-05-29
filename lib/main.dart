import 'package:flutter/material.dart';
import 'moruscan_main.dart';

void main() {
  runApp(const MoruScanApp());
}

class MoruScanApp extends StatelessWidget {
  const MoruScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoruScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
      home: const MoruScanMain(), // ✅ New navigation entry
    );
  }
}
