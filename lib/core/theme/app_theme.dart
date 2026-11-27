import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text_styles.dart';

class AppTheme {
  static final lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blushPink,
      primary: AppColors.action,
      onPrimary: AppColors.onAction,
      primaryContainer: AppColors.blushPink,
      onPrimaryContainer: AppColors.onPink,
      secondary: AppColors.onPink,
      onSecondary: AppColors.onAction,
      secondaryContainer: AppColors.babyPink,
      onSecondaryContainer: AppColors.onPink,
      surface: AppColors.offWhite,
      surfaceContainer: AppColors.surface,
      surfaceContainerHighest: AppColors.babyPink,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.mutedText,
      outline: AppColors.border,
      outlineVariant: AppColors.softBorder,
      error: AppColors.error,
      onError: AppColors.onAction,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
      inverseSurface: AppColors.text,
      onInverseSurface: AppColors.offWhite,
      inversePrimary: AppColors.babyPink,
    );
    const text = AppTextStyles.textTheme;
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppLayout.radius),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppLayout.cardRadius),
      side: BorderSide(color: scheme.outlineVariant),
    );
    const controlSize = Size(0, AppLayout.controlHeight);
    const controlPadding = EdgeInsets.symmetric(
      horizontal: AppLayout.large,
      vertical: AppLayout.medium,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      iconTheme: IconThemeData(color: scheme.primary),
      appBarTheme: AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        showUnselectedLabels: true,
        selectedLabelStyle: text.labelMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.onDisabled,
          minimumSize: controlSize,
          padding: controlPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: AppColors.onDisabled,
          side: BorderSide(color: scheme.outline),
          minimumSize: controlSize,
          padding: controlPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: controlSize,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: scheme.secondaryContainer,
        disabledColor: AppColors.disabled,
        checkmarkColor: scheme.onSecondaryContainer,
        side: BorderSide(color: scheme.outline),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        shape: controlShape,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.primary,
        contentPadding: controlPadding,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        errorMaxLines: 3,
        border: _fieldBorder(scheme.outline),
        enabledBorder: _fieldBorder(scheme.outline),
        focusedBorder: _fieldBorder(scheme.primary, width: 2),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 2),
        disabledBorder: _fieldBorder(scheme.outlineVariant),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.deepRose,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: cardShape,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: controlShape,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppLayout.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
