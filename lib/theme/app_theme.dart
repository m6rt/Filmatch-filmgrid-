import 'package:flutter/material.dart';

class AppTheme {
  // Tinder Color Palette
  static const Color primaryRed = Color(0xFFFF4458); // Tinder Red
  static const Color primaryOrange = Color(0xFFFF6B35); // Tinder Orange
  static const Color secondaryGrey = Color(0xFF9E9E9E); // Medium Grey
  static const Color lightGrey = Color(0xFFF5F5F5); // Light Background
  static const Color darkGrey = Color(0xFF424242); // Dark Text
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryOrange],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightGrey, Color(0xFFEAEAEA)],
  );

  // Genre Color Mappings
  static Color getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'action':
        return primaryRed;
      case 'adventure':
        return primaryOrange;
      case 'comedy':
        return Color(0xFFFFB347); // Light Orange
      case 'drama':
        return Color(0xFFFF8A80); // Light Red
      case 'fantasy':
        return Color(0xFFFFAB91); // Peach
      case 'horror':
        return Color(0xFFFF5722); // Deep Orange
      case 'mystery':
        return Color(0xFFFF7043); // Medium Orange
      case 'romance':
        return primaryRed;
      case 'science fiction':
        return Color(0xFFFF6F00); // Orange
      case 'thriller':
        return Color(0xFFE64A19); // Dark Orange
      case 'crime':
        return Color(0xFFFF5722); // Deep Orange
      case 'documentary':
        return Color(0xFFFFB74D); // Light Orange
      case 'family':
        return Color(0xFFFFCC80); // Very Light Orange
      case 'history':
        return Color(0xFFFF8A65); // Coral
      default:
        return primaryOrange;
    }
  }

  // Material Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: primaryOrange,
        surface: white,
        background: lightGrey,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: "Caveat Brush",
          fontSize: 32,
          color: white,
          fontWeight: FontWeight.normal,
        ),
        iconTheme: IconThemeData(color: white),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryRed),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryRed),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryRed,
        contentTextStyle: TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: darkGrey),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(fontFamily: 'PlayfairDisplay', color: darkGrey),
        bodyMedium: TextStyle(fontFamily: 'PlayfairDisplay', color: darkGrey),
        bodySmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: secondaryGrey,
        ),
        labelLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: white,
          fontWeight: FontWeight.bold,
        ),
        labelMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: darkGrey,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: secondaryGrey,
        ),
      ),
    );
  }

  // Custom Widgets Helper
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: black.withOpacity(0.1),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration get buttonDecoration {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: primaryRed.withOpacity(0.4),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration get dislikeButtonDecoration {
    return BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: secondaryGrey, width: 2),
      boxShadow: [
        BoxShadow(
          color: black.withOpacity(0.1),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}
