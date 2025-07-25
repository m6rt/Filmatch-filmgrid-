import 'package:flutter/material.dart';
import 'dart:async';
import '../models/movie.dart';
import '../services/batch_optimized_movie_service.dart';
import '../services/profile_service.dart';
import '../services/comments_service.dart'; // Bu import'u ekleyin
import '../theme/app_theme.dart';
import '../widgets/optimized_video_player.dart';
import 'package:flutter/services.dart';
import '../widgets/movie_detail_modal.dart';
import 'search_view.dart';

class BrowseView extends StatefulWidget {
  const BrowseView({super.key});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> with TickerProviderStateMixin {
  final BatchOptimizedMovieService _movieService = BatchOptimizedMovieService();
  final ProfileService _profileService = ProfileService();

  List<Movie> _allMovies = [];
  Map<String, List<Movie>> _moviesByGenre = {};
  List<Movie> _trendingMovies = [];
  bool _isLoading = true;
  String? _error;

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
              // Arkaplan gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
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
}
