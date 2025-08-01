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
        return const Color(0xFFE74C3C); // Kırmızı
      case 'adventure':
        return const Color(0xFF3498DB); // Mavi
      case 'animation':
        return const Color(0xFF9B59B6); // Mor
      case 'comedy':
        return const Color(0xFFF39C12); // Turuncu
      case 'crime':
        return const Color(0xFF34495E); // Koyu gri
      case 'documentary':
        return const Color(0xFF16A085); // Teal
      case 'drama':
        return const Color(0xFF8E44AD); // Koyu mor
      case 'family':
        return const Color(0xFF2ECC71); // Yeşil
      case 'fantasy':
        return const Color(0xFFE67E22); // Portakal
      case 'history':
        return const Color(0xFF95A5A6); // Açık gri
      case 'horror':
        return const Color(0xFF000000); // Siyah
      case 'music':
        return const Color(0xFFF1C40F); // Sarı
      case 'mystery':
        return const Color(0xFF7F8C8D); // Gri
      case 'romance':
        return const Color(0xFFE91E63); // Pembe
      case 'science fiction':
        return const Color(0xFF1ABC9C); // Cyan
      case 'tv movie':
        return const Color(0xFF3F51B5); // Indigo
      case 'thriller':
        return const Color(0xFF607D8B); // Blue Grey
      case 'war':
        return const Color(0xFF795548); // Kahverengi
      case 'western':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return primaryRed;
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
