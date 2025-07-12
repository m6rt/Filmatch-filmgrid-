import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/movie.dart';
import '../services/batch_optimized_movie_service.dart';
import '../widgets/optimized_video_player.dart';
import '../theme/app_theme.dart';

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
  final GlobalKey<OptimizedVideoPlayerState> _videoPlayerKey = GlobalKey();

  // Tinder benzeri animasyon değişkenleri
  late AnimationController _swipeAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  double _swipeOffset = 0.0;
  double _rotationAngle = 0.0;
  double _scale = 1.0;
  bool _isSwipeInProgress = false;

  @override
  void initState() {
    super.initState();
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
      print('Film yükleme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeAnimations() {
    // Swipe animasyonu
    _swipeAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Fade animasyonu
    _fadeAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
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

      // Rotation hesapla (maksimum 15 derece)
      _rotationAngle = (_swipeOffset / 300) * 0.3; // Radyan cinsinden

      // Scale hesapla (hafif küçültme)
      _scale = 1.0 - (_swipeOffset.abs() / 1000);
      _scale = _scale.clamp(0.9, 1.0);

      // Sınırları belirle
      _swipeOffset = _swipeOffset.clamp(-400.0, 400.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSwipeInProgress) return;

    // Swipe threshold - daha düşük threshold
    if (_swipeOffset.abs() > 80) {
      _animateSwipe(_swipeOffset > 0);
    } else {
      // Geri dön animasyonu
      _resetSwipePosition();
    }
  }

  void _animateSwipe(bool isLike) {
    setState(() {
      _isSwipeInProgress = true;
    });

    // Kullanıcı eylemini kaydet
    if (_currentMovie != null) {
      _movieService.recordUserAction(
        _currentMovie!,
        isLike ? SwipeAction.like : SwipeAction.dislike,
      );

      // Debug için tercihleri yazdır
      _movieService.printUserPreferences();
    }

    // Swipe animasyonu - karta çıkış yönü
    double targetOffset = isLike ? 500.0 : -500.0;
    double targetRotation = isLike ? 0.5 : -0.5;

    // Manuel animasyon
    _swipeAnimationController.forward().then((_) {
      // Animasyon tamamlandığında
      _showFeedback(isLike);
      _nextCardWithAnimation();
    });

    // Animasyon değerlerini güncelle
    _updateSwipeAnimation(targetOffset, targetRotation);
  }

  void _updateSwipeAnimation(double targetOffset, double targetRotation) {
    // Smooth animasyon için timer kullan
    const steps = 30;
    const stepDuration = Duration(milliseconds: 10);

    double startOffset = _swipeOffset;
    double startRotation = _rotationAngle;
    double startScale = _scale;

    int currentStep = 0;

    Timer.periodic(stepDuration, (timer) {
      currentStep++;
      double progress = currentStep / steps;

      if (progress >= 1.0 || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _swipeOffset = startOffset + (targetOffset - startOffset) * progress;
        _rotationAngle =
            startRotation + (targetRotation - startRotation) * progress;
        _scale = startScale + (0.8 - startScale) * progress;
      });
    });
  }

  void _resetSwipePosition() {
    // Smooth geri dönüş animasyonu
    const steps = 20;
    const stepDuration = Duration(milliseconds: 10);

    double startOffset = _swipeOffset;
    double startRotation = _rotationAngle;
    double startScale = _scale;

    int currentStep = 0;

    Timer.periodic(stepDuration, (timer) {
      currentStep++;
      double progress = currentStep / steps;

      if (progress >= 1.0 || !mounted) {
        timer.cancel();
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
        _scale = startScale + (1.0 - startScale) * progress;
      });
    });
  }

  Future<void> _nextCardWithAnimation() async {
    // Fade out
    await _fadeAnimationController.reverse();

    // Reset animasyon değerleri
    setState(() {
      _swipeOffset = 0.0;
      _rotationAngle = 0.0;
      _scale = 1.0;
      _isSwipeInProgress = false;
    });

    // Sonraki filmi al
    _currentMovie = _movieService.getNextMovie();

    // Animasyonları resetle
    _swipeAnimationController.reset();

    // Fade in
    await _fadeAnimationController.forward();
  }

  void _showFeedback(bool isLike) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLike ? Icons.favorite : Icons.close, color: AppTheme.white),
            SizedBox(width: 8),
            Text(
              isLike ? 'Liked!' : 'Disliked!',
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
          content: Text('Bu film için trailer bulunamadı'),
          backgroundColor: AppTheme.secondaryGrey,
        ),
      );
      return;
    }

    // Mevcut video pozisyonunu al - önce videoyu başlat sonra pozisyonu al
    final currentState = _videoPlayerKey.currentState;
    if (currentState != null) {
      _currentVideoPosition = currentState.currentPosition ?? Duration.zero;
      print('Ana ekran video pozisyonu: ${_currentVideoPosition?.inSeconds} saniye');
    } else {
      _currentVideoPosition = Duration.zero;
      print('Video player state bulunamadı, sıfırdan başlayacak');
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (context) {
        final GlobalKey<OptimizedVideoPlayerState> fullscreenPlayerKey = GlobalKey();
        
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            // Dialog kapanırken fullscreen player'dan pozisyonu al ve ana player'a aktar
            if (didPop) {
              final fullscreenPosition = fullscreenPlayerKey.currentState?.currentPosition;
              if (fullscreenPosition != null) {
                print('Fullscreen pozisyonu: ${fullscreenPosition.inSeconds} saniye');
                // Ana video player'a pozisyonu aktar
                Future.delayed(Duration(milliseconds: 100), () {
                  _videoPlayerKey.currentState?.seekTo(fullscreenPosition);
                });
              }
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Video player - Tam ekran
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: OptimizedVideoPlayer(
                      key: fullscreenPlayerKey,
                      trailerUrl: _currentMovie!.trailerUrl,
                      backgroundColor: Colors.black,
                      autoPlay: true,
                      enableFullscreenControls: true,
                      initialPosition: _currentVideoPosition,
                    ),
                  ),
                ),
                // Kapatma butonu - Safe area'da
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Dialog kapatılırken fullscreen player'dan pozisyonu al
                        final fullscreenPosition = fullscreenPlayerKey.currentState?.currentPosition;
                        if (fullscreenPosition != null) {
                          print('Kapatma butonu - Fullscreen pozisyonu: ${fullscreenPosition.inSeconds} saniye');
                          // Ana video player'a pozisyonu aktar
                          Future.delayed(Duration(milliseconds: 100), () {
                            _videoPlayerKey.currentState?.seekTo(fullscreenPosition);
                          });
                        }
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSampleDialog(String title) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('📱 $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This is a sample UI. You can integrate your API here.'),
                if (title == 'Statistics') ...[
                  SizedBox(height: 10),
                  Text('� Toplam eylem: ${_movieService.totalActionsRecorded}'),
                  Text(
                    '🎬 Batch\'te kalan: ${_movieService.moviesRemainingInBatch}',
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _movieService.printUserPreferences();
                      _movieService.printBatchStatus();
                      Navigator.pop(context);
                    },
                    child: Text('Batch Durumunu Konsola Yazdır'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondaryGrey),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Film türüne göre renk döndür - Tema Sistemi
  Color _getMovieColor(Movie movie) {
    if (movie.genre.isEmpty) return AppTheme.primaryOrange;
    return AppTheme.getGenreColor(movie.genre.first);
  }

  // Film rating'ini hesapla (basit algoritma)
  double _calculateMovieRating(Movie movie) {
    // Basit bir rating algoritması
    double rating = 5.0;

    // Yıla göre bonus
    if (movie.year > 2015) rating += 1.0;
    if (movie.year > 2020) rating += 0.5;

    // Tür çeşitliliğine göre bonus
    rating += movie.genre.length * 0.2;

    // Cast sayısına göre bonus
    rating += movie.cast.length * 0.1;

    // Maksimum 10, minimum 1
    return rating.clamp(1.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: 10),
              Text(
                'Lütfen uygulamayı yeniden başlatın.',
                style: Theme.of(context).textTheme.bodySmall,
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

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _showSampleDialog('Statistics'),
          icon: Icon(Icons.analytics),
        ),
        title: Text("FilmGrid AI"),
        actions: [
          IconButton(
            onPressed: () => _showSampleDialog('Search'),
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => _showSampleDialog('Profile'),
            icon: Icon(Icons.person),
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
                  // Arka plan gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.backgroundGradient,
                    ),
                  ),

                  // Ana kart - Tinder benzeri, yukarı taşındı
                  Center(
                    child: Transform.translate(
                      offset: Offset(
                        _swipeOffset,
                        -30,
                      ), // Y ekseninde 30 piksel yukarı
                      child: Transform.rotate(
                        angle: _rotationAngle,
                        child: Transform.scale(
                          scale: _scale,
                          child: GestureDetector(
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: Container(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.75,
                              decoration: AppTheme.cardDecoration,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    // Video/İçerik container - Daha büyük yapıldı
                                    Container(
                                      width: double.infinity,
                                      height:
                                          screenHeight *
                                          0.58, // 0.55'den 0.58'e çıkarıldı
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
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
                                                      autoPlay:
                                                          false, // true'dan false'a - hızlı yükleme
                                                    ),
                                                    // Subtle play button overlay
                                                    Positioned(
                                                      top: 16,
                                                      right: 16,
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          8,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
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
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'Trailer',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 12,
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
                                                          size: 80,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(height: 20),
                                                        Text(
                                                          'No Trailer Available',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'PlayfairDisplay',
                                                          ),
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text(
                                                          _currentMovie
                                                                  ?.title ??
                                                              'Unknown Movie',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 14,
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

                                    // Swipe overlay effects
                                    if (_swipeOffset.abs() > 50)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: (_swipeOffset > 0
                                                    ? AppTheme.primaryRed
                                                    : AppTheme.secondaryGrey)
                                                .withOpacity(0.4),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding: EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: AppTheme.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _swipeOffset > 0
                                                    ? Icons.favorite
                                                    : Icons.close,
                                                size: 50,
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

                                    // Film bilgileri container - Daha küçük yapıldı
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height:
                                            screenHeight *
                                            0.17, // 0.2'den 0.17'ye düşürüldü
                                        padding: EdgeInsets.all(
                                          16,
                                        ), // 12'den 16'ya artırıldı
                                        decoration: BoxDecoration(
                                          color: AppTheme.white,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Film başlığı ve rating - Kompakt
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _currentMovie!.title,
                                                      style:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .titleLarge, // headlineSmall'dan titleLarge'a
                                                      maxLines:
                                                          1, // 2'den 1'e düşürüldü
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ), // 10'dan 8'e
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              10, // 8'den 10'a
                                                          vertical:
                                                              6, // 4'den 6'ya
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.primaryRed,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18, // 15'den 18'e
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
                                                              14, // 12'den 14'e
                                                        ),
                                                        SizedBox(
                                                          width: 4, // 2'den 4'e
                                                        ),
                                                        Text(
                                                          _calculateMovieRating(
                                                            _currentMovie!,
                                                          ).toStringAsFixed(1),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelMedium, // labelSmall'dan labelMedium'a
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10, // 6'dan 10'a
                                              ),
                                              // Film detayları - Kompakt
                                              _buildInfoRow(
                                                Icons.person,
                                                'Director',
                                                _currentMovie!.director,
                                              ),
                                              SizedBox(height: 4), // 8'den 4'e
                                              _buildInfoRow(
                                                Icons.category,
                                                'Genre',
                                                _currentMovie!.genre
                                                    .take(2)
                                                    .join(
                                                      ', ',
                                                    ), // Sadece ilk 2 tür
                                              ),
                                              SizedBox(height: 4), // 8'den 4'e
                                              _buildInfoRow(
                                                Icons.calendar_today,
                                                'Year',
                                                _currentMovie!.year.toString(),
                                              ),
                                              SizedBox(height: 4),
                                              _buildInfoRow(
                                                Icons.group,
                                                'Cast',
                                                _currentMovie!.cast
                                                    .take(2)
                                                    .join(', '),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Tam ekran butonu - Düzeltildi
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: _showFullscreenVideo,
                                          icon: Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
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

                  // Alt butonlar - Daha aşağı taşındı
                  Positioned(
                    bottom: 20, // 50'den 20'ye düşürüldü
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Dislike butonu - Biraz büyütüldü
                        GestureDetector(
                          onTap: () => _animateSwipe(false),
                          child: Container(
                            width: 65, // 60'dan 65'e
                            height: 65, // 60'dan 65'e
                            decoration: AppTheme.dislikeButtonDecoration,
                            child: Icon(
                              Icons.close,
                              color: AppTheme.secondaryGrey,
                              size: 32, // 30'dan 32'ye
                            ),
                          ),
                        ),

                        // Like butonu - Biraz büyütüldü
                        GestureDetector(
                          onTap: () => _animateSwipe(true),
                          child: Container(
                            width: 65, // 60'dan 65'e
                            height: 65, // 60'dan 65'e
                            decoration: AppTheme.buttonDecoration,
                            child: Icon(
                              Icons.favorite,
                              color: AppTheme.white,
                              size: 32, // 30'dan 32'ye
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
