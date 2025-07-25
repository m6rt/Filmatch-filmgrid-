import 'package:filmgrid/views/public_profile_view.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/movie.dart';
import '../models/user_profile.dart';
import '../services/batch_optimized_movie_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_detail_modal.dart';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final BatchOptimizedMovieService _movieService = BatchOptimizedMovieService();
  final ProfileService _profileService = ProfileService();

  List<Movie> _allMovies = [];
  List<UserProfile> _allUsers = [];
  List<Movie> _filteredMovies = [];
  List<UserProfile> _filteredUsers = [];

  bool _isLoading = false;
  bool _isSearching = false;
  String _currentQuery = '';
  Timer? _debounceTimer;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Filmleri yükle
      await _movieService.initializeService();
      _allMovies = _movieService.getAllMovies();

      // Kullanıcıları yükle
      _allUsers = await _profileService.getAllUsers();
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && query != _currentQuery) {
        _currentQuery = query;
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMovies = [];
        _filteredUsers = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final lowerQuery = query.toLowerCase();

    // Film arama - başlık, yönetmen, oyuncu, tür
    _filteredMovies =
        _allMovies.where((movie) {
          return movie.title.toLowerCase().contains(lowerQuery) ||
              movie.director.toLowerCase().contains(lowerQuery) ||
              movie.cast.any(
                (actor) => actor.toLowerCase().contains(lowerQuery),
              ) ||
              movie.genre.any(
                (genre) => genre.toLowerCase().contains(lowerQuery),
              );
        }).toList();

    // Kullanıcı arama - kullanıcı adı, tam ad
    _filteredUsers =
        _allUsers.where((user) {
          return user.username.toLowerCase().contains(lowerQuery) ||
              user.fullName.toLowerCase().contains(lowerQuery);
        }).toList();

    // Sonuçları relevansa göre sırala
    _sortSearchResults(lowerQuery);

    setState(() => _isSearching = false);
  }

  void _sortSearchResults(String query) {
    // Filmleri relevansa göre sırala
    _filteredMovies.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();

      // Tam eşleşme önce
      if (aTitle == query) return -1;
      if (bTitle == query) return 1;

      // Başlangıçta eşleşen önce
      final aStartsWith = aTitle.startsWith(query);
      final bStartsWith = bTitle.startsWith(query);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // Alfabetik sıralama
      return aTitle.compareTo(bTitle);
    });

    // Kullanıcıları relevansa göre sırala
    _filteredUsers.sort((a, b) {
      final aUsername = a.username.toLowerCase();
      final bUsername = b.username.toLowerCase();

      // Tam eşleşme önce
      if (aUsername == query) return -1;
      if (bUsername == query) return 1;

      // Başlangıçta eşleşen önce
      final aStartsWith = aUsername.startsWith(query);
      final bStartsWith = bUsername.startsWith(query);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // Alfabetik sıralama
      return aUsername.compareTo(bUsername);
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

  void _navigateToUserProfile(UserProfile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PublicProfileView(username: user.username, user: user),
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
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Film veya kullanıcı ara...',
              hintStyle: TextStyle(color: AppTheme.secondaryGrey),
              prefixIcon: Icon(Icons.search, color: AppTheme.secondaryGrey),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.secondaryGrey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(color: AppTheme.darkGrey),
          ),
        ),
        bottom:
            _currentQuery.isNotEmpty
                ? TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: [
                    Tab(text: 'Filmler (${_filteredMovies.length})'),
                    Tab(text: 'Kullanıcılar (${_filteredUsers.length})'),
                  ],
                )
                : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (_currentQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (_filteredMovies.isEmpty && _filteredUsers.isEmpty) {
      return _buildNoResultsState();
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildMoviesTab(), _buildUsersTab()],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: AppTheme.secondaryGrey),
          const SizedBox(height: 16),
          Text(
            'Film veya kullanıcı aramaya başlayın',
            style: TextStyle(fontSize: 18, color: AppTheme.secondaryGrey),
          ),
          const SizedBox(height: 8),
          Text(
            'Film adı, yönetmen, oyuncu veya kullanıcı adı arayabilirsiniz',
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: AppTheme.secondaryGrey),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(fontSize: 18, color: AppTheme.secondaryGrey),
          ),
          const SizedBox(height: 8),
          Text(
            '"$_currentQuery" için hiçbir sonuç bulunamadı',
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = _filteredMovies[index];
        return _buildMovieItem(movie);
      },
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildMovieItem(Movie movie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.secondaryGrey.withOpacity(0.3),
          ),
          child:
              movie.posterUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
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
                          child: const Icon(Icons.movie, color: Colors.white),
                        );
                      },
                    ),
                  )
                  : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
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
                    child: const Icon(Icons.movie, color: Colors.white),
                  ),
        ),
        title: Text(
          movie.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${movie.year} • ${movie.director}',
              style: TextStyle(color: AppTheme.secondaryGrey, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              movie.genre.take(3).join(', '),
              style: TextStyle(color: AppTheme.primaryRed, fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.secondaryGrey,
          size: 16,
        ),
        onTap: () => _showMovieDetails(movie),
      ),
    );
  }

  Widget _buildUserItem(UserProfile user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.primaryRed,
          backgroundImage:
              user.profileImageUrl.isNotEmpty
                  ? NetworkImage(user.profileImageUrl)
                  : null,
          child:
              user.profileImageUrl.isEmpty
                  ? Text(
                    user.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                  : null,
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.fullName,
              style: TextStyle(color: AppTheme.secondaryGrey, fontSize: 14),
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                user.bio,
                style: TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.secondaryGrey,
          size: 16,
        ),
        onTap: () => _navigateToUserProfile(user),
      ),
    );
  }
}
