import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/movie.dart';
import '../services/batch_optimized_movie_service.dart';
import '../services/profile_service.dart';
import '../services/comments_service.dart'; // Bu import'u ekleyin
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../widgets/movie_detail_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_view.dart';

class BrowseView extends StatefulWidget {
  const BrowseView({super.key});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> with TickerProviderStateMixin {
  final BatchOptimizedMovieService _movieService = BatchOptimizedMovieService();
  final ProfileService _profileService = ProfileService();
  final CommentsService _commentsService = CommentsService();

  List<Movie> _allMovies = [];
  Map<String, List<Movie>> _moviesByGenre = {};
  List<Movie> _trendingMovies = [];
  bool _isLoading = true;
  String? _error;

  // Film karşılaştırma için
  Movie? _comparisonMovie1;
  Movie? _comparisonMovie2;
  Movie? _userChoice;
  Map<String, int> _votingResults = {'movie1': 0, 'movie2': 0};
  bool _hasVoted = false;
  bool _showResults = false;

  // Trending carousel için
  late PageController _trendingController;
  late Timer _autoScrollTimer;
  int _currentTrendingIndex = 0;

  // Animasyon controller'ları
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadMovies();
  }

  void _initializeControllers() {
    _trendingController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _trendingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _movieService.initializeService();
      _allMovies = _movieService.getAllMovies();

      _categorizeMovies();
      _selectTrendingMovies();
      _startAutoScroll();
      _fadeController.forward();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Filmler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _categorizeMovies() {
    _moviesByGenre.clear();

    for (final movie in _allMovies) {
      for (final genre in movie.genre) {
        if (!_moviesByGenre.containsKey(genre)) {
          _moviesByGenre[genre] = [];
        }
        _moviesByGenre[genre]!.add(movie);
      }
    }

    // Türleri popülerlik sırasına göre sırala
    final sortedGenres =
        _moviesByGenre.keys.toList()..sort(
          (a, b) =>
              _moviesByGenre[b]!.length.compareTo(_moviesByGenre[a]!.length),
        );

    final sortedMap = <String, List<Movie>>{};
    for (final genre in sortedGenres) {
      sortedMap[genre] = _moviesByGenre[genre]!;
    }
    _moviesByGenre = sortedMap;
  }

  void _selectTrendingMovies() {
    // Son 5 yılın filmlerini seç ve yüksek puanlı olanları gündemde göster
    final recentMovies =
        _allMovies
            .where((movie) => movie.year >= DateTime.now().year - 5)
            .toList();

    recentMovies.shuffle();
    _trendingMovies = recentMovies.take(10).toList();
    _selectDailyComparisonMovies();
  }

  Future<void> _selectDailyComparisonMovies() async {
    final today =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final prefs = await SharedPreferences.getInstance();

    print('🗓️ Bugünün tarihi: $today');

    // Bugünkü filmler zaten seçilmiş mi kontrol et
    final savedDate = prefs.getString('daily_comparison_date');
    final savedMovie1Id = prefs.getInt('daily_movie1_id');
    final savedMovie2Id = prefs.getInt('daily_movie2_id');

    print('💾 SharedPreferences\'den okunan:');
    print('   - Kayıtlı tarih: $savedDate');
    print('   - Film 1 ID: $savedMovie1Id');
    print('   - Film 2 ID: $savedMovie2Id');

    if (savedDate == today && savedMovie1Id != null && savedMovie2Id != null) {
      // Bugün için zaten filmler seçilmiş, onları kullan
      print('🔄 Bugün için kaydedilmiş filmler bulundu, kullanılıyor...');
      _comparisonMovie1 = _allMovies.firstWhere(
        (movie) => movie.id == savedMovie1Id,
        orElse: () => _selectRandomMovies().first,
      );
      _comparisonMovie2 = _allMovies.firstWhere(
        (movie) => movie.id == savedMovie2Id,
        orElse: () => _selectRandomMovies().last,
      );
      print(
        '🎬 Yüklenen filmler: ${_comparisonMovie1!.title} vs ${_comparisonMovie2!.title}',
      );
    } else {
      // Yeni gün, yeni filmler seç
      print('🆕 Yeni gün, yeni filmler seçiliyor...');
      final selectedMovies = _selectMoviesForDate(today);
      _comparisonMovie1 = selectedMovies[0];
      _comparisonMovie2 = selectedMovies[1];

      print(
        '🎬 Seçilen filmler: ${_comparisonMovie1!.title} vs ${_comparisonMovie2!.title}',
      );

      // SharedPreferences'a kaydet
      await prefs.setString('daily_comparison_date', today);
      await prefs.setInt('daily_movie1_id', _comparisonMovie1!.id);
      await prefs.setInt('daily_movie2_id', _comparisonMovie2!.id);

      print('💾 SharedPreferences\'e kaydedildi');
    }

    // Günlük oylama durumunu kontrol et
    await _checkDailyVotingStatus();
  }

  List<Movie> _selectMoviesForDate(String date) {
    // Tarihi seed olarak kullanarak deterministik film seçimi
    final highRatedMovies =
        _allMovies.where((movie) => movie.voteAverage >= 7.0).toList();

    if (highRatedMovies.length < 2) {
      return _selectRandomMovies();
    }

    // Tarihi sayıya çevir (seed olarak kullan)
    final dateSeed = date.replaceAll('-', '').hashCode;
    final random = Random(dateSeed);

    // Aynı filmleri seçmemek için
    final shuffledMovies = List<Movie>.from(highRatedMovies);
    shuffledMovies.shuffle(random);

    return [shuffledMovies[0], shuffledMovies[1]];
  }

  List<Movie> _selectRandomMovies() {
    final movies =
        _allMovies.where((movie) => movie.voteAverage >= 6.0).toList();
    if (movies.length < 2) return _allMovies.take(2).toList();
    movies.shuffle();
    return movies.take(2).toList();
  }

  Future<void> _checkDailyVotingStatus() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();

    // Bugünkü oylama durumunu kontrol et
    final savedVotingDate = prefs.getString('daily_voting_date');
    final hasUserVoted = prefs.getBool('has_voted_today') ?? false;
    final userChoiceId = prefs.getInt('daily_user_choice_id');
    final movie1Votes = prefs.getInt('daily_movie1_votes') ?? 0;
    final movie2Votes = prefs.getInt('daily_movie2_votes') ?? 0;

    print('📊 Günlük oylama durumu:');
    print('   - Oylama tarihi: $savedVotingDate');
    print('   - Kullanıcı oy verdi mi: $hasUserVoted');
    print('   - Seçilen film ID: $userChoiceId');
    print('   - Film 1 oyları: $movie1Votes');
    print('   - Film 2 oyları: $movie2Votes');

    if (savedVotingDate == today) {
      // Bugün için oylama durumunu geri yükle
      _hasVoted = hasUserVoted;
      _showResults = hasUserVoted;
      _votingResults = {'movie1': movie1Votes, 'movie2': movie2Votes};

      if (userChoiceId != null) {
        _userChoice = _allMovies.firstWhere(
          (movie) => movie.id == userChoiceId,
          orElse: () => _comparisonMovie1!,
        );
      }

      print('🔄 Bugünkü oylama durumu geri yüklendi');
    } else {
      // Yeni gün, oylama durumunu sıfırla
      _hasVoted = false;
      _showResults = false;
      _votingResults = {'movie1': 0, 'movie2': 0};
      _userChoice = null;

      print('🆕 Yeni gün, oylama durumu sıfırlandı');
    }
  }

