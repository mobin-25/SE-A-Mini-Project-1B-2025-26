import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Provides a parallax offset based on device tilt (accelerometer) or pointer movement (web/desktop).

class ParallaxController extends ChangeNotifier {
  Offset _offset = Offset.zero;
  Offset get offset => _offset;
  StreamSubscription? _sub;
  DateTime _lastUpdate = DateTime.now();
  static const int _minFrameMs = 16; // ~60 FPS

  ParallaxController() {
    // Use accelerometer for mobile, fallback to pointer for web/desktop
    _sub = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastUpdate).inMilliseconds < _minFrameMs) return;
      _lastUpdate = now;
      // Clamp and scale for subtle effect
      final dx = (event.x.clamp(-6, 6) / 12).toDouble();
      final dy = (event.y.clamp(-6, 6) / 12).toDouble();
      _offset = Offset(dx, dy);
      notifyListeners();
    });
  }

  void setPointerOffset(Offset pointer, Size size) {
    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMilliseconds < _minFrameMs) return;
    _lastUpdate = now;
    // For web/desktop: pointer position relative to center
    final center = size.center(Offset.zero);
    final dx = ((pointer.dx - center.dx) / size.width).clamp(-0.2, 0.2);
    final dy = ((pointer.dy - center.dy) / size.height).clamp(-0.2, 0.2);
    _offset = Offset(dx, dy);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
