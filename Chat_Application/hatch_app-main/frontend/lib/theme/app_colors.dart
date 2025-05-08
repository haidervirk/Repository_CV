import 'package:flutter/material.dart';

class AppColors {
  static Map<String, Map<String, dynamic>> themes = {
    'dark': {
      'brightness': Brightness.dark,
      'skeletonload': Colors.white24,
      'skeletonColor': Colors.grey[900]!,
      'textShadow': Colors.black87,
      'primaryColor': const Color.fromRGBO(131, 103, 255, 1),
      'secondaryColor': Colors.white,
      'errorColor': Colors.redAccent,
      'backgroundColor': const Color.fromRGBO(42, 50, 72, 1),
      'bottomSheetBgColor': const Color.fromRGBO(30, 36, 52, 1),
      'foregroundColor': Colors.white,
      'textColor': Colors.white,
      'lightTextColor': Colors.white.withValues(alpha: 0.8),
      'lighterTextColor': Colors.white54,
      'lightestTextColor': Colors.white38,
      'textColorInvert': Colors.black,
      'lighttextColorInvert': Colors.black87,
      'lighterTextColorInvert': Colors.black54,
      'highlightColor': Colors.black,
      'navbarUnselectedColor': Colors.white30,
    },
  };

  static String currentTheme = 'dark';

  static Brightness get brightness => currentTheme == 'system' ? MediaQueryData.fromView(WidgetsBinding.instance.window).platformBrightness : themes[currentTheme]!['brightness']!;
  static Color get skeletonload => themes[currentTheme]!['skeletonload']!;
  static Color get skeletonColor => themes[currentTheme]!['skeletonColor']!;
  static Color get textShadow => themes[currentTheme]!['textShadow']!;
  static Color get primaryColor => themes[currentTheme]!['primaryColor']!;
  static Color get secondaryColor => themes[currentTheme]!['secondaryColor']!;
  static Color get errorColor => themes[currentTheme]!['errorColor']!;
  static Color get backgroundColor => themes[currentTheme]!['backgroundColor']!;
  static Color get bottomSheetBgColor => themes[currentTheme]!['bottomSheetBgColor']!;
  static Color get foregroundColor => themes[currentTheme]!['foregroundColor']!;
  static Color get textColor => themes[currentTheme]!['textColor']!;
  static Color get lightTextColor => themes[currentTheme]!['lightTextColor']!;
  static Color get lighterTextColor => themes[currentTheme]!['lighterTextColor']!;
  static Color get lightestTextColor => themes[currentTheme]!['lightestTextColor']!;
  static Color get textColorInvert => themes[currentTheme]!['textColorInvert']!;
  static Color get lighttextColorInvert => themes[currentTheme]!['lighttextColorInvert']!;
  static Color get lighterTextColorInvert => themes[currentTheme]!['lighterTextColorInvert']!;
  static Color get highlightColor => themes[currentTheme]!['highlightColor']!;
  static Color get navbarUnselectedColor => themes[currentTheme]!['navbarUnselectedColor']!;
}
