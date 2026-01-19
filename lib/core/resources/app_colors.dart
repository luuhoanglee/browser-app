import 'dart:ui' show Color;

import 'package:flutter/material.dart' show Colors;

class AppColors {
  static const Color greenPrimary = Color(0xFF83BD1B);
  static const Color greenSecondary = Color(0xFFB5D776);
  static const Color greenTertiary = Color(0xFFDAECBB);
  static const Color green60 = Color(0xFFB5D776);
  static const Color green30 = Color(0xFFDAECBB);
  static const Color green10 = Color(0xFFF3F9E9);

  static const Color greyPrimary = Color(0xFFBCBCBC);
  static const Color greySecondary = Color(0xFFF3F6F1);
  static const Color greyTertiary = Color(0xFFE5E5E5);

  static const Color blackPrimary = Color(0xFF1D1D1D);
  static const Color blackSecondary = Color(0xFF777777);
  static const Color blackTertiary = Color(0xFFBCBCBC);
  static const Color black = Color(0xFF000000);
  static const Color black60 = Color(0xFF777777);
  static const Color black30 = Color(0xFFBCBCBC);
  static const Color black10 = Color(0xFFE9E9E9);

  static const Color iconColor = Color(0xFF6B6B6B);

  static const Color textDivider = Color(0xFF6B6B6B);

  static const Color white = Color(0xFFFFFFFF);

  static const Color textFieldError = Color(0xFFFF0000);

  static const Color titleTextField = Color(0xFF6B6B6B);

  static const Color overlayColorHoverOutLine = Color(0xFF6FA015);
  static const Color overlayColorPressOutLine = Colors.transparent;

  static const Color foregroundColorHoverOutLine = Color(0xFF000000);
  static const Color foregroundColorPressOutLine = Color(0xFF213301);

  static const Color overlayColorPress = Color(0xFF213301);

  static const Color btnBorderLoginGoogle = Color(0xFFF24822);
  static const Color btnForegroundLoginThird = Color(0xFF485068);

  static const Color noteUploadFiles = Color(0xFF485068);

  static const Color hintText = Color(0xFF6B6B6B);

  static const Color dotNotify = Color(0xFFFF1414);

  static const Color borderColorLoading = Color(0xFFEAECEE);

  static Color withOpacity(Color base, double opacity) {
    return base.withValues(alpha: opacity);
  }
}
