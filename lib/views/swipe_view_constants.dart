class SwipeViewConstants {
  // Animation durations
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 400);
  static const Duration stepDuration = Duration(milliseconds: 10);
  static const Duration hideControlsDuration = Duration(seconds: 3);
  static const Duration positionUpdateInterval = Duration(milliseconds: 500);

  // UI dimensions (screen ratios)
  static const double cardWidthRatio = 0.9;
  static const double cardHeightRatio = 0.75;
  static const double videoHeightRatio = 0.48;
  static const double infoHeightRatio = 0.27;

  // Swipe thresholds
  static const double swipeThreshold = 80.0;
  static const double maxSwipeOffset = 400.0;
  static const double maxRotationMultiplier = 0.3;
  static const double maxRotationDivider = 300.0;
  static const double scaleMin = 0.8;
  static const double scaleMax = 1.0;
  static const double scaleMinClamp = 0.9;
  static const double scaleDivider = 1000.0;

  // Animation steps
  static const int swipeAnimationSteps = 30;
  static const int resetAnimationSteps = 20;

  // Button sizes
  static const double actionButtonSize = 65.0;
  static const double actionButtonIconSize = 32.0;

  // Fullscreen video
  static const double aspectRatio = 16 / 9;
  static const double playButtonSize = 40.0;
  static const double seekButtonSize = 24.0;
  static const int seekSeconds = 10;
  static const int defaultTrailerMinutes = 3;

  // Error messages
  static const String noTrailerMessage = 'Bu film için trailer bulunamadı';
  static const String movieLoadError = 'Film yükleme hatası';
  static const String noMovieMessage = 'Gösterilecek film bulunamadı!';
  static const String restartMessage = 'Lütfen uygulamayı yeniden başlatın.';
  static const String retryButtonText = 'Yeniden Yükle';
  static const String loadingMessage = 'Filmler yükleniyor...';

  // Feedback messages
  static const String likedMessage = 'Liked!';
  static const String dislikedMessage = 'Disliked!';

  // Accessibility labels
  static const String statisticsLabel = 'İstatistikler';
  static const String searchLabel = 'Arama';
  static const String profileLabel = 'Profil';
  static const String likeButtonLabel = 'Filmi beğen';
  static const String dislikeButtonLabel = 'Filmi beğenme';
  static const String fullscreenLabel = 'Tam ekran';
  static const String closeLabel = 'Kapat';
  static const String playLabel = 'Oynat';
  static const String pauseLabel = 'Duraklat';
}
