import 'package:flutter/physics.dart';

/// Spring configurations for fluid UI animations
class SpringConfigs {
  /// Card snap-back spring
  /// Card snap-back spring
  static const cardSnapBack = SpringDescription(
    mass: 0.8,
    stiffness: 350,
    damping: 28,
  );

  /// Reset spring (more damped)
  /// Reset spring (more damped)
  static const reset = SpringDescription(
    mass: 0.8,
    stiffness: 350,
    damping: 35,
  );

  /// Menu toggle spring
  /// Menu toggle spring
  static const menuToggle = SpringDescription(
    mass: 0.8,
    stiffness: 120,
    damping: 18,
  );

  /// Sensor smoothing spring
  /// Sensor smoothing spring
  static const sensorSmooth = SpringDescription(
    mass: 1.0,
    stiffness: 100,
    damping: 22,
  );
}

/// General animation constants used across the application
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
