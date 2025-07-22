import 'package:flutter/material.dart';
import 'dart:async';
import '../models/movie.dart';
import '../services/batch_optimized_movie_service.dart';
import '../services/profile_service.dart';
import '../services/comments_service.dart'; // Bu import'u ekleyin
import '../theme/app_theme.dart';
import '../widgets/optimized_video_player.dart';

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
          (context) => _MovieDetailsDialog(
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
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Film Keşfet', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Arama ekranı
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Arama özelliği yakında gelecek')),
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

// Film Detay Dialog Widget'ı
class _MovieDetailsDialog extends StatefulWidget {
  final Movie movie;
  final ProfileService profileService;
  final Function(Movie) onAddToFavorites;
  final Function(Movie) onAddToWatchlist;

  const _MovieDetailsDialog({
    required this.movie,
    required this.profileService,
    required this.onAddToFavorites,
    required this.onAddToWatchlist,
  });

  @override
  State<_MovieDetailsDialog> createState() => _MovieDetailsDialogState();
}

class _MovieDetailsDialogState extends State<_MovieDetailsDialog> {
  bool _isAddingToFavorites = false;
  bool _isAddingToWatchlist = false;
  bool _isInFavorites = false;
  bool _isInWatchlist = false;
  bool _isLoading = true;

  // Yorumlar için yeni state'ler ekleyin
  final CommentsService _commentsService = CommentsService();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _checkMovieStatus();
    _loadComments(); // Yorumları yükle
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    final comments = await _commentsService.getComments(widget.movie.id);

    setState(() {
      _comments = comments;
      _isLoadingComments = false;
    });
  }

  Future<void> _checkMovieStatus() async {
    final movieId = widget.movie.id.toString();
    try {
      final inFavorites = await widget.profileService.isMovieInFavorites(
        movieId,
      );
      final inWatchlist = await widget.profileService.isMovieInWatchlist(
        movieId,
      );

      if (mounted) {
        setState(() {
          _isInFavorites = inFavorites;
          _isInWatchlist = inWatchlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking movie status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      alignment: Alignment.center, // Dialogu merkeze konumlandır
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 96 : 16,
        vertical: 50, // Vertical padding'i artır
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.3, // Minimum yükseklik
          maxHeight: screenHeight * 0.8, // %80'e düşür
          maxWidth: isTablet ? 600 : double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  children: [
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trailer Video
                            if (widget.movie.trailerUrl != null)
                              Container(
                                height: isTablet ? 180 : 140,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: OptimizedVideoPlayer(
                                    trailerUrl: widget.movie.trailerUrl!,
                                    backgroundColor: AppTheme.getGenreColor(
                                      widget.movie.genre.isNotEmpty
                                          ? widget.movie.genre.first
                                          : 'Unknown',
                                    ),
                                    autoPlay: false,
                                  ),
                                ),
                              ),

                            // Movie Info
                            _buildInfoRow('Yönetmen', widget.movie.director),
                            _buildInfoRow('Tür', widget.movie.genre.join(', ')),
                            _buildInfoRow('Yıl', widget.movie.year.toString()),
                            _buildInfoRow(
                              'Oyuncular',
                              widget.movie.cast.take(3).join(', '),
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              'Açıklama',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.movie.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.darkGrey,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 24), // 16'dan 24'e çıkardım
                            // Yorumlar Bölümü
                            _buildCommentsSection(),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons - Fixed at bottom
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : Row(
                                children: [
                                  // Favorilere Ekle/Çıkar
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isAddingToFavorites
                                              ? null
                                              : () async {
                                                setState(
                                                  () =>
                                                      _isAddingToFavorites =
                                                          true,
                                                );

                                                if (_isInFavorites) {
                                                  final success = await widget
                                                      .profileService
                                                      .removeFavoriteMovie(
                                                        widget.movie.id
                                                            .toString(),
                                                      );
                                                  if (success && mounted) {
                                                    setState(() {
                                                      _isInFavorites = false;
                                                    });
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${widget.movie.title} favorilerden çıkarıldı',
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                } else {
                                                  await widget.onAddToFavorites(
                                                    widget.movie,
                                                  );
                                                  if (mounted) {
                                                    setState(() {
                                                      _isInFavorites = true;
                                                    });
                                                  }
                                                }

                                                setState(
                                                  () =>
                                                      _isAddingToFavorites =
                                                          false,
                                                );
                                              },
                                      icon:
                                          _isAddingToFavorites
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Icon(
                                                _isInFavorites
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                size: 18,
                                              ),
                                      label: Text(
                                        _isAddingToFavorites
                                            ? (_isInFavorites
                                                ? 'Çıkarılıyor...'
                                                : 'Ekleniyor...')
                                            : (_isInFavorites
                                                ? 'Favorilerden Çıkar'
                                                : 'Favorilere Ekle'),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _isInFavorites
                                                ? Colors.orange
                                                : AppTheme.primaryRed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 6,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Listeye Ekle/Çıkar
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isAddingToWatchlist
                                              ? null
                                              : () async {
                                                setState(
                                                  () =>
                                                      _isAddingToWatchlist =
                                                          true,
                                                );

                                                if (_isInWatchlist) {
                                                  final success = await widget
                                                      .profileService
                                                      .removeFromWatchlist(
                                                        widget.movie.id
                                                            .toString(),
                                                      );
                                                  if (success && mounted) {
                                                    setState(() {
                                                      _isInWatchlist = false;
                                                    });
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${widget.movie.title} izleme listesinden çıkarıldı',
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                } else {
                                                  await widget.onAddToWatchlist(
                                                    widget.movie,
                                                  );
                                                  if (mounted) {
                                                    setState(() {
                                                      _isInWatchlist = true;
                                                    });
                                                  }
                                                }

                                                setState(
                                                  () =>
                                                      _isAddingToWatchlist =
                                                          false,
                                                );
                                              },
                                      icon:
                                          _isAddingToWatchlist
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Icon(
                                                _isInWatchlist
                                                    ? Icons.playlist_remove
                                                    : Icons.playlist_add,
                                                size: 18,
                                              ),
                                      label: Text(
                                        _isAddingToWatchlist
                                            ? (_isInWatchlist
                                                ? 'Çıkarılıyor...'
                                                : 'Ekleniyor...')
                                            : (_isInWatchlist
                                                ? 'Listeden Çıkar'
                                                : 'Listeye Ekle'),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _isInWatchlist
                                                ? Colors.orange
                                                : AppTheme.primaryRed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 6,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: AppTheme.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yorumlar başlığı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yorumlar (${_comments.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGrey,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/comments',
                  arguments: {
                    'movieId': widget.movie.id,
                    'movie': widget.movie,
                  },
                ).then((_) {
                  _loadComments();
                });
              },
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Yorumlar listesi - Yüksekliği artıralım
        SizedBox(
          height: 130, // 100'den 130'a çıkar
          child:
              _isLoadingComments
                  ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  )
                  : _comments.isEmpty
                  ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20), // Padding'i artır
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.secondaryGrey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: AppTheme.secondaryGrey,
                          size: 24, // İkon boyutunu artır
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz yorum yapılmamış\nİlk yorumu siz yapın!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, // Font boyutunu artır
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentCard(comment);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return GestureDetector(
      onTap: () {
        // CommentsView'e yönlendir
        Navigator.pushNamed(
          context,
          '/comments',
          arguments: {'movieId': widget.movie.id, 'movie': widget.movie},
        ).then((_) {
          // CommentsView'den döndükten sonra yorumları yenile
          _loadComments();
        });
      },
      child: Container(
        width: 300, // Genişliği 280'den 300'e artır
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.secondaryGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgisi ve yıldızlar - Daha kompakt
            Row(
              children: [
                CircleAvatar(
                  radius: 14, // Biraz küçült
                  backgroundColor: AppTheme.primaryRed,
                  child: Text(
                    (comment['username']?.toString() ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11, // Font boyutunu küçült
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['username']?.toString() ?? 'Kullanıcı',
                        style: TextStyle(
                          fontSize: 11, // Font boyutunu küçült
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < ((comment['rating'] ?? 0) / 2)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 10, // Yıldız boyutunu küçült
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              comment['date']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 9, // Font boyutunu küçült
                                color: AppTheme.secondaryGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6), // Spacing'i azalt
            // Yorum metni (spoiler kontrolü ile)
            Expanded(
              child:
                  (comment['isSpoiler'] == true)
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6), // Padding'i azalt
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primaryRed.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_off,
                              color: AppTheme.primaryRed,
                              size: 14, // İkon boyutunu küçült
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Spoiler içerik\nTıklayın',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9, // Font boyutunu küçült
                                color: AppTheme.darkGrey,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Text(
                        comment['comment']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 11, // Font boyutunu küçült
                          color: AppTheme.darkGrey,
                          height: 1.3,
                        ),
                        maxLines: 4, // Maksimum satır sayısını artır
                        overflow: TextOverflow.ellipsis,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