  Future<void> _voteForMovie(Movie selectedMovie) async {
    if (_hasVoted) return;

    setState(() {
      _userChoice = selectedMovie;
      _hasVoted = true;

      // Gerçek zamanlı oy sayısını artır
      if (selectedMovie == _comparisonMovie1) {
        _votingResults['movie1'] = _votingResults['movie1']! + 1;
      } else {
        _votingResults['movie2'] = _votingResults['movie2']! + 1;
      }

      _showResults = true;
    });

    // Oylama durumunu SharedPreferences'e kaydet
    await _saveDailyVotingStatus(selectedMovie);

    print('✅ Oy kaydedildi: ${selectedMovie.title}');
  }

  Future<void> _saveDailyVotingStatus(Movie selectedMovie) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('daily_voting_date', today);
    await prefs.setBool('has_voted_today', true);
    await prefs.setInt('daily_user_choice_id', selectedMovie.id);
    await prefs.setInt('daily_movie1_votes', _votingResults['movie1']!);
    await prefs.setInt('daily_movie2_votes', _votingResults['movie2']!);

    print('💾 Oylama durumu SharedPreferences\'e kaydedildi');
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) {
      if (_trendingMovies.isNotEmpty && mounted) {
        _currentTrendingIndex =
            (_currentTrendingIndex + 1) % _trendingMovies.length;

        if (_trendingController.hasClients) {
          _trendingController.animateToPage(
            _currentTrendingIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _showMovieDetails(Movie movie) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => MovieDetailModal(
            movie: movie,
            profileService: _profileService,
            onAddToFavorites: (movie) => _addToFavorites(movie),
            onAddToWatchlist: (movie) => _addToWatchlist(movie),
          ),
    );
  }

  Future<void> _addToFavorites(Movie movie) async {
    try {
      await _profileService.addFavoriteMovie(movie.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} favorilere eklendi'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorilere eklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addToWatchlist(Movie movie) async {
    try {
      await _profileService.addToWatchlist(movie.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} listeye eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listeye eklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      appBar: AppBar(
        title: Text(
          "Keşfet",
          style: TextStyle(fontFamily: "Caveat Brush", fontSize: 40),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchView()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryGrey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMovies,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gündemde Olanlar
            _buildTrendingSection(),

            const SizedBox(height: 20),

            // Günlük Film Karşılaştırması
            _buildDailyComparisonSection(),

            const SizedBox(height: 20),

            // Türlere Göre Filmler
            ..._buildGenreSections(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final containerHeight = isTablet ? 280.0 : 220.0;
        final titleFontSize = isTablet ? 24.0 : 20.0;
        final iconSize = isTablet ? 28.0 : 24.0;
        final horizontalPadding = isTablet ? 24.0 : 16.0;

        return Container(
          height: containerHeight,
          margin: EdgeInsets.only(bottom: isTablet ? 15 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppTheme.primaryRed,
                      size: iconSize,
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Text(
                      'Gündemde',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Expanded(
                child: PageView.builder(
                  controller: _trendingController,
                  itemCount: _trendingMovies.length,
                  onPageChanged: (index) {
                    setState(() => _currentTrendingIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final movie = _trendingMovies[index];
                    return _buildTrendingCard(movie, isTablet);
                  },
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              // Sayfa göstergeleri
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _trendingMovies.length,
                  (index) => Container(
                    width: isTablet ? 10 : 8,
                    height: isTablet ? 10 : 8,
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentTrendingIndex == index
                              ? AppTheme.primaryRed
                              : AppTheme.secondaryGrey.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingCard(Movie movie, bool isTablet) {
    final horizontalMargin = isTablet ? 24.0 : 16.0;
    final borderRadius = isTablet ? 20.0 : 16.0;
    final contentPadding = isTablet ? 28.0 : 20.0;
    final titleFontSize = isTablet ? 26.0 : 22.0;
    final genreFontSize = isTablet ? 16.0 : 14.0;
    final yearFontSize = isTablet ? 14.0 : 12.0;
    final badgePadding =
        isTablet
            ? EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final badgeFontSize = isTablet ? 12.0 : 10.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: GestureDetector(
        onTap: () => _showMovieDetails(movie),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.getGenreColor(
                  movie.genre.isNotEmpty ? movie.genre.first : 'Unknown',
                ),
                AppTheme.getGenreColor(
                  movie.genre.isNotEmpty ? movie.genre.first : 'Unknown',
                ).withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: isTablet ? 15 : 10,
                offset: Offset(0, isTablet ? 6 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Poster Background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child:
                      movie.posterUrl.isNotEmpty
                          ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.getGenreColor(
                                        movie.genre.isNotEmpty
                                            ? movie.genre.first
                                            : 'Unknown',
                                      ),
                                      AppTheme.getGenreColor(
                                        movie.genre.isNotEmpty
                                            ? movie.genre.first
                                            : 'Unknown',
                                      ).withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                          : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.getGenreColor(
                                    movie.genre.isNotEmpty
                                        ? movie.genre.first
                                        : 'Unknown',
                                  ),
                                  AppTheme.getGenreColor(
                                    movie.genre.isNotEmpty
                                        ? movie.genre.first
                                        : 'Unknown',
                                  ).withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                ),
              ),

              // Arkaplan gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // İçerik
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      movie.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isTablet ? 12 : 8),

                    // Rating bilgisi ekle
                    FutureBuilder<Map<String, dynamic>>(
                      future: _commentsService.getMovieRatingInfo(movie.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final ratingInfo = snapshot.data!;
                          return Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: isTablet ? 18 : 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${ratingInfo['formattedRating']} (${ratingInfo['commentCount']})',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: genreFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }
                        return SizedBox(height: isTablet ? 18 : 16);
                      },
                    ),

                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                      movie.genre.take(2).join(' • '),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: genreFontSize,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      movie.year.toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: yearFontSize,
                      ),
                    ),
                  ],
                ),
              ),

              // Trending badge
              Positioned(
                top: isTablet ? 20 : 16,
                right: isTablet ? 20 : 16,
                child: Container(
                  padding: badgePadding,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                  child: Text(
                    'TREND',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGenreSections() {
    return _moviesByGenre.entries.map((entry) {
      final genre = entry.key;
      final movies = entry.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final horizontalPadding = isTablet ? 24.0 : 16.0;
          final titleFontSize = isTablet ? 22.0 : 18.0;
          final sectionHeight = isTablet ? 240.0 : 200.0;
          final bottomMargin = isTablet ? 30.0 : 20.0;

          return Container(
            margin: EdgeInsets.only(bottom: bottomMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    genre,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                SizedBox(
                  height: sectionHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      return _buildMovieCard(movies[index], isTablet);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildMovieCard(Movie movie, bool isTablet) {
    final cardWidth = isTablet ? 140.0 : 120.0;
    final rightMargin = isTablet ? 16.0 : 12.0;
    final borderRadius = isTablet ? 16.0 : 12.0;
    final blurRadius = isTablet ? 8.0 : 6.0;
    final shadowOffset = isTablet ? Offset(0, 3) : Offset(0, 2);
    final titleFontSize = isTablet ? 14.0 : 12.0;
    final yearFontSize = isTablet ? 12.0 : 10.0;
    final iconSize = isTablet ? 48.0 : 40.0;
    final spacingBetween = isTablet ? 12.0 : 8.0;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: rightMargin),
      child: GestureDetector(
        onTap: () => _showMovieDetails(movie),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: blurRadius,
                      offset: shadowOffset,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child:
                      movie.posterUrl.isNotEmpty
                          ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppTheme.secondaryGrey,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryRed,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildPlaceholderPoster(movie, iconSize),
                          )
                          : _buildPlaceholderPoster(movie, iconSize),
                ),
              ),
            ),
            SizedBox(height: spacingBetween),
            Text(
              movie.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacingBetween / 4),

            // Rating bilgisi ekle
            FutureBuilder<Map<String, dynamic>>(
              future: _commentsService.getMovieRatingInfo(movie.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final ratingInfo = snapshot.data!;
                  return Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: isTablet ? 12 : 10,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${ratingInfo['formattedRating']} (${ratingInfo['commentCount']})',
                        style: TextStyle(
                          fontSize: yearFontSize,
                          color: AppTheme.secondaryGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox(height: yearFontSize);
              },
            ),

            SizedBox(height: spacingBetween / 4),
            Text(
              movie.year.toString(),
              style: TextStyle(
                fontSize: yearFontSize,
                color: AppTheme.secondaryGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster(Movie movie, [double iconSize = 40]) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.getGenreColor(
              movie.genre.isNotEmpty ? movie.genre.first : 'Unknown',
            ),
            AppTheme.getGenreColor(
              movie.genre.isNotEmpty ? movie.genre.first : 'Unknown',
            ).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.movie, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildDailyComparisonSection() {
    if (_comparisonMovie1 == null || _comparisonMovie2 == null) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.compare, color: AppTheme.primaryRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Günlük Karşılaştırma',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGrey,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Hangi filmi daha çok seviyorsun? Seçimini yap ve diğer kullanıcıların tercihlerini gör!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkGrey.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16),

          // Karşılaştırma Kartları
          if (!_showResults) ...[
            _buildComparisonCards(),
          ] else ...[
            _buildResultsCards(),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonCards() {
    return Row(
      children: [
        // Film 1
        Expanded(
          child: GestureDetector(
            onTap: () => _voteForMovie(_comparisonMovie1!),
            child: _buildComparisonCard(_comparisonMovie1!, false),
          ),
        ),

        SizedBox(width: 16),

        // VS Text
        Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'VS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),

        SizedBox(width: 16),

        // Film 2
        Expanded(
          child: GestureDetector(
            onTap: () => _voteForMovie(_comparisonMovie2!),
            child: _buildComparisonCard(_comparisonMovie2!, false),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCards() {
    final totalVotes = _votingResults['movie1']! + _votingResults['movie2']!;
    final movie1Percentage =
        totalVotes > 0 ? (_votingResults['movie1']! / totalVotes) * 100 : 0;
    final movie2Percentage =
        totalVotes > 0 ? (_votingResults['movie2']! / totalVotes) * 100 : 0;

    return Column(
      children: [
        Row(
          children: [
            // Film 1 Results
            Expanded(
              child: _buildComparisonCard(
                _comparisonMovie1!,
                true,
                percentage: movie1Percentage.round(),
                isWinner: false, // Kazanan gösterme
                isUserChoice: _userChoice == _comparisonMovie1,
              ),
            ),

            SizedBox(width: 16),

            // VS Text with total votes
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$totalVotes oy',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey.withOpacity(0.6),
                  ),
                ),
              ],
            ),

            SizedBox(width: 16),

            // Film 2 Results
            Expanded(
              child: _buildComparisonCard(
                _comparisonMovie2!,
                true,
                percentage: movie2Percentage.round(),
                isWinner: false, // Kazanan gösterme
                isUserChoice: _userChoice == _comparisonMovie2,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        Text(
          'Oyunuz kaydedildi! Diğer kullanıcıların seçimlerini görüyorsunuz.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryRed,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    Movie movie,
    bool showResults, {
    int percentage = 0,
    bool isWinner = false,
    bool isUserChoice = false,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Film Poster/Background
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                movie.posterUrl.isNotEmpty
                    ? Image.network(
                      movie.posterUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.getGenreColor(
                                  movie.genre.isNotEmpty
                                      ? movie.genre.first
                                      : 'Unknown',
                                ),
                                AppTheme.getGenreColor(
                                  movie.genre.isNotEmpty
                                      ? movie.genre.first
                                      : 'Unknown',
                                ).withOpacity(0.8),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    : Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.getGenreColor(
                              movie.genre.isNotEmpty
                                  ? movie.genre.first
                                  : 'Unknown',
                            ),
                            AppTheme.getGenreColor(
                              movie.genre.isNotEmpty
                                  ? movie.genre.first
                                  : 'Unknown',
                            ).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
          ),

          // Film Bilgileri
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Results Overlay
          if (showResults) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isWinner) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'KAZANAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // User Choice Indicator
          if (isUserChoice && showResults) ...[
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
