
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A); // Dark Slate
  static const Color sidebar = Color(0xFF1E293B); // Slightly lighter
  static const Color primary = Color(0xFF3B82F6); // Blue
  static const Color accent = Color(0xFF8B5CF6); // Purple
  static const Color text = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppConstants {
  static const String appName = 'Nexus AI Dashboard';
  static const String settingsBox = 'settingsBox';
  static const String secretsBox = 'secretsBox';
  static const String chatBox = 'chatBox';
}
