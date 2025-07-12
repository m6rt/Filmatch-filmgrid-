import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/movie.dart';
import '../../services/batch_optimized_movie_service.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/swipe_constants.dart';
import '../../core/utils/performance_utils.dart';
import 'controllers/video_controller.dart';
import 'widgets/movie_card.dart';
import 'widgets/error_widgets.dart';

class RefactoredSwipeView extends StatefulWidget {
  const RefactoredSwipeView({super.key});

  @override
  State<RefactoredSwipeView> createState() => _RefactoredSwipeViewState();
}

class _RefactoredSwipeViewState extends State<RefactoredSwipeView>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSwipeInProgress = false;
  String? _errorMessage;

  // Service & Data
  final BatchOptimizedMovieService _movieService = BatchOptimizedMovieService();
  Movie? _currentMovie;

  // Controllers
  late VideoController _videoController;
  late AnimationController _swipeAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  // Animation values
  double _swipeOffset = 0.0;
  double _rotationAngle = 0.0;
  double _scale = 1.0;

  // Performance helpers
  final Debouncer _swipeDebouncer = Debouncer(
    delay: SwipeConstants.debounceDelay,
  );
  final ThrottleManager _throttleManager = ThrottleManager();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadMovies();
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _fadeAnimationController.dispose();
    _videoController.dispose();
    _swipeDebouncer.dispose();
    _throttleManager.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _videoController = VideoController();

    _swipeAnimationController = AnimationController(
      duration: SwipeConstants.swipeAnimationDuration,
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: SwipeConstants.fadeAnimationDuration,
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

  Future<void> _loadMovies() async {
    await PerformanceHelper.measureAsync('loadMovies', () async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        if (!_movieService.isInitialized) {
          await _movieService.initializeService();
        }

        final movie = _movieService.getNextMovie();
        if (movie != null && mounted) {
          setState(() {
            _currentMovie = movie;
            _isLoading = false;
          });
          _videoController.reset();
        } else if (mounted) {
          setState(() {
            _errorMessage = SwipeConstants.movieLoadError;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '${SwipeConstants.movieLoadError}: $e';
            _isLoading = false;
          });
        }
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwipeInProgress) return;

    _throttleManager.throttle('panUpdate', Duration(milliseconds: 16), () {
      if (!mounted) return;

      setState(() {
        _swipeOffset += details.delta.dx;
        _rotationAngle = _swipeOffset * 0.001;
        _scale = (1.0 - (_swipeOffset.abs() / 300)).clamp(
          SwipeConstants.scaleAnimationMin,
          SwipeConstants.scaleAnimationMax,
        );
      });
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _swipeDebouncer.call(() {
      if (_swipeOffset.abs() > SwipeConstants.swipeThreshold) {
        _animateSwipe(_swipeOffset > 0);
      } else {
        _resetCard();
      }
    });
  }

  Future<void> _animateSwipe(bool isLike) async {
    if (_isSwipeInProgress) return;

    await PerformanceHelper.measureAsync('animateSwipe', () async {
      setState(() {
        _isSwipeInProgress = true;
      });

      HapticFeedback.lightImpact();

      _swipeAnimationController.forward().then((_) {
        if (mounted) {
          _loadNextMovie(isLike);
        }
      });
    });
  }

  void _resetCard() {
    setState(() {
      _swipeOffset = 0.0;
      _rotationAngle = 0.0;
      _scale = 1.0;
    });
  }

  Future<void> _loadNextMovie(bool liked) async {
    await PerformanceHelper.measureAsync('loadNextMovie', () async {
      try {
        // Film action'ını kaydet (like/dislike)
        if (_currentMovie != null) {
          _movieService.recordUserAction(
            _currentMovie!,
            liked ? SwipeAction.like : SwipeAction.dislike,
          );
          debugPrint(
            'Film ${liked ? "beğenildi" : "beğenilmedi"}: ${_currentMovie!.title}',
          );
        }

        // Yeni film yükle
        final nextMovie = _movieService.getNextMovie();

        if (nextMovie != null && mounted) {
          setState(() {
            _currentMovie = nextMovie;
            _isSwipeInProgress = false;
          });

          // Animasyonları sıfırla
          _resetCard();
          _swipeAnimationController.reset();
          _videoController.reset();

          // Fade in animasyonu
          _fadeAnimationController.reset();
          _fadeAnimationController.forward();
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Daha fazla film bulunamadı';
            _isSwipeInProgress = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Yeni film yüklenirken hata: $e';
            _isSwipeInProgress = false;
          });
        }
      }
    });
  }

  void _onFullscreen() {
    // Fullscreen logic - bu kısmı SwipeView'dan kopyalayabilirsin
    debugPrint('Fullscreen requested');
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryRed),
              SizedBox(height: 20),
              Text(
                'Filmler yükleniyor...',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: NetworkErrorWidget(onRetry: _loadMovies),
      );
    }

    // No movie state
    if (_currentMovie == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 80,
                color: AppTheme.darkGrey,
              ),
              SizedBox(height: 20),
              Text(
                'Gösterilecek film bulunamadı!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loadMovies,
                child: Text('Yeniden Yükle'),
              ),
            ],
          ),
        ),
      );
    }

    // Main UI
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'İstatistikler',
          child: IconButton(
            onPressed: () => debugPrint('Statistics'),
            icon: Icon(Icons.analytics),
            tooltip: 'İstatistikler',
          ),
        ),
        title: Text("Film Keşfi"),
        actions: [
          Semantics(
            label: 'Arama',
            child: IconButton(
              onPressed: () => debugPrint('Search'),
              icon: Icon(Icons.search),
              tooltip: 'Film ara',
            ),
          ),
          Semantics(
            label: 'Profil',
            child: IconButton(
              onPressed: () => debugPrint('Profile'),
              icon: Icon(Icons.person),
              tooltip: 'Profil',
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
              decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
              child: Center(
                child: Transform.translate(
                  offset: Offset(_swipeOffset, -50),
                  child: Transform.rotate(
                    angle: _rotationAngle,
                    child: Transform.scale(
                      scale: _scale,
                      child: GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Container(
                          width:
                              screenSize.width * SwipeConstants.cardWidthRatio,
                          height:
                              screenSize.height *
                              SwipeConstants.cardHeightRatio,
                          decoration: AppTheme.cardDecoration,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: MovieCard(
                              movie: _currentMovie!,
                              videoController: _videoController,
                              onLike: () => _animateSwipe(true),
                              onDislike: () => _animateSwipe(false),
                              onFullscreen: _onFullscreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
