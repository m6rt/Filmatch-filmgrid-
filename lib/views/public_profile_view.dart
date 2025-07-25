import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_detail_modal.dart';

class PublicProfileView extends StatefulWidget {
  final String username;

  const PublicProfileView({Key? key, required this.username}) : super(key: key);

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  final ProfileService _profileService = ProfileService();

  UserProfile? _userProfile;
  List<Movie> _userFavorites = [];
  List<Movie> _userWatchlist = [];
  List<Map<String, dynamic>> _userComments = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getUserProfile(widget.username);
      if (profile != null) {
        _userProfile = profile;

        // Kullanıcının verilerini yükle
        await Future.wait([
          _loadUserFavorites(),
          _loadUserWatchlist(),
          _loadUserComments(),
        ]);
      } else {
        _error = 'Kullanıcı bulunamadı';
      }
    } catch (e) {
      _error = 'Profil yüklenirken hata oluştu: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserFavorites() async {
    try {
      _userFavorites = await _profileService.getUserPublicFavorites(
        widget.username,
      );
    } catch (e) {
      print('Favori filmler yüklenirken hata: $e');
    }
  }

  Future<void> _loadUserWatchlist() async {
    try {
      _userWatchlist = await _profileService.getUserPublicWatchlist(
        widget.username,
      );
    } catch (e) {
      print('İzleme listesi yüklenirken hata: $e');
    }
  }

  Future<void> _loadUserComments() async {
    try {
      _userComments = await _profileService.getUserComments(widget.username);
    } catch (e) {
      print('Yorumlar yüklenirken hata: $e');
    }
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
            showActionButtons: false, // Public profile'da butonları gizle
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

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profil fotoğrafı
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage:
                    _userProfile!.profileImageUrl.isNotEmpty
                        ? NetworkImage(_userProfile!.profileImageUrl)
                        : null,
                child:
                    _userProfile!.profileImageUrl.isEmpty
                        ? Text(
                          _userProfile!.username.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        )
                        : null,
              ),
              const SizedBox(height: 16),

              // Kullanıcı adı
              Text(
                _userProfile!.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Full name (eğer farklıysa)
              if (_userProfile!.fullName.isNotEmpty &&
                  _userProfile!.fullName != _userProfile!.username)
                Text(
                  _userProfile!.fullName,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),

              const SizedBox(height: 16),

              // İstatistikler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Yorum', _userComments.length.toString()),
                  _buildStatCard('Film', _userWatchlist.length.toString()),
                  _buildStatCard('Favori', _userFavorites.length.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryRed,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryRed,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: AppTheme.primaryRed,
                      unselectedLabelColor: AppTheme.secondaryGrey,
                      indicatorColor: AppTheme.primaryRed,
                      tabs: const [
                        Tab(text: 'Favoriler'),
                        Tab(text: 'İzleme Listesi'),
                        Tab(text: 'Yorumlar'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMoviesGrid(_userFavorites),
                        _buildMoviesGrid(_userWatchlist),
                        _buildCommentsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: AppTheme.secondaryGrey),
            const SizedBox(height: 16),
            Text(
              'Henüz film yok',
              style: TextStyle(fontSize: 16, color: AppTheme.secondaryGrey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
          onTap: () => _showMovieDetails(movie),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  movie.posterUrl.isNotEmpty
                      ? Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.getGenreColor(
                              movie.genre.isNotEmpty
                                  ? movie.genre.first
                                  : 'Unknown',
                            ),
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: AppTheme.getGenreColor(
                          movie.genre.isNotEmpty
                              ? movie.genre.first
                              : 'Unknown',
                        ),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    if (_userComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: AppTheme.secondaryGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz yorum yok',
              style: TextStyle(fontSize: 16, color: AppTheme.secondaryGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        final comment = _userComments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (starIndex) => Icon(
                        starIndex < ((comment['rating'] ?? 0) / 2)
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment['date']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment['comment']?.toString() ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
