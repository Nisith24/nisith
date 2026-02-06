import 'package:flutter/physics.dart';

/// Spring configurations matching React Native Reanimated
class SpringConfigs {
  /// Card snap-back spring
  /// RN: { damping: 28, stiffness: 350, mass: 0.8 }
  static const cardSnapBack = SpringDescription(
    mass: 0.8,
    stiffness: 350,
    damping: 28,
  );

  /// Reset spring (more damped)
  /// RN: { damping: 35, stiffness: 350, mass: 0.8 }
  static const reset = SpringDescription(
    mass: 0.8,
    stiffness: 350,
    damping: 35,
  );

  /// Menu toggle spring
  /// RN: { damping: 18, stiffness: 120, mass: 0.8 }
  static const menuToggle = SpringDescription(
    mass: 0.8,
    stiffness: 120,
    damping: 18,
  );

  /// Sensor smoothing spring
  /// RN: { damping: 22, stiffness: 100, mass: 1.0 }
  static const sensorSmooth = SpringDescription(
    mass: 1.0,
    stiffness: 100,
    damping: 22,
  );
}

/// Animation constants matching React Native implementation
class AnimationConstants {
  // Swipe thresholds
  static const double swipeThreshold = 100.0;
  static const double swipeVelocityThreshold = 500.0;

  // Pan gesture offsets
  static const double panActiveOffsetY = 25.0;
  static const double panFailOffsetX = 20.0;

  // Tilt settings (reduced for subtler effect)
  static const double tiltDeadzone = 0.04;
  static const double tiltSensitivity = 8.0;
  static const double maxTiltAngle = 3.0;

  // Durations
  static const Duration cardExit = Duration(milliseconds: 250);
  static const Duration optionFade = Duration(milliseconds: 400);
  static const Duration optionStagger = Duration(milliseconds: 50);
  static const Duration hintBounce = Duration(milliseconds: 2000);
  static const Duration bottomBarFade = Duration(milliseconds: 150);
}
