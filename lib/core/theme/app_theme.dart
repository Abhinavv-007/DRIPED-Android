import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const base = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.ink,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.inkCard,
      onSurface: AppColors.textHi,
      error: AppColors.danger,
      onError: AppColors.textHi,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.ink,
      canvasColor: AppColors.ink,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.glassFill,
      dividerColor: AppColors.hairline,
      textTheme: TextTheme(
        displayLarge: AppTypography.heroNumber,
        displayMedium: AppTypography.bigNumber,
        displaySmall: AppTypography.midNumber,
        headlineLarge: AppTypography.pageTitle,
        headlineMedium: AppTypography.sectionTitle,
        titleLarge: AppTypography.cardTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.buttonMd,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.micro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        disabledElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      iconTheme: const IconThemeData(color: AppColors.text, size: 22),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inkOverlay,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.textHi),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.inkOverlay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.ink,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbColor: AppColors.gold,
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.glassFill,
        overlayColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.textMid,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.glassFill,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll(AppColors.glassBorder),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textLow),
        labelStyle: AppTypography.caption,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.danger),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassFill,
        side: const BorderSide(color: AppColors.glassBorder),
        selectedColor: AppColors.gold,
        secondarySelectedColor: AppColors.gold,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: AppTypography.caption.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.glassFillHi),
        radius: const Radius.circular(2),
      ),
    );
  }

  static ThemeData get light {
    const base = ColorScheme.light(
      primary: AppColors.gold,
      onPrimary: AppColors.ink,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightText,
      error: AppColors.danger,
      onError: AppColors.lightCard,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.lightCream,
      canvasColor: AppColors.lightCream,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.lightHair,
      textTheme: TextTheme(
        displayLarge: AppTypography.heroNumber.copyWith(color: AppColors.lightText),
        displayMedium: AppTypography.bigNumber.copyWith(color: AppColors.lightText),
        displaySmall: AppTypography.midNumber.copyWith(color: AppColors.lightText),
        headlineLarge: AppTypography.pageTitle.copyWith(color: AppColors.lightText),
        headlineMedium: AppTypography.sectionTitle.copyWith(color: AppColors.lightText),
        titleLarge: AppTypography.cardTitle.copyWith(color: AppColors.lightText),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.lightText),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.lightText),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.lightTextMid),
        labelLarge: AppTypography.buttonMd.copyWith(color: AppColors.lightText),
        labelMedium: AppTypography.label.copyWith(color: AppColors.lightTextMid),
        labelSmall: AppTypography.micro.copyWith(color: AppColors.lightTextMid),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightText, size: 22),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightCard,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.lightText),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCream,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.lightCream,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.lightCard
              : AppColors.lightTextMid,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : Colors.grey.shade300,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        hintStyle: AppTypography.body.copyWith(color: AppColors.lightTextMid),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: Colors.grey.shade300),
        selectedColor: AppColors.gold,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.lightText,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
