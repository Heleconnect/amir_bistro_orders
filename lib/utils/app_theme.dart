import 'package:flutter/material.dart';

/// 🎨 ألوان التطبيق
class AppColors {
  static const primary = Color(0xFF1F4E6D);
  static const white = Color(0xFFFFFFFF);
  static const lightGrey = Color(0xFFF5F5F5);
  static const greyText = Color(0xFF555555);
  static const blackText = Color(0xFF000000);
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);
}

/// ✍️ الخطوط والستايلات
class AppFonts {
  static const mainTitle = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: AppColors.blackText,
  );

  static const subtitle = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w500,
    fontSize: 18,
    color: AppColors.greyText,
  );

  static const buttonText = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.white,
  );
}

/// 🖌️ الثيم العام (Light & Dark)
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    canvasColor: AppColors.lightGrey,
    cardColor: const Color(0xFFF0F0F0),

    textTheme: const TextTheme(
      displayLarge: AppFonts.mainTitle,
      headlineMedium: AppFonts.subtitle,
      bodyLarge: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.normal,
        fontSize: 16,
        color: AppColors.blackText,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.normal,
        fontSize: 14,
        color: AppColors.greyText,
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.primary),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        textStyle: AppFonts.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppFonts.buttonText.copyWith(color: AppColors.primary),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.blackText,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        color: AppColors.greyText,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    fontFamily: 'Cairo',
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFF000000),
    canvasColor: const Color(0xFF1A1A1A),
    cardColor: const Color(0xFF2A2A2A),

    textTheme: const TextTheme(
      displayLarge: AppFonts.mainTitle,
      headlineMedium: AppFonts.subtitle,
      bodyLarge: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.normal,
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.normal,
        fontSize: 14,
        color: Color(0xFFAAAAAA),
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.primary),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        textStyle: AppFonts.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppFonts.buttonText.copyWith(color: AppColors.primary),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.white,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        color: Color(0xFFAAAAAA),
      ),
    ),
  );
}