// recognition.dart
import 'dart:ui';

class Recognition {
  final Rect location;
  final String label;
  final double score;

  Recognition(this.location, this.label, this.score);
}