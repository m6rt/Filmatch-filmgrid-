import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/movie.dart';
import '../services/batch_optimized_movie_service.dart';
import '../widgets/optimized_video_player.dart';
import '../theme/app_theme.dart';
import 'swipe_view_constants.dart';

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> with TickerProviderStateMixin {
  bool _isLoading = true;

  // Film servisi
  final BatchOptimizedMovieService _movieService = BatchOptimizedMovieService();
  Movie? _currentMovie;

  // Video pozisyonunu saklamak için
  Duration? _currentVideoPosition;
  GlobalKey<OptimizedVideoPlayerState>? _videoPlayerKey;

  // Tinder benzeri animasyon değişkenleri
  late AnimationController _swipeAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  double _swipeOffset = 0.0;
  double _rotationAngle = 0.0;
  double _scale = 1.0;
  bool _isSwipeInProgress = false;

  // Timer'ları track et (Memory leak fix)
  final List<Timer> _activeTimers = [];

  void _addTimer(Timer timer) {
    _activeTimers.add(timer);
  }

  void _cancelAllTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  @override
  void initState() {
    super.initState();
    _videoPlayerKey = GlobalKey<OptimizedVideoPlayerState>();
    _initializeAnimations();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _movieService.initializeService();
      _currentMovie = _movieService.currentMovie;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('${SwipeViewConstants.movieLoadError}: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeAnimations() {
    // Swipe animasyonu
    _swipeAnimationController = AnimationController(
      duration: SwipeViewConstants.swipeAnimationDuration,
      vsync: this,
    );

    // Fade animasyonu
    _fadeAnimationController = AnimationController(
      duration: SwipeViewConstants.fadeAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimationController.forward();
  }

  // Tinder benzeri pan update
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwipeInProgress) return;

    setState(() {
      _swipeOffset += details.delta.dx;
      _rotationAngle =
          (_swipeOffset / SwipeViewConstants.maxRotationDivider) *
          SwipeViewConstants.maxRotationMultiplier;
      _scale = 1.0 - (_swipeOffset.abs() / SwipeViewConstants.scaleDivider);
      _scale = _scale.clamp(
        SwipeViewConstants.scaleMinClamp,
        SwipeViewConstants.scaleMax,
      );
      _swipeOffset = _swipeOffset.clamp(
        -SwipeViewConstants.maxSwipeOffset,
        SwipeViewConstants.maxSwipeOffset,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSwipeInProgress) return;

    if (_swipeOffset.abs() > SwipeViewConstants.swipeThreshold) {
      _animateSwipe(_swipeOffset > 0);
    } else {
      _resetSwipePosition();
    }
  }

  void _animateSwipe(bool isLike) {
    setState(() {
      _isSwipeInProgress = true;
    });

    if (_currentMovie != null) {
      _movieService.recordUserAction(
        _currentMovie!,
        isLike ? SwipeAction.like : SwipeAction.dislike,
      );
      _movieService.printUserPreferences();
    }

    double targetOffset = isLike ? 500.0 : -500.0;
    double targetRotation = isLike ? 0.5 : -0.5;

    _swipeAnimationController.forward().then((_) {
      _showFeedback(isLike);
      _nextCardWithAnimation();
    });

    _updateSwipeAnimation(targetOffset, targetRotation);
  }

  void _updateSwipeAnimation(double targetOffset, double targetRotation) {
    const steps = SwipeViewConstants.swipeAnimationSteps;
    const stepDuration = SwipeViewConstants.stepDuration;

    double startOffset = _swipeOffset;
    double startRotation = _rotationAngle;
    double startScale = _scale;

    int currentStep = 0;

    final timer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      double progress = currentStep / steps;

      if (progress >= 1.0 || !mounted) {
        timer.cancel();
        _activeTimers.remove(timer);
        return;
      }

      setState(() {
        _swipeOffset = startOffset + (targetOffset - startOffset) * progress;
        _rotationAngle =
            startRotation + (targetRotation - startRotation) * progress;
        _scale =
            startScale + (SwipeViewConstants.scaleMin - startScale) * progress;
      });
    });

    _addTimer(timer);
  }

  void _resetSwipePosition() {
    const steps = SwipeViewConstants.resetAnimationSteps;
    const stepDuration = SwipeViewConstants.stepDuration;

    double startOffset = _swipeOffset;
    double startRotation = _rotationAngle;
    double startScale = _scale;

    int currentStep = 0;

    final timer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      double progress = currentStep / steps;

      if (progress >= 1.0 || !mounted) {
        timer.cancel();
        _activeTimers.remove(timer);
        setState(() {
          _swipeOffset = 0.0;
          _rotationAngle = 0.0;
          _scale = 1.0;
        });
        return;
      }

      setState(() {
        _swipeOffset = startOffset * (1.0 - progress);
        _rotationAngle = startRotation * (1.0 - progress);
        _scale =
            startScale + (SwipeViewConstants.scaleMax - startScale) * progress;
      });
    });

    _addTimer(timer);
  }

  Future<void> _nextCardWithAnimation() async {
    await _fadeAnimationController.reverse();

    setState(() {
      _swipeOffset = 0.0;
      _rotationAngle = 0.0;
      _scale = 1.0;
      _isSwipeInProgress = false;
      // Video pozisyonunu sıfırla
      _currentVideoPosition = null;
      // Video player key'ini de yenile
      _videoPlayerKey = GlobalKey<OptimizedVideoPlayerState>();
    });

    // Yeni filmi al
    _currentMovie = _movieService.getNextMovie();

    _swipeAnimationController.reset();
    await _fadeAnimationController.forward();
  }

  void _showFeedback(bool isLike) {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLike ? Icons.favorite : Icons.close, color: AppTheme.white),
            SizedBox(width: 8),
            Text(
              isLike
                  ? SwipeViewConstants.likedMessage
                  : SwipeViewConstants.dislikedMessage,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: isLike ? AppTheme.primaryRed : AppTheme.secondaryGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showFullscreenVideo() {
    if (_currentMovie?.trailerUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SwipeViewConstants.noTrailerMessage),
          backgroundColor: AppTheme.secondaryGrey,
        ),
      );
      return;
    }

    // Mevcut video pozisyonunu al
    final currentState = _videoPlayerKey?.currentState;
    if (currentState != null) {
      _currentVideoPosition = currentState.currentPosition ?? Duration.zero;
      print(
        'Ana ekran video pozisyonu: ${_currentVideoPosition?.inSeconds} saniye',
      );
    } else {
      _currentVideoPosition = Duration.zero;
      print('Video player state bulunamadı, sıfırdan başlayacak');
    }

    // Tam ekrana geçerken otomatik yatay çevir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (context) {
        return _CustomFullscreenVideoPlayer(
          trailerUrl: _currentMovie!.trailerUrl!,
          initialPosition: _currentVideoPosition,
          onClose: (position) {
            // Tam ekrandan çıkışta pozisyonu ana player'a aktar
            if (position != null) {
              print('Fullscreen pozisyonu: ${position.inSeconds} saniye');
              Future.delayed(Duration(milliseconds: 100), () {
                _videoPlayerKey?.currentState?.seekTo(position);
              });
            }

            // Dikey moda geri dön
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          },
        );
      },
    );
  }

  void _showSampleDialog(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '📱 $title',
              style: TextStyle(fontSize: isTablet ? 20 : 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is a sample UI. You can integrate your API here.',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                if (title == 'Statistics') ...[
                  SizedBox(height: isTablet ? 15 : 10),
                  Text(
                    '📊 Toplam eylem: ${_movieService.totalActionsRecorded}',
                    style: TextStyle(fontSize: isTablet ? 15 : 13),
                  ),
                  Text(
                    '🎬 Batch\'te kalan: ${_movieService.moviesRemainingInBatch}',
                    style: TextStyle(fontSize: isTablet ? 15 : 13),
                  ),
                  SizedBox(height: isTablet ? 15 : 10),
                  ElevatedButton(
                    onPressed: () {
                      _movieService.printUserPreferences();
                      _movieService.printBatchStatus();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 12 : 8,
                      ),
                    ),
                    child: Text(
                      'Batch Durumunu Konsola Yazdır',
                      style: TextStyle(fontSize: isTablet ? 14 : 12),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 12 : 8,
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // Timer'ları iptal et (Memory leak prevention)
    _cancelAllTimers();

    // Animation controller'ları dispose et
    _swipeAnimationController.dispose();
    _fadeAnimationController.dispose();

    // Video player key'ini temizle
    _videoPlayerKey = null;

    super.dispose();
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isTablet,
  ) {
    return Row(
      children: [
        Icon(icon, size: isTablet ? 18 : 16, color: AppTheme.secondaryGrey),
        SizedBox(width: isTablet ? 10 : 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isTablet ? 14 : 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: isTablet ? 15 : 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getMovieColor(Movie movie) {
    if (movie.genre.isEmpty) return AppTheme.primaryOrange;
    return AppTheme.getGenreColor(movie.genre.first);
  }

  double _calculateMovieRating(Movie movie) {
    double rating = 5.0;
    if (movie.year > 2015) rating += 1.0;
    if (movie.year > 2020) rating += 0.5;
    rating += movie.genre.length * 0.2;
    rating += movie.cast.length * 0.1;
    return rating.clamp(1.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryRed),
              SizedBox(height: screenHeight * 0.025),
              Text(
                SwipeViewConstants.loadingMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentMovie == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_creation_outlined,
                  size: isTablet ? 120 : 80,
                  color: AppTheme.darkGrey,
                ),
                SizedBox(height: screenHeight * 0.025),
                Text(
                  SwipeViewConstants.noMovieMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: isTablet ? 24 : 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  SwipeViewConstants.restartMessage,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: isTablet ? 16 : 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.04),
                ElevatedButton(
                  onPressed: _loadMovies,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                  child: Text(
                    SwipeViewConstants.retryButtonText,
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: SwipeViewConstants.statisticsLabel,
          child: IconButton(
            onPressed: () => _showSampleDialog('Statistics'),
            icon: Icon(Icons.analytics),
            tooltip: SwipeViewConstants.statisticsLabel,
          ),
        ),
        title: Text("Swipe"),
        actions: [
          Semantics(
            label: SwipeViewConstants.searchLabel,
            child: IconButton(
              onPressed: () => _showSampleDialog('Search'),
              icon: Icon(Icons.search),
              tooltip: SwipeViewConstants.searchLabel,
            ),
          ),
          Semantics(
            label: SwipeViewConstants.profileLabel,
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: Icon(Icons.person),
              tooltip: SwipeViewConstants.profileLabel,
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.backgroundGradient,
                    ),
                  ),

                  // Ana kart
                  Center(
                    child: Transform.translate(
                      offset: Offset(
                        _swipeOffset,
                        -50,
                      ), // Daha yukarı kaldırdık
                      child: Transform.rotate(
                        angle: _rotationAngle,
                        child: Transform.scale(
                          scale: _scale,
                          child: GestureDetector(
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: Container(
                              width:
                                  screenWidth *
                                  (isTablet
                                      ? 0.7
                                      : SwipeViewConstants.cardWidthRatio),
                              height:
                                  screenHeight *
                                  (isTablet
                                      ? 0.8
                                      : SwipeViewConstants.cardHeightRatio),
                              decoration: AppTheme.cardDecoration,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 24 : 20,
                                ),
                                child: Stack(
                                  children: [
                                    // Video container
                                    Container(
                                      width: double.infinity,
                                      height:
                                          screenHeight *
                                          SwipeViewConstants.videoHeightRatio,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                            isTablet ? 24 : 20,
                                          ),
                                          topRight: Radius.circular(
                                            isTablet ? 24 : 20,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                            isTablet ? 24 : 20,
                                          ),
                                          topRight: Radius.circular(
                                            isTablet ? 24 : 20,
                                          ),
                                        ),
                                        child:
                                            _currentMovie?.trailerUrl != null
                                                ? Stack(
                                                  children: [
                                                    OptimizedVideoPlayer(
                                                      key: _videoPlayerKey,
                                                      trailerUrl:
                                                          _currentMovie!
                                                              .trailerUrl,
                                                      backgroundColor:
                                                          _getMovieColor(
                                                            _currentMovie!,
                                                          ),
                                                      autoPlay: false,
                                                    ),
                                                    Positioned(
                                                      top: isTablet ? 20 : 16,
                                                      right: isTablet ? 20 : 16,
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          isTablet ? 12 : 8,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                isTablet
                                                                    ? 24
                                                                    : 20,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.play_arrow,
                                                              color:
                                                                  Colors.white,
                                                              size:
                                                                  isTablet
                                                                      ? 20
                                                                      : 16,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  isTablet
                                                                      ? 6
                                                                      : 4,
                                                            ),
                                                            Text(
                                                              'Trailer',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize:
                                                                    isTablet
                                                                        ? 14
                                                                        : 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontFamily:
                                                                    'PlayfairDisplay',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        _getMovieColor(
                                                          _currentMovie!,
                                                        ),
                                                        _getMovieColor(
                                                          _currentMovie!,
                                                        ).withOpacity(0.7),
                                                      ],
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.movie,
                                                          size:
                                                              isTablet
                                                                  ? 120
                                                                  : 80,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(
                                                          height:
                                                              isTablet
                                                                  ? 24
                                                                  : 20,
                                                        ),
                                                        Text(
                                                          'No Trailer Available',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                isTablet
                                                                    ? 22
                                                                    : 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'PlayfairDisplay',
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height:
                                                              isTablet
                                                                  ? 12
                                                                  : 10,
                                                        ),
                                                        Text(
                                                          _currentMovie
                                                                  ?.title ??
                                                              'Unknown Movie',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize:
                                                                isTablet
                                                                    ? 16
                                                                    : 14,
                                                            fontFamily:
                                                                'PlayfairDisplay',
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),

                                    // Swipe overlay
                                    if (_swipeOffset.abs() > 50)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: (_swipeOffset > 0
                                                    ? AppTheme.primaryRed
                                                    : AppTheme.secondaryGrey)
                                                .withOpacity(0.4),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(
                                                isTablet ? 24 : 20,
                                              ),
                                              topRight: Radius.circular(
                                                isTablet ? 24 : 20,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                isTablet ? 24 : 20,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _swipeOffset > 0
                                                    ? Icons.favorite
                                                    : Icons.close,
                                                size: isTablet ? 60 : 50,
                                                color:
                                                    _swipeOffset > 0
                                                        ? AppTheme.primaryRed
                                                        : AppTheme
                                                            .secondaryGrey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Film bilgileri
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height:
                                            screenHeight *
                                            SwipeViewConstants.infoHeightRatio,
                                        padding: EdgeInsets.all(
                                          isTablet ? 20 : 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.white,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(
                                              isTablet ? 24 : 20,
                                            ),
                                            bottomRight: Radius.circular(
                                              isTablet ? 24 : 20,
                                            ),
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _currentMovie!.title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            fontSize:
                                                                isTablet
                                                                    ? 24
                                                                    : 20,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: isTablet ? 12 : 8,
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              isTablet
                                                                  ? 14
                                                                  : 10,
                                                          vertical:
                                                              isTablet ? 8 : 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.primaryRed,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            isTablet ? 22 : 18,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color: AppTheme.white,
                                                          size:
                                                              isTablet
                                                                  ? 16
                                                                  : 14,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              isTablet ? 6 : 4,
                                                        ),
                                                        Text(
                                                          _calculateMovieRating(
                                                            _currentMovie!,
                                                          ).toStringAsFixed(1),
                                                          style: Theme.of(
                                                                context,
                                                              )
                                                              .textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                fontSize:
                                                                    isTablet
                                                                        ? 14
                                                                        : 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: isTablet ? 12 : 10,
                                              ),
                                              _buildInfoRow(
                                                Icons.person,
                                                'Director',
                                                _currentMovie!.director,
                                                isTablet,
                                              ),
                                              SizedBox(
                                                height: isTablet ? 6 : 4,
                                              ),
                                              _buildInfoRow(
                                                Icons.category,
                                                'Genre',
                                                _currentMovie!.genre
                                                    .take(2)
                                                    .join(', '),
                                                isTablet,
                                              ),
                                              SizedBox(
                                                height: isTablet ? 6 : 4,
                                              ),
                                              _buildInfoRow(
                                                Icons.calendar_today,
                                                'Year',
                                                _currentMovie!.year.toString(),
                                                isTablet,
                                              ),
                                              SizedBox(
                                                height: isTablet ? 6 : 4,
                                              ),
                                              _buildInfoRow(
                                                Icons.group,
                                                'Cast',
                                                _currentMovie!.cast
                                                    .take(2)
                                                    .join(', '),
                                                isTablet,
                                              ),
                                              SizedBox(
                                                height: isTablet ? 10 : 8,
                                              ),
                                              // Description - kutu olmadan
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.description,
                                                    size: isTablet ? 18 : 16,
                                                    color:
                                                        AppTheme.secondaryGrey,
                                                  ),
                                                  SizedBox(
                                                    width: isTablet ? 10 : 8,
                                                  ),
                                                  Text(
                                                    'Description: ',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              isTablet
                                                                  ? 14
                                                                  : 12,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: isTablet ? 8 : 6,
                                              ),
                                              Text(
                                                _currentMovie!.description,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.darkGrey,
                                                  height: 1.4,
                                                  fontSize: isTablet ? 14 : 12,
                                                ),
                                                maxLines: isTablet ? 5 : 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Tam ekran butonu
                                    Positioned(
                                      top: isTablet ? 20 : 16,
                                      right: isTablet ? 20 : 16,
                                      child: Semantics(
                                        label:
                                            SwipeViewConstants.fullscreenLabel,
                                        button: true,
                                        onTap: _showFullscreenVideo,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: _showFullscreenVideo,
                                            icon: Icon(
                                              Icons.fullscreen,
                                              color: Colors.white,
                                              size: isTablet ? 28 : 24,
                                            ),
                                            tooltip:
                                                SwipeViewConstants
                                                    .fullscreenLabel,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alt butonlar
                  Positioned(
                    bottom: isTablet ? 30 : 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Semantics(
                          label: SwipeViewConstants.dislikeButtonLabel,
                          button: true,
                          onTap: () => _animateSwipe(false),
                          child: GestureDetector(
                            onTap: () => _animateSwipe(false),
                            child: Container(
                              width:
                                  isTablet
                                      ? 80
                                      : SwipeViewConstants.actionButtonSize,
                              height:
                                  isTablet
                                      ? 80
                                      : SwipeViewConstants.actionButtonSize,
                              decoration: AppTheme.dislikeButtonDecoration,
                              child: Icon(
                                Icons.close,
                                color: AppTheme.secondaryGrey,
                                size:
                                    isTablet
                                        ? 40
                                        : SwipeViewConstants
                                            .actionButtonIconSize,
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          label: SwipeViewConstants.likeButtonLabel,
                          button: true,
                          onTap: () => _animateSwipe(true),
                          child: GestureDetector(
                            onTap: () => _animateSwipe(true),
                            child: Container(
                              width:
                                  isTablet
                                      ? 80
                                      : SwipeViewConstants.actionButtonSize,
                              height:
                                  isTablet
                                      ? 80
                                      : SwipeViewConstants.actionButtonSize,
                              decoration: AppTheme.buttonDecoration,
                              child: Icon(
                                Icons.favorite,
                                color: AppTheme.white,
                                size:
                                    isTablet
                                        ? 40
                                        : SwipeViewConstants
                                            .actionButtonIconSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Özel Fullscreen Video Player Widget
class _CustomFullscreenVideoPlayer extends StatefulWidget {
  final String trailerUrl;
  final Duration? initialPosition;
  final Function(Duration?) onClose;

  const _CustomFullscreenVideoPlayer({
    required this.trailerUrl,
    this.initialPosition,
    required this.onClose,
  });

  @override
  State<_CustomFullscreenVideoPlayer> createState() =>
      _CustomFullscreenVideoPlayerState();
}

class _CustomFullscreenVideoPlayerState
    extends State<_CustomFullscreenVideoPlayer> {
  late GlobalKey<OptimizedVideoPlayerState> _playerKey;
  bool _showControls = true;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _hideControlsTimer;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _playerKey = GlobalKey<OptimizedVideoPlayerState>();
    _startHideControlsTimer();
    _startPositionUpdater();
  }

  @override
  void dispose() {
    // Timer'ları güvenli şekilde dispose et
    _hideControlsTimer?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(SwipeViewConstants.hideControlsDuration, () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _startPositionUpdater() {
    _positionTimer = Timer.periodic(SwipeViewConstants.positionUpdateInterval, (
      timer,
    ) {
      if (mounted) {
        final state = _playerKey.currentState;
        if (state != null) {
          final position = state.currentPosition;
          final duration = state.totalDuration;
          final isPlaying = state.isPlaying;

          if (position != null) {
            setState(() {
              _currentPosition = position;
              _isPlaying = isPlaying;

              // Video süresi varsa güncelle
              if (duration != null && duration.inSeconds > 0) {
                _totalDuration = duration;
              } else if (_totalDuration.inSeconds <= 0) {
                // Varsayılan süre
                _totalDuration = Duration(
                  minutes: SwipeViewConstants.defaultTrailerMinutes,
                );
              }
            });
          }
        }
      }
    });
  }

  void _togglePlayPause() {
    final state = _playerKey.currentState;
    if (state != null) {
      if (_isPlaying) {
        state.pause();
      } else {
        state.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
    _showControlsTemporarily();
  }

  void _seekTo(Duration position) {
    final state = _playerKey.currentState;
    if (state != null) {
      // Önce seek et
      state.seekTo(position);

      // Hemen pozisyonu güncelle (görsel feedback için)
      setState(() {
        _currentPosition = position;
      });

      // 500ms sonra gerçek pozisyonu kontrol et
      Timer(Duration(milliseconds: 500), () {
        if (mounted) {
          final actualPosition = state.currentPosition;
          if (actualPosition != null) {
            setState(() {
              _currentPosition = actualPosition;
            });
          }
        }
      });
    }
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  void _closeFullscreen() {
    final currentPosition = _playerKey.currentState?.currentPosition;
    widget.onClose(currentPosition);
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          final currentPosition = _playerKey.currentState?.currentPosition;
          widget.onClose(currentPosition);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
            if (_showControls) {
              _startHideControlsTimer();
            }
          },
          child: Stack(
            children: [
              // Video Player
              Center(
                child: AspectRatio(
                  aspectRatio: SwipeViewConstants.aspectRatio,
                  child: OptimizedVideoPlayer(
                    key: _playerKey,
                    trailerUrl: widget.trailerUrl,
                    backgroundColor: Colors.black,
                    autoPlay: true,
                    enableFullscreenControls:
                        false, // YouTube kontrollerini devre dışı bırak
                    initialPosition: widget.initialPosition,
                  ),
                ),
              ),

              // Özel Kontroller
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Üst Bar - Kapatma Butonu
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            (isTablet ? 15 : 10),
                        left: isTablet ? 30 : 20,
                        right: isTablet ? 30 : 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Film Başlığı
                            Expanded(
                              child: Text(
                                'Film Trailer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 22 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Kapatma Butonu
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _closeFullscreen,
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 30 : 25,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: isTablet ? 28 : 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Orta - Play/Pause Butonu
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _togglePlayPause,
                            borderRadius: BorderRadius.circular(
                              isTablet ? 50 : 40,
                            ),
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 28 : 20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size:
                                    isTablet
                                        ? 50
                                        : SwipeViewConstants.playButtonSize,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Alt Bar - Progress Bar ve Zaman
                      Positioned(
                        bottom:
                            MediaQuery.of(context).padding.bottom +
                            (isTablet ? 30 : 20),
                        left: isTablet ? 30 : 20,
                        right: isTablet ? 30 : 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress Bar
                            Row(
                              children: [
                                // Zaman - Başlangıç
                                Text(
                                  _formatDuration(_currentPosition),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 12),

                                // Progress Bar
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppTheme.primaryRed,
                                      inactiveTrackColor: Colors.white
                                          .withOpacity(0.3),
                                      thumbColor: AppTheme.primaryRed,
                                      overlayColor: AppTheme.primaryRed
                                          .withOpacity(0.2),
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: isTablet ? 10 : 8,
                                      ),
                                      trackHeight: isTablet ? 6 : 4,
                                    ),
                                    child: Slider(
                                      value:
                                          _totalDuration.inSeconds > 0
                                              ? (_currentPosition.inSeconds
                                                          .toDouble() /
                                                      _totalDuration.inSeconds
                                                          .toDouble())
                                                  .clamp(0.0, 1.0)
                                              : 0.0,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (value) {
                                        if (_totalDuration.inSeconds > 0) {
                                          final newPosition = Duration(
                                            seconds:
                                                (value *
                                                        _totalDuration
                                                            .inSeconds)
                                                    .round(),
                                          );
                                          _seekTo(newPosition);
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(width: isTablet ? 16 : 12),
                                // Zaman - Toplam (tahmini)
                                Text(
                                  _totalDuration.inSeconds > 0
                                      ? _formatDuration(_totalDuration)
                                      : '00:03:00', // Varsayılan trailer süresi
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isTablet ? 30 : 20),

                            // Alt Kontroller
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 10 saniye geri
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final newPosition = Duration(
                                        seconds: (_currentPosition.inSeconds -
                                                SwipeViewConstants.seekSeconds)
                                            .clamp(0, _totalDuration.inSeconds),
                                      );
                                      _seekTo(newPosition);
                                    },
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 30 : 25,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isTablet ? 16 : 12,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.replay_10,
                                            color: Colors.white,
                                            size:
                                                isTablet
                                                    ? 28
                                                    : SwipeViewConstants
                                                        .seekButtonSize,
                                          ),
                                          SizedBox(width: isTablet ? 6 : 4),
                                          Text(
                                            '10s',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isTablet ? 14 : 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: isTablet ? 60 : 40),

                                // 10 saniye ileri
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final newPosition = Duration(
                                        seconds: (_currentPosition.inSeconds +
                                                SwipeViewConstants.seekSeconds)
                                            .clamp(0, _totalDuration.inSeconds),
                                      );
                                      _seekTo(newPosition);
                                    },
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 30 : 25,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isTablet ? 16 : 12,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.forward_10,
                                            color: Colors.white,
                                            size:
                                                isTablet
                                                    ? 28
                                                    : SwipeViewConstants
                                                        .seekButtonSize,
                                          ),
                                          SizedBox(width: isTablet ? 6 : 4),
                                          Text(
                                            '10s',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isTablet ? 14 : 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
