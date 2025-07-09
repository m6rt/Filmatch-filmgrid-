import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';
import '../services/tvdb_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_preferences.dart'; // ✅ models değil services

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class FullScreenPlayer extends StatefulWidget {
  final YoutubePlayerController controller;

  const FullScreenPlayer({required this.controller, super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late YoutubePlayerController _fullScreenController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    // Ekranı yatay yöne zorla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Status bar'ı gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Tam ekran için ayrı controller oluştur
    _fullScreenController = YoutubePlayerController(
      initialVideoId: widget.controller.metadata.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        enableCaption: false,
        hideThumbnail: true,
        disableDragSeek: false,
        useHybridComposition: true,
        forceHD: false,
        startAt: widget.controller.value.position.inSeconds,
      ),
    );

    // 3 saniye sonra kontrolleri gizle
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Ana controller'a pozisyonu aktar
    try {
      widget.controller.seekTo(_fullScreenController.value.position);
    } catch (e) {
      print('Error seeking to position: $e');
    }

    // Çıkarken ekran yönünü normal hale getir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Status bar'ı tekrar göster
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    _fullScreenController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              Center(
                child: YoutubePlayer(
                  controller: _fullScreenController,
                  showVideoProgressIndicator: false,
                  onReady: () {},
                  onEnded: (metaData) {
                    Navigator.pop(context);
                  },
                ),
              ),

              // Kontroller
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Stack(
                    children: [
                      // Geri butonu
                      Positioned(
                        top: 40,
                        left: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),

                      // Play/Pause butonu
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              if (_fullScreenController.value.isPlaying) {
                                _fullScreenController.pause();
                              } else {
                                _fullScreenController.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              _fullScreenController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),

                      // Alt kontroller
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            // Progress bar
                            ValueListenableBuilder<YoutubePlayerValue>(
                              valueListenable: _fullScreenController,
                              builder: (context, value, child) {
                                final duration = value.metaData.duration;
                                final position = value.position;

                                if (duration.inSeconds == 0) {
                                  return SizedBox.shrink();
                                }

                                return SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3.0,
                                    thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 8.0,
                                    ),
                                  ),
                                  child: Slider(
                                    value: position.inSeconds.toDouble().clamp(
                                      0.0,
                                      duration.inSeconds.toDouble(),
                                    ),
                                    max: duration.inSeconds.toDouble(),
                                    onChanged: (value) {
                                      _fullScreenController.seekTo(
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Kontrol butonları
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Geri sarma
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      final currentPos =
                                          _fullScreenController.value.position;
                                      _fullScreenController.seekTo(
                                        Duration(
                                          seconds: (currentPos.inSeconds - 10)
                                              .clamp(0, currentPos.inSeconds),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                // İleri sarma
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      final currentPos =
                                          _fullScreenController.value.position;
                                      final duration =
                                          _fullScreenController
                                              .value
                                              .metaData
                                              .duration;
                                      _fullScreenController.seekTo(
                                        Duration(
                                          seconds: (currentPos.inSeconds + 10)
                                              .clamp(0, duration.inSeconds),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                // Ses kontrolü
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      if (_fullScreenController.value.volume ==
                                          0) {
                                        _fullScreenController.setVolume(100);
                                      } else {
                                        _fullScreenController.setVolume(0);
                                      }
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      _fullScreenController.value.volume == 0
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
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

class _SwipeViewState extends State<SwipeView> with TickerProviderStateMixin {
  YoutubePlayerController? _controller;
  int _currentVideoIndex = 0;
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  String _errorMessage = '';

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
    _initializeApp();
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

  Future<void> _initializeApp() async {
    try {
      await UserPreferences.init();
      await _loadMovies();
    } catch (e) {
      print('❌ Error initializing app: $e');
      setState(() {
        _errorMessage = 'Failed to initialize app: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🎬 Loading personalized movies...');

      // ✅ Yeni kişiselleştirilmiş öneri sistemini kullan
      List<Map<String, dynamic>> movies =
          await RecommendationService.getPersonalizedRecommendations(count: 30);

      if (movies.isEmpty) {
        // Fallback: Dummy movies
        print('⚠️ No movies from recommendation service, using fallback');
        movies = _getFallbackMovies();
      }

      setState(() {
        _movies = movies;
        _isLoading = false;
      });

      if (_movies.isNotEmpty) {
        _initializeController();
      } else {
        setState(() {
          _errorMessage =
              'No movies found. Please check your internet connection.';
        });
      }
    } catch (e) {
      print('❌ Error loading movies: $e');
      setState(() {
        _movies = _getFallbackMovies();
        _errorMessage = 'Using offline movies. Check internet connection.';
        _isLoading = false;
      });
      _initializeController();
    }
  }

  List<Map<String, dynamic>> _getFallbackMovies() {
    List<Map<String, dynamic>> movies = [
      {
        'id': 'f1',
        'title': 'Oppenheimer',
        'vote_average': 8.5,
        'director': 'Christopher Nolan',
        'cast': 'Cillian Murphy, Emily Blunt, Matt Damon',
        'genre': 'Biography, Drama, History',
        'year': '2023',
        'youtube_key': 'uYPbbksJxIg',
        'priority_score': 9.0,
      },
      {
        'id': 'f2',
        'title': 'Barbie',
        'vote_average': 7.8,
        'director': 'Greta Gerwig',
        'cast': 'Margot Robbie, Ryan Gosling, America Ferrera',
        'genre': 'Comedy, Adventure, Fantasy',
        'year': '2023',
        'youtube_key': 'pBk4NYhWNMM',
        'priority_score': 8.5,
      },
      {
        'id': 'f3',
        'title': 'Top Gun: Maverick',
        'vote_average': 8.7,
        'director': 'Joseph Kosinski',
        'cast': 'Tom Cruise, Miles Teller, Jennifer Connelly',
        'genre': 'Action, Drama',
        'year': '2022',
        'youtube_key': 'qSqVVswa420',
        'priority_score': 9.2,
      },
      {
        'id': 'f4',
        'title': 'The Batman',
        'vote_average': 7.8,
        'director': 'Matt Reeves',
        'cast': 'Robert Pattinson, Zoë Kravitz, Paul Dano',
        'genre': 'Action, Crime, Drama',
        'year': '2022',
        'youtube_key': 'mqqft2x_Aa4',
        'priority_score': 8.3,
      },
      {
        'id': 'f5',
        'title': 'Everything Everywhere All at Once',
        'vote_average': 7.8,
        'director': 'Daniels',
        'cast': 'Michelle Yeoh, Stephanie Hsu, Ke Huy Quan',
        'genre': 'Action, Adventure, Comedy',
        'year': '2022',
        'youtube_key': 'WLkfz1Hults',
        'priority_score': 8.7,
      },
      {
        'id': 'f6',
        'title': 'Avatar: The Way of Water',
        'vote_average': 7.6,
        'director': 'James Cameron',
        'cast': 'Sam Worthington, Zoe Saldana, Sigourney Weaver',
        'genre': 'Action, Adventure, Family',
        'year': '2022',
        'youtube_key': 'd9MyW72ELq0',
        'priority_score': 8.9,
      },
      {
        'id': 'f7',
        'title': 'Dune: Part Two',
        'vote_average': 8.8,
        'director': 'Denis Villeneuve',
        'cast': 'Timothée Chalamet, Zendaya, Rebecca Ferguson',
        'genre': 'Action, Adventure, Drama',
        'year': '2024',
        'youtube_key': 'Way9Dexny3w',
        'priority_score': 9.2,
      },
      {
        'id': 'f8',
        'title': 'Spider-Man: Across the Spider-Verse',
        'vote_average': 8.7,
        'director': 'Joaquim Dos Santos',
        'cast': 'Shameik Moore, Hailee Steinfeld, Oscar Isaac',
        'genre': 'Animation, Action, Adventure',
        'year': '2023',
        'youtube_key': 'cqGjhVJWtEg',
        'priority_score': 8.9,
      },
      {
        'id': 'f9',
        'title': 'Guardians of the Galaxy Vol. 3',
        'vote_average': 8.1,
        'director': 'James Gunn',
        'cast': 'Chris Pratt, Zoe Saldana, Dave Bautista',
        'genre': 'Action, Adventure, Comedy',
        'year': '2023',
        'youtube_key': 'u3V5KDHRQvk',
        'priority_score': 8.6,
      },
      {
        'id': 'f10',
        'title': 'John Wick: Chapter 4',
        'vote_average': 7.8,
        'director': 'Chad Stahelski',
        'cast': 'Keanu Reeves, Donnie Yen, Bill Skarsgård',
        'genre': 'Action, Crime, Thriller',
        'year': '2023',
        'youtube_key': 'qEVUtrk8_B4',
        'priority_score': 8.4,
      },
    ];

    // Listeyi karıştır - her seferinde farklı sırada göster
    movies.shuffle();
    return movies;
  }

  void _initializeController() {
    try {
      // Önceki controller'ı dispose et
      if (_controller != null) {
        _controller!.dispose();
      }

      if (_movies.isNotEmpty &&
          _currentVideoIndex < _movies.length &&
          _movies[_currentVideoIndex]['youtube_key'] != null) {
        String youtubeKey = _movies[_currentVideoIndex]['youtube_key'];
        print('🎬 Initializing video: $youtubeKey');

        _controller = YoutubePlayerController(
          initialVideoId: youtubeKey,
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: true,
            hideControls: true,
            enableCaption: false,
            hideThumbnail: true,
            disableDragSeek: false,
            useHybridComposition: true,
            forceHD: false,
            loop: true,
          ),
        );

        // Controller listener ekle
        _controller!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        print('🎬 Video initialized: ${_movies[_currentVideoIndex]['title']}');
      } else {
        print('❌ Cannot initialize video - no valid youtube key');
      }
    } catch (e) {
      print('❌ Error initializing controller: $e');
    }
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

    // Swipe animasyonu - karta çıkış yönü
    double targetOffset = isLike ? 500.0 : -500.0;
    double targetRotation = isLike ? 0.5 : -0.5;

    // Manuel animasyon
    _swipeAnimationController.forward().then((_) {
      // Animasyon tamamlandığında
      _showFeedback(isLike);

      if (isLike) {
        _handleLike();
      } else {
        _handleDislike();
      }
    });

    // Animasyon değerlerini güncelle
    _updateSwipeAnimation(targetOffset, targetRotation);
  }

  void _updateSwipeAnimation(double targetOffset, double targetRotation) {
    // Smooth animasyon için timer kullan
    const duration = Duration(milliseconds: 300);
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
    const duration = Duration(milliseconds: 200);
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

  Future<void> _handleLike() async {
    if (_currentVideoIndex < _movies.length) {
      var currentMovie = _movies[_currentVideoIndex];

      try {
        // ✅ Yeni UserPreferences metodunu kullan
        await UserPreferences.addLikedMovie(
          currentMovie['genre'] ?? '',
          currentMovie['director'] ?? '',
          currentMovie['cast'] ?? '',
        );

        // Film ID'sini gösterilmiş olarak işaretle
        RecommendationService.markAsShown(currentMovie['id']);

        print(
          '✅ Liked: ${currentMovie['title']} (Score: ${currentMovie['priority_score']})',
        );
      } catch (e) {
        print('❌ Error saving like: $e');
      }

      await _nextVideoWithAnimation();
    }
  }

  Future<void> _handleDislike() async {
    if (_currentVideoIndex < _movies.length) {
      var currentMovie = _movies[_currentVideoIndex];

      try {
        // ✅ Yeni UserPreferences metodunu kullan
        await UserPreferences.addDislikedMovie(
          currentMovie['genre'] ?? '',
          currentMovie['director'] ?? '',
          currentMovie['cast'] ?? '',
        );

        // Film ID'sini gösterilmiş olarak işaretle
        RecommendationService.markAsShown(currentMovie['id']);

        print(
          '❌ Disliked: ${currentMovie['title']} (Score: ${currentMovie['priority_score']})',
        );
      } catch (e) {
        print('❌ Error saving dislike: $e');
      }

      await _nextVideoWithAnimation();
    }
  }

  Future<void> _nextVideoWithAnimation() async {
    // Fade out
    await _fadeAnimationController.reverse();

    // Reset animasyon değerleri
    setState(() {
      _swipeOffset = 0.0;
      _rotationAngle = 0.0;
      _scale = 1.0;
      _isSwipeInProgress = false;
    });

    // Video değiştir
    if (_currentVideoIndex < _movies.length - 1) {
      setState(() {
        _currentVideoIndex++;
      });
      _changeVideo();
    } else {
      await _loadMoreMovies();
    }

    // Animasyonları resetle
    _swipeAnimationController.reset();

    // Fade in
    await _fadeAnimationController.forward();
  }

  Future<void> _loadMoreMovies() async {
    try {
      print('🔄 Loading more personalized movies...');

      // Mevcut film ID'lerini al
      List<String> currentMovieIds =
          _movies.map((m) => m['id']).cast<String>().toList();

      // Yeni kişiselleştirilmiş öneriler al (mevcut filmleri hariç tut)
      List<Map<String, dynamic>> newMovies =
          await RecommendationService.getPersonalizedRecommendations(
            count: 25,
            excludeMovies: currentMovieIds,
          );

      // Yeni ve benzersiz filmleri filtrele
      List<Map<String, dynamic>> uniqueMovies =
          newMovies
              .where((movie) => !currentMovieIds.contains(movie['id']))
              .toList();

      if (uniqueMovies.isNotEmpty) {
        setState(() {
          _movies.addAll(uniqueMovies);
        });
        print('✅ Added ${uniqueMovies.length} new personalized movies');
      } else {
        // Yeni film bulunamadı, başa dön
        setState(() {
          _currentVideoIndex = 0;
        });
        _changeVideo();
      }
    } catch (e) {
      print('❌ Error loading more movies: $e');
      setState(() {
        _currentVideoIndex = 0;
      });
      _changeVideo();
    }
  }

  void _changeVideo() async {
    try {
      // Önceki controller'ı dispose et
      if (_controller != null) {
        _controller!.dispose();
        _controller = null;
      }

      // UI'ı güncelle (loading state)
      setState(() {});

      // Biraz bekle
      await Future.delayed(Duration(milliseconds: 300));

      if (_currentVideoIndex < _movies.length &&
          _movies[_currentVideoIndex]['youtube_key'] != null) {
        String youtubeKey = _movies[_currentVideoIndex]['youtube_key'];
        print('🎬 Changing to video: $youtubeKey');

        _controller = YoutubePlayerController(
          initialVideoId: youtubeKey,
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: true,
            hideControls: true,
            enableCaption: false,
            hideThumbnail: true,
            disableDragSeek: false,
            useHybridComposition: true,
            forceHD: false,
            loop: true,
          ),
        );

        // Controller listener ekle
        _controller!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        // UI'ı güncelle
        setState(() {});

        print('🎬 Video changed to: ${_movies[_currentVideoIndex]['title']}');
      }
    } catch (e) {
      print('❌ Error changing video: $e');
    }
  }

  void _showFeedback(bool isLike) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLike ? Icons.favorite : Icons.close, color: Colors.white),
            SizedBox(width: 8),
            Text(
              isLike ? 'Added to your favorites!' : 'Removed from suggestions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: isLike ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAlgorithmStats() async {
    // ✅ Async method olarak değiştir
    Map<String, dynamic> stats = await UserPreferences.getAlgorithmStats();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('🧠 AI Algorithm Stats'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('👍 Liked Movies: ${stats['liked_movies_count']}'),
                  Text('👎 Disliked Movies: ${stats['disliked_movies_count']}'),
                  SizedBox(height: 10),
                  Text(
                    '🎭 Preferred Genres:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List<String>.from(
                    stats['preferred_genres'] ?? [],
                  ).map((genre) => Text('• $genre')),
                  SizedBox(height: 10),
                  Text(
                    '🎬 Preferred Directors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List<String>.from(
                    stats['preferred_directors'] ?? [],
                  ).map((director) => Text('• $director')),
                  SizedBox(height: 10),
                  Text(
                    '⭐ Preferred Actors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List<String>.from(
                    stats['preferred_actors'] ?? [],
                  ).map((actor) => Text('• $actor')),
                  SizedBox(height: 10),
                  Text(
                    '📊 Algorithm Performance:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• Recommendation Engine: AI-based'),
                  Text(
                    '• Personalization: ${stats['has_preferences'] ? 'Active' : 'Learning'}',
                  ),
                  Text('• Total Interactions: ${stats['total_interactions']}'),
                ],
              ),
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

  void _showGenreSearch() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('🔍 Search by Genre'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Search for movies in specific genres:'),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            'Action',
                            'Drama',
                            'Comedy',
                            'Thriller',
                            'Horror',
                            'Romance',
                            'Sci-Fi',
                            'Fantasy',
                            'Crime',
                            'Adventure',
                          ]
                          .map(
                            (genre) => ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _searchByGenre(genre);
                              },
                              child: Text(genre),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _searchByGenre(String genre) async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Map<String, dynamic>> genreMovies =
          await RecommendationService.searchByGenreDetailed(genre);

      if (genreMovies.isNotEmpty) {
        setState(() {
          _movies = genreMovies;
          _currentVideoIndex = 0;
          _isLoading = false;
        });
        _initializeController();
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No movies found for genre: $genre')),
        );
      }
    } catch (e) {
      print('❌ Error searching by genre: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _fadeAnimationController.dispose();
    try {
      _controller?.dispose();
    } catch (e) {
      print('❌ Error disposing controller: $e');
    }
    super.dispose();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('🤖 Loading personalized movies...'),
              SizedBox(height: 10),
              Text(
                'Our AI is analyzing your preferences...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 60, color: Colors.orange),
              SizedBox(height: 20),
              Text(_errorMessage, textAlign: TextAlign.center),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _loadMovies, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie, size: 60, color: Colors.grey),
              SizedBox(height: 20),
              Text('No movies available'),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _loadMovies, child: Text('Reload')),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    var currentMovie = _movies[_currentVideoIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            _showAlgorithmStats();
          },
          icon: Icon(Icons.analytics),
        ),
        title: Text(
          "FilmGrid AI",
          style: TextStyle(
            fontFamily: "Caveat Brush",
            fontSize: 32,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showGenreSearch();
            },
            icon: Icon(Icons.search),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.person)),
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
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey[100]!, Colors.grey[200]!],
                      ),
                    ),
                  ),

                  // Ana kart - Tinder benzeri
                  Center(
                    child: Transform.translate(
                      offset: Offset(_swipeOffset, 0),
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
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    // Video container
                                    Container(
                                      width: double.infinity,
                                      height: screenHeight * 0.5,
                                      color: Colors.black,
                                      child:
                                          currentMovie['youtube_key'] != null &&
                                                  _controller != null
                                              ? ClipRRect(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.cover,
                                                  child: SizedBox(
                                                    width: screenWidth * 2,
                                                    height:
                                                        screenWidth *
                                                        2 *
                                                        9 /
                                                        16,
                                                    child: YoutubePlayer(
                                                      controller: _controller!,
                                                      showVideoProgressIndicator:
                                                          false,
                                                      onReady: () {
                                                        print(
                                                          '🎬 Video ready: ${currentMovie['title']}',
                                                        );
                                                      },
                                                      onEnded: (metaData) {
                                                        // Video bittiğinde loop
                                                        _controller?.seekTo(
                                                          Duration.zero,
                                                        );
                                                        _controller?.play();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              )
                                              : Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.movie,
                                                      size: 60,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(height: 20),
                                                    Text(
                                                      _controller == null
                                                          ? 'Loading trailer...'
                                                          : 'No trailer available',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                    ),

                                    // Swipe overlay effects
                                    if (_swipeOffset.abs() > 50)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: (_swipeOffset > 0
                                                    ? Colors.green
                                                    : Colors.red)
                                                .withOpacity(0.3),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding: EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _swipeOffset > 0
                                                    ? Icons.favorite
                                                    : Icons.close,
                                                size: 50,
                                                color:
                                                    _swipeOffset > 0
                                                        ? Colors.green
                                                        : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Film bilgileri container
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: screenHeight * 0.25,
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Film başlığı ve rating
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    currentMovie['title'] ??
                                                        'Unknown Movie',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily:
                                                          'PlayfairDisplay',
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
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
                                                        Icons.star,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        (currentMovie['vote_average'] ??
                                                                0.0)
                                                            .toStringAsFixed(1),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),

                                            // Film detayları
                                            _buildInfoRow(
                                              Icons.person,
                                              'Director',
                                              currentMovie['director'] ??
                                                  'Unknown',
                                            ),
                                            SizedBox(height: 8),
                                            _buildInfoRow(
                                              Icons.category,
                                              'Genre',
                                              currentMovie['genre'] ??
                                                  'Unknown',
                                            ),
                                            SizedBox(height: 8),
                                            _buildInfoRow(
                                              Icons.calendar_today,
                                              'Year',
                                              currentMovie['year'] ?? 'Unknown',
                                            ),
                                            SizedBox(height: 8),
                                            _buildInfoRow(
                                              Icons.group,
                                              'Cast',
                                              currentMovie['cast'] ?? 'Unknown',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Tam ekran butonu
                                    if (_controller != null)
                                      Positioned(
                                        top: 20,
                                        right: 20,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          FullScreenPlayer(
                                                            controller:
                                                                _controller!,
                                                          ),
                                                ),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.fullscreen,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Sayaç
                                    Positioned(
                                      top: 20,
                                      left: 20,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          "${_currentVideoIndex + 1}/${_movies.length}",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // AI Score badge
                                    if (currentMovie['priority_score'] != null)
                                      Positioned(
                                        top: 70,
                                        left: 20,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.smart_toy,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'AI: ${currentMovie['priority_score'].toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
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
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alt butonlar
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Dislike butonu
                        GestureDetector(
                          onTap: () => _animateSwipe(false),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),

                        // Like butonu
                        GestureDetector(
                          onTap: () => _animateSwipe(true),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 30,
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
