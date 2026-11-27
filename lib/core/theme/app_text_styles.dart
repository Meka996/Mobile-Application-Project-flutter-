import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: AppColors.mutedText),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  );

  static TextStyle? price(BuildContext context, {bool prominent = false}) {
    final theme = Theme.of(context);
    final style = prominent
        ? theme.textTheme.headlineSmall
        : theme.textTheme.titleMedium;
    return style?.copyWith(color: theme.colorScheme.primary);
  }
}
