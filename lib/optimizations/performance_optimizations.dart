import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimizations for the movie recommendation system
class PerformanceOptimizations {
  // 1. Batch size'ı dinamik olarak ayarla
  static int getOptimalBatchSize() {
    // Cihazın performansına göre batch size ayarla
    final deviceMemory = Platform.operatingSystem == 'ios' ? 1024 : 512; // MB
    return deviceMemory > 512 ? 50 : 25;
  }

  // 2. Image preloading
  static void preloadImages(List<String> imageUrls, BuildContext context) {
    for (String url in imageUrls.take(5)) {
      // Sadece ilk 5'ini preload et
      precacheImage(NetworkImage(url), context);
    }
  }

  // 3. Debounced search
  static Timer? _searchTimer;
  static void debouncedSearch(String query, Function(String) onSearch) {
    _searchTimer?.cancel();
    _searchTimer = Timer(Duration(milliseconds: 500), () {
      onSearch(query);
    });
  }

  // 4. Memory monitoring
  static void logMemoryUsage() {
    if (kDebugMode) {
      print('Memory usage monitoring would be here');
      // Production'da Firebase Performance kullanılabilir
    }
  }
}
