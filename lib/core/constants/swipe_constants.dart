class SwipeConstants {
  // Animation durations
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 200);
  static const Duration hideControlsDuration = Duration(seconds: 3);
  static const Duration videoPositionUpdateInterval = Duration(
    milliseconds: 500,
  );
  static const Duration seekStepDuration = Duration(seconds: 10);

  // UI dimensions (percentages of screen)
  static const double videoHeightRatio = 0.48;
  static const double cardHeightRatio = 0.75;
  static const double cardWidthRatio = 0.9;
  static const double infoSectionHeightRatio = 0.27;

  // Swipe thresholds
  static const double swipeThreshold = 80.0;
  static const double maxRotationAngle = 0.1;
  static const double scaleAnimationMin = 0.95;
  static const double scaleAnimationMax = 1.0;

  // Video player settings
  static const double seekBarHeight = 4.0;
  static const double controlButtonSize = 48.0;
  static const double progressIndicatorSize = 20.0;

  // Accessibility
  static const String playButtonSemanticLabel = 'Videoyu oynat';
  static const String pauseButtonSemanticLabel = 'Videoyu duraklat';
  static const String fullscreenButtonSemanticLabel = 'Tam ekran yap';
  static const String exitFullscreenSemanticLabel = 'Tam ekrandan çık';
  static const String likeButtonSemanticLabel = 'Bu filmi beğen';
  static const String dislikeButtonSemanticLabel = 'Bu filmi beğenme';
  static const String nextMovieSemanticLabel = 'Sonraki filme geç';
  static const String movieInfoSemanticFormat =
      'Film: %s. Yönetmen: %s. Tür: %s. Yıl: %d';

  // Error messages
  static const String videoLoadError = 'Video yüklenirken hata oluştu';
  static const String movieLoadError = 'Filmler yüklenirken hata oluştu';
  static const String networkError = 'İnternet bağlantısı kontrol edilsin';
  static const String retryButtonText = 'Yeniden Dene';

  // Performance
  static const int maxCachedVideos = 3;
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const int maxRetryAttempts = 3;
}
