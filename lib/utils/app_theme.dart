import 'package:flutter/material.dart';

class AppTheme {
  // Balanced Black, White, Orange Theme
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkGray = Color(0xFF1C1C1C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F8F8);
  static const Color lightGray = Color(0xFFE5E5E5);
  static const Color orange = Color(0xFFFF6B35);  // Softer orange
  static const Color orangeLight = Color(0xFFFF8C61);
  static const Color orangeDark = Color(0xFFE85A2B);
  
  // Balanced Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1C1C1C), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient whiteGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8C61), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Typography
  static const TextStyle heroText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: black,
    letterSpacing: 0.5,
  );
  
  static const TextStyle narrativeText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: black,
    letterSpacing: 0.3,
  );
  
  static const TextStyle dataText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: darkGray,
    letterSpacing: 0.2,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
    letterSpacing: 0.8,
  );
  
  // Theme
  static ThemeData get theme {
    return ThemeData(
      primaryColor: orange,
      scaffoldBackgroundColor: offWhite,
      colorScheme: const ColorScheme.light(
        primary: orange,
        secondary: orangeLight,
        surface: white,
        background: offWhite,
      ),
      useMaterial3: true,
    );
  }
  
  // White Glossy Card
  static BoxDecoration whiteCard({double borderRadius = 20}) {
    return BoxDecoration(
      gradient: whiteGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: orange.withOpacity(0.1),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }
  
  // Black Glossy Card
  static BoxDecoration blackCard({double borderRadius = 20}) {
    return BoxDecoration(
      color: black,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: orange.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: orange.withOpacity(0.2),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
  
  // Orange Button
  static BoxDecoration orangeButton({bool isPressed = false}) {
    return BoxDecoration(
      gradient: orangeGradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: orange.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
          : [
              BoxShadow(
                color: orange.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }
  
  // Animations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  
  // Spacing
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
}
