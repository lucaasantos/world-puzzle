import 'package:flutter/services.dart';

class HapticsService {
  bool enabled = true;

  Future<void> move() async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  Future<void> victory() async {
    if (enabled) await HapticFeedback.heavyImpact();
  }

  Future<void> reward() async {
    if (enabled) await HapticFeedback.mediumImpact();
  }
}
