import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma дизайны өнгөнүүд (SkillMate/Colors)
class C {
  static const primary = Color(0xFF4F46E5);
  static const primaryTint = Color(0xFFEEF2FF);
  static const secondary = Color(0xFF14B8A6);
  static const secondaryTint = Color(0xFFCCFBF1);
  static const secondaryDark = Color(0xFF0F766E);
  static const accent = Color(0xFFF59E0B);
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const error = Color(0xFFEF4444);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary, error: C.error),
    scaffoldBackgroundColor: C.bg,
  );
  OutlineInputBorder b(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c));
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: C.text, displayColor: C.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: b(C.border), enabledBorder: b(C.border), focusedBorder: b(C.primary), errorBorder: b(C.error),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: shape, backgroundColor: C.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: shape, foregroundColor: C.text,
          side: const BorderSide(color: C.border), textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface, indicatorColor: C.primaryTint,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    ),
  );
}
